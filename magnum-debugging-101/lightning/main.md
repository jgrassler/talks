## User...

include(common/arch/arch0.md)

<!--

# User...

Like many stories in our profession, this one one starts with a user. That user
operates a Magnum client.

![User...](img/magnum_architecture_0.PNG)

-->

include(common/arch/arch1.md)

<!--

# User and Magnum API

That client talks to the Magnum API.

![User and Magnum API](img/magnum_architecture_1.PNG)

-->

include(common/arch/arch2.md)


<!--

# Describe Cluster in ClusterTemplate

The first thing we create with this client is a cluster template. That holds
most of the metadata describing a Magnum cluster.

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
metadata. Magnum uses this field to determine which image specific driver to
use, so set it and the error will go away.

-->

include(common/arch/arch3.md)

<!--

# Create Cluster...

![Create Cluster...](img/magnum_architecture_3.PNG)

-->

include(common/arch/arch4.md)

<!--

# ...based on ClusterTemplate

Now that we have a Cluster Template we can create the cluster itself, which
references it.  For that we'll need to reference the cluster template by name
or UUID.

![...based on ClusterTemplate](img/magnum_architecture_4.PNG)

-->

## Early `CREATE_FAILED` from Magnum

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * A `status` value of `CREATE_FAILED` indicates creation failure

  * Error message in `status_reason` upon `CREATE_FAILED`

* Common early failures from Magnum itself:

  * `Failed to get discovery url from 'https://discovery.etcd.io/new?size=1'`

  * `This cluster can only be created with trust/cluster_user_trust = True in magnum.conf`

<!--

At this point we may encounter a different failure. Magnum won't tell us right
away because it is creating the cluster in the background. To see its status we
need to poll the Magnum API...

```
include(cmd/cluster-show.sh)
```

and examine the `status` and `stack_status` fields. `status` will tell us if
creation failed, `status_reason` will tell us why it failed if it did.

If we get a `CREATE_FAILED` after only a couple of seconds it's usually
a failure to `magnum-api` obtain a `etcd` discovery URL. On a Newton cloud you
may see this error message about `cluster_user_trust`, but as of Ocata this
check has been remover. Instead, things that communicate with Openstack APIs
from inside the cluster will fail with authentication errors. You will find
more information on this in the 40 minute version.

-->

include(common/arch/arch5.md)

<!--

# API to Conductor: "Create Cluster, please"

Now that the Magnum API has gotten a request to create a cluster, it passes a
RabbitMQ message to its backend service, `magnum-conductor`, which does the
actual work.

![API to Conductor: "Create Cluster, please"](img/magnum_architecture_5.PNG)

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

Now that may go wrong. Depending on whether RabbitMQ or just magnum-conductor
is down you will either experience an indefinite Magnum client hang or see this
error message. Check whether `magnum-conductor` and RabbitMQ are up and running
in that case.

-->

include(common/arch/arch6.md)

<!--

# Generate a Heat Template Matching Cluster

Now `magnum-conductor` generates a Heat template from the information in the
cluster and cluster template...

![Generate a Heat Template Matching Cluster](img/magnum_architecture_6.PNG)

-->

include(common/arch/arch7.md)

<!--

# Send Heat Template to Heat API


![Send Heat Template to Heat API](img/magnum_architecture_7.PNG)


...and submits it to the Heat API.

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

If cluster creation fails after 30 seconds to a few minutes
we will see creation failures passed through from Heat. Again we check the
cluster's `status` and `status_reason` which contains the passed through
`stack_status_reason` from Heat. Failures at this point are usually either
resource exhaustion problems such as the ever popular `No valid host was found`
from Nova or the equally popular "our cloud admin forgot bumping the default
quota of 10 volumes to something more sensible".

-->

include(common/arch/arch9.md)

<!--

# VMs Run Container Friendly OS Image

If we make it past this hurdle we will now have a bunch of VMs with a container
friedly image...

![VMs Run Container Friendly OS Image](img/magnum_architecture_9.PNG)

-->

include(common/arch/arch12.md)

<!--

# user-data run by cloud-init

...on which `cloud-init` runs the CloudConfig snippets generated by Magnum.
If that fails to complete we will see the most common Magnum failure mode:

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

Now this user data script is where the most common failure mode occurs: the
wait condition timeout.

Just like other errors, you will see this one in the `status_reason` field.

Wait condition timeouts happen if the user data scripts on an instance fail to
signal completion: for the very last script to run accesses the wait
condition's URL. If that URL is accessed late or never, the wait condition
times out and transitions to `CREATE_FAILED` state.

-->

## Debugging Wait Condition Timeouts

* Find cluster's Heat stack ID

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

* Find timed out wait condition

```
$ include(cmd/find-wait-condition-short.sh)include(output/failed-master-wait-condition-short)
```

<!--

## Debugging Wait Condition Timeouts

If you do encounter this problem you always use the same basic debugging
process:

First of all you need to find the cluster's main Heat stack ID:

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

Second, you list the stack's resources and find the offending wait condition
the offending `WaitCondition`:

```
$ include(cmd/find-wait-condition.sh)include(output/failed-master-wait-condition)
```

We are only interested in the first and last column here, hence the `awk`. The
first column tells us whether the problematic node is a master or minion node.

-->

## Debugging Wait Condition Timeouts (cont.)

* ssh to VMs (substitute node type name for Mesos/Swarm)

  * Try all masters if wait condition is named `master_wait_condition`

  * Try all minions if wait condition is named `minion_wait_condition`

* Examine `cloud-init` log on failed VM:

```
/var/log/cloud-init-output.log
```

* Add debugging output to failed user data script from
  `/var/lib/cloud/instance/scripts/` and re-run it

* Last resort: add debugging output to scripts in (`fragments/` directories in
  `magnum/drivers` source tree subdirectory) and recreate cluster

<!--

If you know whether the problematic node is a master or minion you ssh to all
nodes of that type and examine `/var/log/cloud-init-output.log` for errors.
Once you've got a log with errors you've found the broken node. You could find
the exact node by digging through Heat, but takes too long to explain here.

Now you might get lucky and see the problem in the log. If there's no useful
information in there other than "this script failed", add debug output to the
script in question and re-run it. Finally, if the problem requires a pristine
VM to reproduce, you'll have to add your debug output to the same script in the
Magnum source tree and recreate the cluster.

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
   clouds. In the rare case where you've got a successful user data script
   simply taking to long, recreating the cluster with an even bigger timeout
   will fix the problem.

-->

include(common/arch/arch14.md)

<!--

# Kubernetes orchestrates Docker

# cloud-init configures Kubernetes

Let's assume all cloud-init scripts run fine. Then `cloud-init` configures
Kubernetes now...

![Kubernetes orchestrates Docker](img/magnum_architecture_14.PNG)

-->

include(common/arch/arch15.md)

<!--

...and the cluster is ready to receive containers.

![Workload in Docker Containers](img/magnum_architecture_15.PNG)

-->

include(common/arch/arch16.md)

<!--

And now the user comes along and starts talking to the Kubernetes API...

![Kubernetes Credentials from Magnum API](img/magnum_architecture_16.PNG)

-->

## Kubernetes Failures

<!-- TODO slunkad: fill in some Kubernetes errors (maybe some problems caused by cluster_user_trust=False in situations where the trust token is needed -->
