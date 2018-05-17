# Overview

# Preliminaries: Slides and Transcript

include(common/slides.md)

include(common/intro.md)

# Magnum Under The Hood

## User...

include(common/arch/arch0.md)

<!--

# Magnum Under The Hood

Now that we've got a general idea of what Magnum is all about we'll zoom in a
bit and accompany a cluster through its whole life cycle.

# User...

Like many stories in our profession, this one starts with a user. That user
operates a Magnum client.

![User...](img/magnum_architecture_0.PNG)

-->

include(common/arch/arch1.md)

<!--

# User and Magnum API

A client alone is not very useful, so on the other side we have the Magnum API
running on the cloud's OpenStack controller. The user interacts with Magnum
through this API.

![User and Magnum API](img/magnum_architecture_1.PNG)

-->

include(common/arch/arch2.md)


<!--

# Describe Cluster in ClusterTemplate

As mentioned before, the first thing we need is a cluster template. This is how
the user tells Magnum which orchestration engine to configure, which glance
image to use and many other things.

![Describe Cluster in ClusterTemplate](img/magnum_architecture_2.PNG)

-->

## Cluster Template: Missing `os-distro` Field

<!--

## Cluster Template: Missing `os-distro` Field

At this point we can already encounter a problem. It's trivial to solve but the
error message leaves something to be desired, so we will cover it here:

-->

## Cluster Template: Missing `os-distro` Field

```
ERROR: Image doesn't contain os-distro field. (HTTP 404)
```

<!--

```
ERROR: Image doesn't contain os-distro field. (HTTP 404)
```

-->

## Cluster Template: Missing `os-distro` Field

```
ERROR: Image doesn't contain os-distro field. (HTTP 404)
```

* Glance image needs to have `os-distro` field in its metadata

<!--

This happens if the Glance image does not have an `os-distro` field in its
metadata.

-->

## Cluster Template: Missing `os-distro` Field

```
ERROR: Image doesn't contain os-distro field. (HTTP 404)
```

* Glance image needs to have `os-distro` field in its metadata

* `os-distro` needs to match a Magnum driver's cluster distribution such as
  `jeos` or `fedora-atomic`

<!--


Magnum has a notion of drivers that are identified by orchestration engine,
distribution name and version. The combination of the cluster template's
orchestration engine and its image's `os-distro` field must match a Magnum
driver.

-->

include(common/arch/arch3.md)

<!--

# Create Cluster...

Now that we have a Cluster Template we can create the cluster itself.

![Create Cluster...](img/magnum_architecture_3.PNG)

-->

include(common/arch/arch4.md)

<!--

# ...based on ClusterTemplate

The most important - and also mandatory - parameter when creating a cluster is
its Cluster Template, specified either as a name or a UUID. Other than that
there are not all that many since most other metadata are stored in the cluster
template.

![...based on ClusterTemplate](img/magnum_architecture_4.PNG)

-->

## Early `CREATE_FAILED` from Magnum

<!--

There are a couple of ways cluster creation can fail early on.

-->

## Early `CREATE_FAILED` from Magnum

* Cluster status

<!--

First of all, let's take a look at how to determine a Magnum cluster's status.
For a `cluster create` command will return immediately and report succcess even
though Magnum's conductor service will take quite a while to actually create
the cluster and may well fail at some stage.

-->

## Early `CREATE_FAILED` from Magnum

* Cluster status

  * `include(cmd/cluster-show.sh)`

<!--

To see a cluster's status we can use the API client's `cluster show` command:

```
include(cmd/cluster-show.sh)
```

-->

## Early `CREATE_FAILED` from Magnum

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * A `status` value of `CREATE_FAILED` indicates creation failure
    reported by `magnum-conductor`

<!--

This command shows us various metadata, among them the cluster's current status
as recorded in the Magnum database by `magnum-conductor`. You may still keep
your hopes up for a successful deployment if the status is
`CREATE_IN_PROGRESS`. A status of `CREATE_FAILED` indicates that cluster
creation has encountered a terminal error condition it cannot recover from.

-->

## Early `CREATE_FAILED` from Magnum

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * A `status` value of `CREATE_FAILED` indicates creation failure
    reported by `magnum-conductor`

  * Error message in `status_reason` upon `CREATE_FAILED`

<!--

If cluster deployment does fail, you will find a more detailed error message in
the cluster's `status_reason` attribute.

-->

