# Overview

include(common/slides.md)

include(common/intro.md)

# Magnum Under The Hood

<!--

# Magnum Under The Hood

Now that we've got a general idea of what Magnum is all about we'll zoom in a
bit and accompany a cluster through its whole life cycle.

-->

## User...

include(common/arch/arch0.md)

<!--

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
the user tells Magnum which orchestration engine to provide, and which image to
use and many other things.

![Describe Cluster in ClusterTemplate](img/magnum_architecture_2.PNG)

-->



## Cluster Template: Missing `os-distro` Field

```
ERROR: Image doesn't contain os-distro field. (HTTP 404)
```

* Glance image needs to have `os-distro` field in its metadata

* `os-distro` needs to match a Magnum driver's cluster distribution such as
  `jeos` or `fedora-atomic`

<!--

## Cluster Template: Missing `os-distro` Field

At this point we can already encounter a problem. It's trivial to solve but the
error message leaves something to be desired, so we will cover it here:

```
ERROR: Image doesn't contain os-distro field. (HTTP 404)
```

This happens if the Glance image does not have an `os-distro` field in its
metadata. Magnum uses this field to determine which driver to use, so set it to
fix this problem.

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

For that you'll need to reference the cluster template by name or UUID.

![...based on ClusterTemplate](img/magnum_architecture_4.PNG)

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

There are a couple of ways cluster creation can fail early on. All of these
are validation errors that happen inside Magnum, before Magnum even talks to
other service. To see them we need to take a look at the cluster's status with
a `cluster show` command:

```
include(cmd/cluster-show.sh)
```

Much like Heat, magnum's `cluster create` command will return immediately and
report succcess if the creation request was issued successfully. To get the
cluster's status we need to poll the Magnum API with `cluster show`.

In its output we look at the `status` and `status_reason` field. If `status`
indicates an error status such as `CREATE_FAILED` we'll usually find a helpful
error message in `stack_status_reason`. Failures at this stage usually happen
due to Magnum being unable to create a new etcd cluster:

```
Failed to get discovery url from 'https://discovery.etcd.io/new?size=1'
```

If you use Newton you may also encounter this message about `cluster_user_trust`:

`This cluster can only be created with trust/cluster_user_trust = True in magnum.conf`

In later Openstack releases this check and message have been removed: the lack
of this setting causes problems much later now. We'll take another look at that
during Kubernetes debugging.

-->

include(common/arch/arch5.md)

<!--

# API to Conductor: "Create Cluster, please"

Now that the Magnum API has gotten a request to create a cluster, it passes a
RabbitMQ message to its backend service, magnum-conductor, which is tasked with
the actual work of creating the cluster.

![API to Conductor: "Create Cluster, please"](img/magnum_architecture_5.PNG)

-->

include(common/arch/arch6.md)

<!--

# Generate a Heat Template Matching Cluster

Now magnum-conductor looks at both the Cluster's and the Cluster Template's
attributes and uses that information to stitch together a Heat template
implementing the cluster the user requested, in our case a Kubernetes cluster
on OpenSUSE.

![Generate a Heat Template Matching Cluster](img/magnum_architecture_6.PNG)

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

## Timeouts and frozen clients

Before we get to problems during cluster creation let's look at a Magnum API
error that may be a bit puzzling if it occurs: Sometimes Magnum clients hang.

```
include(output/conductor-down) 
```

Sometimes you get this error message after about a minute, sometimes it just
hangs. In the first case the problem happens because there's no
`magnum-conductor` processing messages `magnum-api` drops into RabbitMQ. In the
second case you are dealing with a RabbitMQ outage. In both cases just make
sure these services run.

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
networks, assigns Floating IPs and adds all the other ingredients that go into
a working Heat stack.

![Heat Creates VMs and Plumbing](img/magnum_architecture_8.PNG)

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

## Early `CREATE_FAILED` from Heat

If cluster creation takes a little longer to fail (on the order of 30 seconds
to a few minutes, depending on cluster size and cloud load) we may see creation
failures passed through from Heat. Again we check the cluster's `status` and
`status_reason` which contains the passed through `stack_status_reason` from
Heat. If we see Heat failures at this early time, it's usually either resource
exhaustion such as the ever popular `No valid host was found` from Nova or the
similarly popular "our cloud admin forgot bumping the default quota of 10
volumes to something more sensible".

-->

include(common/arch/arch9.md)

<!--

# VMs Run Container Friendly OS Image

First of all, the VMs run a container friendly operating system image. That may
be our own OpenSUSE Kubernetes image (which we are still in the process of
pushing upstream), Fedora Atomic, CoreOS or Ubuntu Mesos. That image should
have all or at least most packages required for running the requested container
orchestration engine already installed and Magnum will mostly only configure
them.

![VMs Run Container Friendly OS Image](img/magnum_architecture_9.PNG)

-->

include(common/arch/arch10.md)

<!--

# VMs Run Container Friendly OS Image

Configuration is where the red stuff from earlier comes into play again. I
mentioned before that there is pool of deployment scripts Magnum picks from
when generating its Heat templates. These got passed into Heat as a CloudConfig
resource.

![CloudConfig Snippets...](img/magnum_architecture_10.PNG)

-->

include(common/arch/arch11.md)

<!--

# CloudConfig Snippets Become user-data

This CloudConfig resource ends up as a user-data payload on the Nova instances
now.

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

* Error message

 * `Resource CREATE failed: WaitConditionTimeout`

* Most common failure mode

* Background:

  * Cluster node deployment is synchronized via Heat wait conditions

  * If wait conditions are not triggered before their timeout, they fail

* Meaning of timeout: `user-data` scripts inside VM failed to complete

<!--

Now this user data script is where the most common error occurs: the wait
condition timeout.

Just like the other errors, this error will be visible in the cluster's
`status_reason` field: Whenever there is a `Resource CREATE failed:
WaitConditionTimeout`, in there, you are facing this problem.

Wait condition timeouts are the most common failure mode for Magnum clusters.
The causes vary, but most problems will manifest as a wait condition timeout.

Wait conditions are a Heat mechanism the user data scripts use to signal
completion to Heat. If a wait condition's signalling URL is never accessed, it
eventually times out.

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

* Add debugging output to failed user data script from
  `/var/lib/cloud/instance/scripts/` and re-run it

* Last resort: add debugging output to scripts in (`fragments/` directories in
  `magnum/drivers` source tree subdirectory) and recreate cluster

<!--

While the reasons for the timeout may vary (more on that on the next slide),
debugging always follows the same pattern:

First of all you need to find the cluster's main Heat stack ID:

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

Once you have that Heat stack ID, you need to list its resources and find
the offending `WaitCondition`:

```
$ include(cmd/find-wait-condition.sh)include(output/failed-master-wait-condition)
```

We are only interested in the first and last columns here, hence the `awk` We
need the first column for the resource's name and the last for the sub stack
it's in. We then retrieve the problematic VM's floating IP from that stack's
outputs, log in to it and examine `/var/log/cloud-init-output.log` to figure
out what is wrong with it.

If `cloud-init-output.log` only contains unhelpful information such as 
`Failed running /var/lib/cloud/instance/scripts/part-007`, we can add debugging
output to the script in question and re-run it.

If we need the VM in a pristine state to reproduce the problem, our last resort
is adding debugging output to the `cloud-init` fragments Magnum uses to
assemble its user data payload and recreate the cluster.

-->


## Wait Condition Timeout: Common failure modes

* Network issues (VMs cannot reach external resources)

  * Docker registry unreachable

  * `etcd` fails because cluster nodes cannot access `etcd` discovery URLs

  * SSL issues accessing resources with self-signed certificates

* Various sporadic user data script failures. Examples:

  * Random services crashing after a while and being unavailable during later
    deployment

  * `etcd` cluster fails to converge

  * `flannel` failing to start

* Genuine timeout

  * Usually on large clusters

  * Recreate cluster with higher wait condition timeout to fix

<!--

We do not have the time to go into detail on all possible issues that can
cause WaitCondition timeouts here. Please refer to the 40 minute version of
this talk and its transcript for details. That being said we can quickly sum
them up here:

There are basically three categories:

1. Network issues where the user-data scripts are unable to reach external
   issues or attempt or stumble upon certificate validation talking to a Magnum
   API that uses SSL with self-signed certificates.

2. User data scripts failing sporadically at some stage. There are a ton of
   moving parts in there and sometimes they fail. Some we've seen so far:

   * Random service crashes combined with user data script later expecting the
     service to run.
   * `etcd` or `flannel` acting up when a user data script expects them to work

3. Last but not least, the - normally generous - default timeout of 60 minutes
   for wait conditions may be too low for very large clusters on very busy
   clouds. That's rare, though: the default timeout has been bumped to 60
   minutes to cover most realistic scenarios. In the rare case where you've got
   a successful user data script simply taking to long, recreating the cluster
   with an even bigger timeout will fix the problem.

-->

include(common/arch/arch13.md)

<!--

# cloud-init configures Kubernetes

Since Magnum put together a user-data payload for deploying Kubernetes, we will
hopefully end up with working Kubernetes once cloud-init has run to
conclusion. "Hopefully" because this same process happens on all cluster
instances, which will also need to coordinate with each other using etcd to set
up their Flannel overlay networking, so there are plenty of moving parts and
opportunities for things to go sideways. We'll take a look at some of these
problems in the hands-on part later.

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
cluster, it knows where the cluster's APIs reside, of course. It also generates
and configures access credentials. The Magnum API is equipped to share that
information with a cluster's creating user, and the Magnum client in turn comes
with a very convenient mechanism for putting that facility to good use: its
cluster-config operation will request access credentials for the container
orchestration engine's API and generate configuration for its native API
client and write it to a file. In our case that client is the kubernetes
client, kubectl. Magnum will also output a shell environment suitable for
pointing the native client to that configuration file.

![Kubernetes Credentials from Magnum API](img/magnum_architecture_16.PNG)

-->

## Kubernetes Failures

<!-- TODO slunkad: fill in some Kubernetes errors (maybe some problems caused by cluster_user_trust=False in situations where the trust token is needed -->

## Slides and Transcript

include(common/slides.md)

<!--

This concludes the introduction part. We are putting up the URL to the slides
again, because the slides and the supporting material (especially the little
code snippets you can paste from in a pinch) will come in handy for the hand-on
part. Does everybody have the slides? If you do not, please download them now.

-->