## Early `CREATE_FAILED` from Magnum

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * A `status` value of `CREATE_FAILED` indicates creation failure
    reported by `magnum-conductor`

  * Error message in `status_reason` upon `CREATE_FAILED`

* Common early failures from Magnum itself:

<!--

If you encounter a `CREATE_FAILED` just a few seconds after cluster creation
you are probably dealing with some sort of early validation error.

These vary across Openstack releases as checks are ocasionally added and
removed.

-->

## Early `CREATE_FAILED` from Magnum

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * A `status` value of `CREATE_FAILED` indicates creation failure
    reported by `magnum-conductor`

  * Error message in `status_reason` upon `CREATE_FAILED`

* Common early failures from Magnum itself:

  * `Failed to get discovery url from 'https://discovery.etcd.io/new?size=1'`

<!--

One example is a failure to obtain a discovery URL from the public `etcd`
discovery service.

```
Failed to get discovery url from 'https://discovery.etcd.io/new?size=1'
```

This URL would ordinarily be passed to the Magnum clusters' VMs so they can
coordinate using an `etcd` cluster.

This typically happens if the machine where the Magnum services run cannot
access the Internet or a local `etcd` discovery service (if one has been
specified).

-->

## Early `CREATE_FAILED` from Magnum

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * A `status` value of `CREATE_FAILED` indicates creation failure
    reported by `magnum-conductor`

  * Error message in `status_reason` upon `CREATE_FAILED`

* Common early failures from Magnum itself:

  * `Failed to get discovery url from 'https://discovery.etcd.io/new?size=1'`

  * `This cluster can only be created with trust/cluster_user_trust = True in magnum.conf`

<!--

Another one is an error that can meanwhile no longer occur: 

some clusters require the (somewhat insecure) `cluster_user_trust` setting to
be set to `True`:

```
This cluster can only be created with trust/cluster_user_trust = True in magnum.conf`
```

Nowadays the heuristic checking for clusters that may require this setting has
been removed.

You may still see this error on clouds running OpenStack Newton,
but on more recent releases it will not occur.

You will see various later failures on clouds that require this setting to be
set to `True`, though.

We will show you what that looks like that in the Kubernetes debugging section.

-->

include(common/arch/arch5.md)

<!--

# API to Conductor: "Create Cluster, please"

Now that the Magnum API has gotten a request to create a cluster, it does what
most OpenStack API services do when they receive a request to create a
resource: 

it passes a RabbitMQ message to its backend service, magnum-conductor, which is
tasked with the actual work of creating the cluster.

![API to Conductor: "Create Cluster, please"](img/magnum_architecture_5.PNG)

-->

include(common/arch/arch6.md)

<!--

# Generate a Heat Template Matching Cluster

Now magnum-conductor looks at both the Cluster's and the Cluster Template's
attributes and uses that information to stitch together a Heat template
implementing the cluster the user requested.

In our case this is a Kubernetes cluster on OpenSUSE. 

Magnum comes with drivers for various operating systems and
orchestration engines.

All of these come with Heat templates for resource creation and lots of
little shell scripts for setting up the cluster nodes.

These scripts are mixed and matched to form each node's user data payload.

We marked this step in red since we'll refer back to it later.

![Generate a Heat Template Matching Cluster](img/magnum_architecture_6.PNG)

-->

## Timeouts and frozen clients

<!--

## Timeouts and frozen clients

Before we get to problems during cluster creation let's look at a Magnum API
error that may be a bit puzzling if it occurs:

-->

## Timeouts and frozen clients

* Sometimes Magnum clients hang

<!--

Sometimes Magnum clients hang

-->

## Timeouts and frozen clients

* Sometimes Magnum clients hang

* After a minute you may get

```
include(output/conductor-down) 
```

<!--

If you wait about a minute you may get the following error message:

```
include(output/conductor-down) 
```

-->

## Timeouts and frozen clients

* Sometimes Magnum clients hang

* After a minute you may get

```
include(output/conductor-down) 
```

* Diagnosis:

<!--

Diagnosis of the problem is fairly straightforward:

-->

## Timeouts and frozen clients

* Sometimes Magnum clients hang

* After a minute you may get

```
include(output/conductor-down) 
```

* Diagnosis:

  * Timeout error message after a minute: magnum-conductor not
    responding to RabbitMQ messages

<!--

* If you do get an error message after a bit, your problem is a lack of
  RabbitMQ messages magnum-api expects in response to the messages it sent for
  magnum-conductor.
  
  That usually means that there's no magnum-conductor listening to the RabbitMQ
  message queue, usually because it has crashed. In that case, check whether
  magnum-conductor is running properly.

-->

## Timeouts and frozen clients

* Sometimes Magnum clients hang

* After a minute you may get

```
include(output/conductor-down) 
```

* Diagnosis:

  * Timeout error message after a minute: magnum-conductor not
    responding to RabbitMQ messages

  * Indefinite freeze without error message: RabbitMQ not reachable for
    magnum-api

<!--

* If you see an indefinite hang that usually means that magnum-api cannot reach
  RabbitMQ. 
  
  Once RabbitMQ is back up you will see the Magnum client fail with the same
  timeout error message.

-->

include(common/arch/arch7.md)

<!--

# Send Heat Template to Heat API

Now that Magnum has generated its compound Heat template, it sends that Heat
template to the Heat API...

![Send Heat Template to Heat API](img/magnum_architecture_7.PNG)

-->

include(common/arch/arch8.md)

<!--

# Heat Creates VMs and Plumbing

...which goes and spawns Nova instances, interconnects them with Neutron
networks, assigns Floating IPs and adds all the ingredients that go into a
working Heat stack.

![Heat Creates VMs and Plumbing](img/magnum_architecture_8.PNG)

-->

## Early `CREATE_FAILED` from Heat

## Early `CREATE_FAILED` from Heat

* "early": 30 seconds to a few minutes after `cluster create`

<!--

If cluster creation fails after about 30 seconds to a few minutes, we may see
creation failures passed through from Heat.

-->

## Early `CREATE_FAILED` from Heat

* "early": 30 seconds to a few minutes after `cluster create`

* Cluster status

## Early `CREATE_FAILED` from Heat

* "early": 30 seconds to a few minutes after `cluster create`

* Cluster status

  * `include(cmd/cluster-show.sh)`

<!--

To see these errors passed through from Heat we will once again issue a
`cluster show` command to check its status.

-->

## Early `CREATE_FAILED` from Heat

* "early": 30 seconds to a few minutes after `cluster create`

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * Status `CREATE_FAILED` indicates a creation failure

<!--

Again, we will see a status of `CREATE_FAILED`.

From this point onward any status we see in this field will be the Heat stack's
state, by the way.

-->

## Early `CREATE_FAILED` from Heat

* "early": 30 seconds to a few minutes after `cluster create`

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * Status `CREATE_FAILED` indicates a creation failure

  * Error message in `status_reason` upon `CREATE_FAILED`

<!--

And just like with the earlier Magnum errors, the `status_reason` attribute
will contain a detailed error message.

From here on out, that error message is usually copied verbatim from the Heat
stack's `stack_status_reason` attribute.

-->

## Early `CREATE_FAILED` from Heat

* "early": 30 seconds to a few minutes after `cluster create`

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * Status `CREATE_FAILED` indicates a creation failure

  * Error message in `status_reason` upon `CREATE_FAILED`

* Common early failures from Heat:

<!--

There are a myriad reasons a Heat stack may fail to deploy. The most common
ones are from two categories:

-->

## Early `CREATE_FAILED` from Heat

* "early": 30 seconds to a few minutes after `cluster create`

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * Status `CREATE_FAILED` indicates a creation failure

  * Error message in `status_reason` upon `CREATE_FAILED`

* Common early failures from Heat:

  * Resource exhaustion, e.g. `No valid host was found` (Nova)

<!--

1. Resource exhaustion issues, such as the popular `No valid host was found`
   reported by Nova.
   
   Magnum is fairly likely to trigger this problem if you create big
   clusters or lots of clusters since each cluster consumes a non-trivial
   amount of resources.

-->

## Early `CREATE_FAILED` from Heat

* "early": 30 seconds to a few minutes after `cluster create`

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * Status `CREATE_FAILED` indicates a creation failure

  * Error message in `status_reason` upon `CREATE_FAILED`

* Common early failures from Heat:

  * Resource exhaustion, e.g. `No valid host was found` (Nova)

  * Quota issues (Floating IPs, networks, volumes, ...)

<!--

2. Exceeded quotas are fairly common, too.

   For instance, floating IPs usually tend to be genuinely scarce, with
   correspondingly tight quotas.
   
   Everything else, such as networks or volumes often suffers from small
   default quotas the cloud operator forgot to increase when creating a new
   project.

In both cases the problem is not really Magnum but the resources available on
the Cloud you are trying to build a Magnum cluster on.

-->

include(common/arch/arch9.md)

<!--

# VMs Run Container Friendly OS Image

Now we're at the point, where we've got operational VMs running a container
friendly operating system image.

That may be our own OpenSUSE JeOS image (we are currently working on
getting this properly integrated upstream), Fedora Atomic, CoreOS or Ubuntu Mesos.

That image should have all or at least most packages required for running the
requested container orchestration engine already installed and Magnum will
mostly only configure them.

![VMs Run Container Friendly OS Image](img/magnum_architecture_9.PNG)

-->

include(common/arch/arch10.md)

<!--

# VMs Run Container Friendly OS Image

Configuration is where the red stuff from earlier comes into play again.

We mentioned before that there is pool of deployment scripts Magnum picks from
when generating its Heat templates.

These got passed into Heat as a CloudConfig resource.

![CloudConfig Snippets...](img/magnum_architecture_10.PNG)

-->

include(common/arch/arch11.md)

<!--

# CloudConfig Snippets Become user-data

This CloudConfig resource ends up as a cloud-init user data payload on the Nova
instances now.

![CloudConfig Snippets Become user-data](img/magnum_architecture_11.PNG)

-->

include(common/arch/arch12.md)

<!--

# user-data run by cloud-init

All Magnum instances are cloud images, so they contain cloud-init which will
run the code in its user-data payload on startup.

![user-data run by cloud-init](img/magnum_architecture_12.PNG)

-->

## Wait Condition Timeout

<!--

Now this user data script is where the most common error occurs: the wait
condition timeout.

-->

## Wait Condition Timeout

* Error message

 * `Resource CREATE failed: WaitConditionTimeout`

<!--

Just like the other errors, this error will be visible in the cluster's
`status_reason` field:

Whenever there is a `Resource CREATE failed: WaitConditionTimeout`, in there,
you are facing this problem.

-->

## Wait Condition Timeout

* Error message

 * `Resource CREATE failed: WaitConditionTimeout`

* Most common failure mode

<!--

Wait condition timeouts are the most common failure mode for Magnum clusters.

They can occur for a variety of reasons, some of which we'll take a closer look at now.

-->

## Wait Condition Timeout

* Error message

 * `Resource CREATE failed: WaitConditionTimeout`

* Most common failure mode

* Background:

## Wait Condition Timeout

* Error message

 * `Resource CREATE failed: WaitConditionTimeout`

* Most common failure mode

* Background:

  * Cluster node deployment is synchronized via Heat wait conditions

<!--

As you already know, Magnum creates its clusters by generating and
instantiating a Heat template. 

That template cannot just spawn all VMs at once but needs to create them in a
certain order.

For instance, it does not make a lot of sense to launch Kubernetes minions
before the Kubernetes master is up and running.

To ensure that order is followed, a Heat mechanism called a wait condition is
used.

These wait conditions consist of a magic Heat API URL that is accessed from
inside a VM and a counter in the Heat database that gets incremented each time
the URL is accessed.

-->


* Various causes...

## Wait Condition Timeout

* Error message

 * `Resource CREATE failed: WaitConditionTimeout`

* Most common failure mode

* Background:

  * Cluster node deployment is synchronized via Heat wait conditions

  * If wait conditions are not triggered before their timeout, they fail

<!--

All wait conditions have a timeout associated with them.

If a wait condition is not triggered a sufficient number of times, the Heat
resource defining the wait condition transitions to the `CREATE_FAILED` state.

-->

## Wait Condition Timeout

* Error message

 * `Resource CREATE failed: WaitConditionTimeout`

* Most common failure mode

* Background:

  * Cluster node deployment is synchronized via Heat wait conditions

  * If wait conditions are not triggered before their timeout, they fail

* Meaning of timeout: `user-data` scripts inside VM failed to complete

<!--

Whenever a wait condition times out, it means that something went wrong while a
VM was running its user data payload.

At the very end of the user data payload there is a curl command that accesses
the wait condition's magic URL.

If any of the scripts running before that curl command exits non-zero,
cloud-init will stop executing user data scripts.

Thus the script that signals the wait condition will never run.

-->

## Debugging Tools

<!--

While the causes for wait condition timeouts may vary, the debugging tools are
always the same.

-->

## Debugging Tools

* Find cluster's Heat stack ID

<!-- First of all you need to find the cluster's main Heat stack ID: -->

## Debugging Tools

* Find cluster's Heat stack ID

```
$ include(cmd/cluster-stack-id.sh)
```

## Debugging Tools

* Find cluster's Heat stack ID

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

<!--

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

-->

## Debugging Tools

* Find cluster's Heat stack ID

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

* Find timed out wait condition

<!--

Once you have that Heat stack ID, you need to list its resources and find
the offending `WaitCondition`:

-->


## Debugging Tools

* Find cluster's Heat stack ID

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

* Find timed out wait condition

```
$ include(cmd/find-wait-condition.sh)
```

## Debugging Tools

* Find cluster's Heat stack ID

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

* Find timed out wait condition

```
$ include(cmd/find-wait-condition.sh)include(output/failed-master-wait-condition)
```

<!--

```
$ include(cmd/find-wait-condition.sh)include(output/failed-master-wait-condition)
```

We are only interested in the first and last columns here, hence the `awk` We
need the first column to see whether a Kubernetes master or minion is affected.

If we only have a single master setup that already tells us which machine to
log in to in the next step.

If we have a multi master setup we need to use the Heat stack name from the
last column to look up the problematic node's floating IP address.

Magnum creates a nested Heat stack for each cluster node.

Each of these nested stacks comes with its own wait condition.

The command shown above will list all of these since it will descend into the
nested stacks' resources recursively.

Once we have found the failed wait condition we search for its stack name in
the same resource list and pick out the FloatingIP resource in that same stack.

We perform a `openstack stack resource-show` on that floating IP and get the IP
address to SSH to.

-->

## Debugging Tools

* Find cluster's Heat stack ID

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

* Find timed out wait condition

```
$ include(cmd/find-wait-condition.sh)include(output/failed-master-wait-condition)
```

* Examine `cloud-init` log on VM:

<!--

The final step happens on the machine behind the floating IP machine we SSHed to.

We need to examine its cloud-init log:

-->

## Debugging Tools

* Find cluster's Heat stack ID

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

* Find timed out wait condition

```
$ include(cmd/find-wait-condition.sh)include(output/failed-master-wait-condition)
```

* Examine `cloud-init` log on failed VM:

```
/var/log/cloud-init-output.log
```

<!--

```
/var/log/cloud-init-output.log
```

This log contains all output from cloud-init. We will cover it in more detail
in a bit.

-->


## Wait Condition Timeout: `etcd` Discovery

<!--

One fairly common problem, especially in Enterprise environments is
failing `etcd` discovery.

-->

## Wait Condition Timeout: `etcd` Discovery

* Magnum cluster nodes use etcd to synchronize

<!--

As mentioned previously, Magnum cluster nodes use etcd to synchronize with each
other.

-->

## Wait Condition Timeout: `etcd` Discovery

* Magnum cluster nodes use etcd to synchronize

* Need to be able to reach etcd discovery URL

<!--

There is a catch with that: the nodes need to be able to reach the cluster's
`etcd` discovery URL to record their own membership in the `etcd` cluster and
discover the other `etcd` cluster members.

-->

* URL may be unreachable due to...

<!--

While there is the sanity check in the Magnum API we mentioned earlier, that
only checks for reachability from the machine the Magnum API runs on.

That machine is unlikely to be in the same network the Magnum cluster's
floating IPs access the world from.

And that network is often a less-than-favourable vantage point in an enterprise
network.

For there may be...

-->

## Wait Condition Timeout: `etcd` Discovery

* Magnum cluster nodes use etcd to synchronize

* Need to be able to reach etcd discovery URL

* URL may be unreachable due to...

## Wait Condition Timeout: `etcd` Discovery

* Magnum cluster nodes use etcd to synchronize

* Need to be able to reach etcd discovery URL

* URL may be unreachable due to...

  * ...firewall rules

<!--

1. ...any number of firewall rules restricting access to the outside world, where
   `discovery.etcd.io` sits.

-->

## Wait Condition Timeout: `etcd` Discovery

* Magnum cluster nodes use etcd to synchronize

* Need to be able to reach etcd discovery URL

* URL may be unreachable due to...

  * ...firewall rules

  * ...misconfigured public network (e.g. missing routes)

<!--

2. ...a misconfigured public network that does not even have a route it could
   reach `discovery.etcd.io` or an internal `etcd` discovery server through.

-->


## Wait Condition Timeout: `etcd` Discovery

* Magnum cluster nodes use etcd to synchronize

* Need to be able to reach etcd discovery URL

* URL may be unreachable due to...

  * ...firewall rules

  * ...misconfigured public network (e.g. missing routes)

  * ...DNS breakage or filters

<!--

3. ...a DNS setup that yields a `NXDOMAIN` for the etcd URL, either because it
   only resolves internal URLs or because `discovery.etcd.io` is filtered to
   keep users from leaking internal information that way.

-->

## Wait Condition Timeout: `etcd` Discovery

* Magnum cluster nodes use `etcd` to synchronize

* Need to be able to reach `etcd` discovery URL

* URL may be unreachable due to...

  * ...firewall rules

  * ...misconfigured public network (e.g. missing routes)

  * ...DNS breakage or filters

* Error message in journal for `etcd`:

```
cluster status check: error connecting to https://discovery.etcd.io, retrying in 2s
```

<!--

If you see an error message like this in the journal for etcd, you probably
need to fix your network setup:

```
cluster status check: error connecting to https://discovery.etcd.io, retrying in 2s
```

-->

## Wait Condition Timeout: `etcd` Discovery

* Magnum cluster nodes use `etcd` to synchronize

* Need to be able to reach `etcd` discovery URL

* URL may be unreachable due to...

  * ...firewall rules

  * ...misconfigured public network (e.g. missing routes)

  * ...DNS breakage or filters

* Error message in journal for `etcd`:

```
cluster status check: error connecting to https://discovery.etcd.io, retrying in 2s
```

* To verify: `curl` on cluster's discovery URL from inside the affected VM.

<!--

Alternatively, you can check whether you are facing this problem by running
`curl` on the cluster's `etcd` discovery URL from the affected VM.

You will find this URL in the cluster's `discovery_url` attribute)

-->

## Wait Condition Timeout: User Data Script Fails

<!--

## Wait Condition Timeout: User Data Script Fails

If the problem is not etcd, some other part of the user data scripts may have
gone haywire.

We will not go into detail here, for these may fail at any point and time is
rather limited. The debugging process is always the same, though.

-->

## Wait Condition Timeout: User Data Script Fails

* Background 

<!--

### Background

First of all, let's have a little refresher on how a Magnum cluster's nodes are
being deployed.

-->

## Wait Condition Timeout: User Data Script Fails

* Background 

  * Each node is set up by multiple `cloud-init` user data scripts

<!--

Each node runs multiple `cloud-init` user data scripts.

There's usually around six to eight of these.

The exact number and type of scripts varies depending on the platform,
container orchestration engine and various other attributes such as the volume
driver.

-->

## Wait Condition Timeout: User Data Script Fails

* Background 

  * Each node is set up by multiple `cloud-init` user data scripts

  * Any of these scripts may fail on one or more nodes

<!--

Any of these scripts may fail for all sorts of reasons.

-->

## Wait Condition Timeout: User Data Script Fails

* Background 

  * Each node is set up by multiple `cloud-init` user data scripts

  * Any of these scripts may fail on one or more nodes

* Debugging 

<!--

If one of them fails, debug the problem as follows:

-->

## Wait Condition Timeout: User Data Script Fails

* Background 

  * Each node is set up by multiple `cloud-init` user data scripts

  * Any of these scripts may fail on one or more nodes

* Debugging 

  * `/var/log/cloud-init-output.log` on the affected node should give you a
    first idea of what went wrong.

<!--

First of all, log into the VM for which the wait condition timed out.

We already covered this part earlier.

On that machine, take a look at `/var/log/cloud-init-output.log`.

If you are lucky this log will already contain useful information that shows you
exactly what the problem is.

-->

## Wait Condition Timeout: User Data Script Fails

* Background 

  * Each node is set up by multiple `cloud-init` user data scripts

  * Any of these scripts may fail on one or more nodes

* Debugging

  * `/var/log/cloud-init-output.log` on the affected node should give you a first
    idea of what went wrong.

  * Re-run failed script from `/var/lib/cloud/instance/scripts` with debugging
    output

<!--

Usually you will not be lucky though and you will only see a non-zero exit
status for a particular script, without knowing why that happened.

In that case you can add debugging output to the failed user data script and
re-run it.  You will find the scripts in `/var/lib/cloud/instance/scripts`.

-->

## Wait Condition Timeout: User Data Script Fails

* Background 

  * Each node is set up by multiple `cloud-init` user data scripts

  * Any of these scripts may fail on one or more nodes

* Debugging

  * `/var/log/cloud-init-output.log` on the affected node should give you a first
    idea of what went wrong.

  * Re-run failed script from `/var/lib/cloud/instance/scripts` with debugging
    output

  * You may have to modify Magnum's user data fragments (`fragments/` directories
    under `magnum/drivers/`) to add additional debugging output.

<!--

If the problem is only reproducible on a pristine node, your last resort is
modifying the script in the Magnum source tree on your controller node if you've
got that level of access. 

You will find the user data scripts in one of the `fragments/` directories
under `magnum/drivers` in the Magnum source tree.

Where exactly the Magnum source tree resides depends on your controller's
operating system and whether you installed Magnum from a package or via `pip`.

-->

## Wait Condition Timeout: User Data Script Fails

* Background 

  * Each node is set up by multiple `cloud-init` user data scripts

  * Any of these scripts may fail on one or more nodes

* Debugging

  * `/var/log/cloud-init-output.log` on the affected node should give you a first
    idea of what went wrong.

  * You may have to modify Magnum's user data fragments (`fragments/` directories
    under `magnum/drivers/`) to add additional debugging output (or directly in
    `/var/lib/cloud/instance/scripts` on the VM).

  * Modifying fragments in the Magnum source tree requires recreating the
    cluster

<!--

Editing the fragments in the Magnum source tree is a bit tedious since it
requires recreating the cluster with the modified fragments in place.

Nonetheless this is sometimes required since the node may no longer be in the
state it needs to be in if you re-run one of the `cloud-init` fragments.

-->

## Wait Condition Timeout: Timeout Too Low

<!--

If you logged in to the failed cluster node and found a suceessful `cloud-init`
run without any problems, the problem is the wait condition timeout itself.

-->

## Wait Condition Timeout: Timeout Too Low

* Usually happens when deploying large clusters (100+ nodes) on busy clouds

<!--

This usually happens when deploying large clusters on large, busy clouds. On
such a cloud, cluster deployment may take longer than a wait condition's time
out.

-->


## Wait Condition Timeout: Timeout Too Low

* Usually happens when deploying large clusters (100+ nodes) on busy clouds

* Rare these days (generous default timeouts based on experience)

<!--

This used to be a fairly common problem in the past but nowadays it has become
quite rare:

the default timeout for wait conditions is a generous 60 minutes, which should
suffice for most clusters and clouds.

-->


## Wait Condition Timeout: Timeout Too Low

* Usually happens when deploying large clusters (100+ nodes) on busy clouds

* Rare these days (generous default timeouts based on experience)

* Troubleshooting:

<!--

Diagnosing this is fairly easy:

-->

## Wait Condition Timeout: Timeout Too Low

* Usually happens when deploying large clusters (100+ nodes) on busy clouds

* Rare these days (generous default timeouts based on experience)

* Troubleshooting:

  * Check for all previous issues first

<!--

First of all make sure the `user-data` script on the failing wait condition's
node did indeed suceed, to rule out any other issues.

-->


## Wait Condition Timeout: Timeout Too Low

* Usually happens when deploying large clusters (100+ nodes) on busy clouds

* Rare these days (generous default timeouts based on experience)

* Troubleshooting:

  * Check for all previous issues first

  * If the user-data script on the affected node succeeded, time deployment and
    recreate cluster with appropriate `--timeout` option.

<!--

If it did succeed, check how long deployment took (just check the cluster's
`created_at` time stamp) against the wait condition's time stamp.

Now recreate the cluster with a timeout that exceeds this time span.

-->

## Wait Condition Timeout: TLS failure

* Usually happens when using self-signed certificates

* Troubleshooting:

  * Check if `openstack_ca_file option` is set to the OpenStack CA in the driver
  section in magnum.conf

<!--

It is common to use self-signed or certificates signed from CAs that are
usually not included in the systems' default CA-bundles.

Magnum cluster nodes with TLS enabled have their own CA but they need to make
requests to the OpenStack APIs for several reasons: 

* Signal deployment completion through the Heat API 
* Create resources (volumes, load balancers) or get information for each node
  (Cinder, Neutron, Nova).

In these cases, the cluster nodes need the CA certificate that signed the APIs'
SSL certificates.

To pass the OpenStack CA bundle to the nodes you can set the CA using the
openstack_ca_file option in the drivers section of Magnums configuration file
(usually /etc/magnum/magnum.conf).

The default drivers in magnum install this CA in the system and set it in all
the places it might be needed.

-->


include(common/arch/arch13.md)

<!--

# cloud-init configures Kubernetes

Since Magnum put together a user-data payload for deploying Kubernetes, we will
hopefully end up with working Kubernetes once cloud-init has run to
conclusion.

"Hopefully" because this same process happens on all cluster instances, which
will also need to coordinate with each other using etcd to set up their Flannel
overlay networking, so there are plenty of moving parts and opportunities for
things to go sideways.

![cloud-init configures Kubernetes](img/magnum_architecture_13.PNG)

-->

include(common/arch/arch14.md)

<!--

# Kubernetes orchestrates Docker

For now, let's assume it all worked out and we now have Kubernetes and Docker for it
to orchestrate configured and working all machines.

![Kubernetes orchestrates Docker](img/magnum_architecture_14.PNG)

-->

include(common/arch/arch15.md)

<!--

So all that's missing now is a workload to run on our freshly created
Kubernetes cluster. Now how do we get that in there?

![Workload in Docker Containers](img/magnum_architecture_15.PNG)

-->

include(common/arch/arch16.md)

<!--

This is where the Magnum API comes into play again: when Magnum creates a
cluster, it knows where the cluster's APIs reside, of course.

It also generates and configures access credentials.

The Magnum API is equipped to share that information with a cluster's creating
user, and the Magnum client in turn comes with a very convenient mechanism for
putting that facility to good use:

its cluster-config operation will request access credentials for the container
orchestration engine's API, generate configuration for its native API
client and write it to a file.

In our case that client is the kubernetes client, `kubectl`.

Magnum will also output a shell environment suitable for pointing the native
client to that configuration file.

![Kubernetes Credentials from Magnum API](img/magnum_architecture_16.PNG)

-->

## Kubernetes Failures: API server/minions down

* Basic commands

  * `kubectl version`

  * `kubectl get nodes`

* If commands return nothing:

  * Configuration issue: check the master and minion config files in `/etc/kubernetes/`

<!--

Sometimes the API service is simply unreachable which you will see with the
kubectl version command. 

Sometimes the minion nodes are not reachable which will result in `kubectl get
nodes` returning.

This is usually a configuration issue.

-->

## Kubernetes Failures: Pods stuck in `ContainerCreating`

* Pods deployment stuck in ContainerCreating state

* Troubleshooting:

  * Check kube-controller, kube-apiserver and etcd service on master node.

  * Check if *cluster_user_trust* is set in the magnum config file

<!--


The pod can be stuck in creating for various reasons. 

The most common ones are kubernetes services or etcd being down.

It also may happens due to `cluster_user_trust` is not being in
the magnum config.

This happens in case the OpenStack services need to be reached as a part of the
pod creation process, for instance when using cinder as the volume driver for
the cluster.

-->

## Kubernetes Failures: Pods stuck in `Pending`

* Pods stuck in status Pending

* Troubleshooting:

 * Check internet access on the minion nodes.

<!--

The pod status is `Pending` while the Docker image is being downloaded, so if
the status does not change for a long time, log into the minion node and check
if it can access the Internet.

Likewise, if you specified a local Docker registry, make sure the minion node
can reach it.

-->

## Kubernetes Failures: Application Unreachable

* Pods and services deployed but application is unreachable

* Troubleshooting:

  * Check if neutron is working properly by pinging between the minion nodes.
  * Check if the docker0 and flannel0 interfaces are configured correctly.
  * Check if node IP's are in the correct flannel subnet, if not docker daemon
    is not configured correct with parameter --bip.
  * Check if flannel is running properly.
  * Check `kube_proxy` to check if the problem caused  is only on a kubernetes
    level.

<!--

This one is specific to the flannel network driver (which is the default).

There are different levels at which the network could be broken leading to
connectivity issues.

Firstly, make sure that neutron is working properly and that all the nodes in
the cluster are able to ping each other.

The networking between pods is different and separate from the neutron network
set up for the cluster.

Kubernetes presents a flat network space for the pods and services and uses
different network drivers to provide this network model.

* Start by checking the interfaces and the docker deamon.

* Then check flannel. Flannel is the default network driver for magnum which
  provides a flat network space for the containers in a cluster. Therefore, if
  Flannel fails, some containers will not be able to access services from other
  containers in the cluster.
  
* Finally, the containers created by Kubernetes for pods will be on the same IP
  subnet as the containers created directly in Docker and so they will have the
  same connectivity. However, the pods still may not be able to reach each
  other because normally they connect through Kubernetes services rather than
  directly. The services are supported by the `kube-proxy` service and rules
  inserted into `iptables`. Therefore their networking paths have some extra
  hops, one of which may come with extra problems.

-->
