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

That client talks to the Magnum API...

![User and Magnum API](img/magnum_architecture_1.PNG)

-->

include(common/arch/arch2.md)


<!--

# Describe Cluster in ClusterTemplate

...and creates a cluster template. A cluster template is a data structure
holding most of a magnum cluster's metadata, such as the container
orchestration engine and the glance image to use.

![Describe Cluster in ClusterTemplate](img/magnum_architecture_2.PNG)

-->



## Cluster Template: Missing `os-distro` Field

```
ERROR: Image doesn't contain os-distro field. (HTTP 404)
```

* Glance image needs to have `os-distro` field in its metadata

* Magnum uses `os-distro` to pick the image/container orchestration engine
  specific driver to deploy the cluster

<!--

## Cluster Template: Missing `os-distro` Field

This operation can fail due to the Glance image lacking an `os-distro` field:

```
ERROR: Image doesn't contain os-distro field. (HTTP 404)
```

Magnum uses this field to pick the image specific driver to use for cluster
setup, so set it and the error will go away.

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
references it.

![...based on ClusterTemplate](img/magnum_architecture_4.PNG)

-->

include(common/arch/arch5.md)

<!--

# API to Conductor: "Create Cluster, please"

When Magnum API gets this request to create a cluster, it passes a RabbitMQ
message to its backend service, `magnum-conductor`, which does the actual work.

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

That communication may break down, though. Depending on whether RabbitMQ or
just `magnum-conductor` is unavailable, `magnum-client` will either hang or
output this error message after a minute. If this happens, make sure both
services are up and running and retry.

-->

include(common/arch/arch5.md)

<!--

So, back to magnum-conductor. Let's assume it gets the message now.

-->

## Early `CREATE_FAILED` from `magnum-conductor`

* Cluster status

  * `include(cmd/cluster-show.sh)`

  * A `status` value of `CREATE_FAILED` indicates creation failure

  * Error message in `status_reason` upon `CREATE_FAILED`

* Common early failures from Magnum itself:

  * `Failed to get discovery url from 'https://discovery.etcd.io/new?size=1'`

<!--

From this point onward we need to poll the Magnum API...

```
include(cmd/cluster-show.sh)
```

...and examine the `status` and `status_reason` fields to see the state of our
cluster. `status` will tell us if cluster creation failed, suceeded or is still
in progress. `status_reason` will tell us why it failed if it did.

If we do get a `CREATE_FAILED` status after only a couple of seconds it's usually
due to `magnum-conductor` failing to obtain an `etcd` discovery URL. That one
is pretty common in enterprise environments where the machine magnum-conductor
runs on may not be able to access the Internet. In that case you will need to
set up a local `etcd` discovery service and specify it in your clusters'
cluster templates.

-->

include(common/arch/arch6.md)

<!--

## Generate a Heat Template Matching Cluster

If none of the early errors happened, `magnum-conductor` generates a Heat
template...

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

Heat will then spawn Nova instances, interconnect them with Neutron networks,
and add all the other ingredients required for our cluster...

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

...presuming it can. For it may encounter resource exhaustion problems such as
the ever popular `No valid host was found` or the equally popular "Oops, our
admin forgot increasing the default quota!".

-->

include(common/arch/arch9.md)

<!--

# VMs Run Container Friendly OS Image

If we make it past this hurdle we will now have a bunch of VMs...

![VMs Run Container Friendly OS Image](img/magnum_architecture_9.PNG)

-->

include(common/arch/arch12.md)

<!--

# user-data run by cloud-init

...on which `cloud-init` runs the CloudConfig scripts generated by Magnum. If
these fails to complete we will see the most common Magnum failure mode:

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
signal completion to the Heat API: the very last script to run does that. If
any of the scripts before it fails, the wait condition will time out.

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

Debugging this always follows the same pattern:

First of all you need to find the cluster's Heat stack ID:

```
$ include(cmd/cluster-stack-id.sh)include(output/cluster-stack-id)
```

Second, you list the stack's resources and find the offending wait condition:

```
$ include(cmd/find-wait-condition.sh)include(output/failed-master-wait-condition)
```

We are only interested in the first column here, hence the `awk`. The first
column tells us whether the problematic node is a master or minion node.

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

Now you ssh to all master or minion nodes (depending on what's in the first
column) nodes of that type and examine `/var/log/cloud-init-output.log` for
errors. Once you've got a log with errors you've found the broken node. You
could find the exact node by digging through Heat, but that takes too long to
explain here.

Once you've got the problematic node, you've got 3 levels of debugging
escalation:

1) You might get lucky and see the problem in the log.

2) If there's no useful information in there other than "this script failed",
add debug output to the script and re-run it.

3) If the problem requires a pristine VM to reproduce, you'll have to
add your debug output to the same script in the Magnum source tree and recreate
the cluster.

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

There are three basic categories of wait condition timeout:

1. Network issues where the user-data scripts are unable to reach external
   resources or stumble upon SSL certificate validation.

2. User data scripts failing sporadically at some stage. There are a ton of
   moving parts in there and sometimes they fail. Some we've seen so far:

   *  Services crashing a little after startup
   * `etcd` or `flannel` acting up when a user data script expects them to work

3. Last but not least, default timeout of 60 minutes for wait conditions may be
   too low for very large clusters on very busy clouds. In the rare case where
   you've got successful user data scripts across the board script they may
   simply be taking to long. Recreating the cluster with a bigger timeout
   should fix the problem.

-->

include(common/arch/arch14.md)

<!--

# Kubernetes orchestrates Docker

# cloud-init configures Kubernetes

Let's assume all cloud-init scripts run fine. Then `cloud-init` will have
configured Kubernetes now...

![Kubernetes orchestrates Docker](img/magnum_architecture_14.PNG)

-->

include(common/arch/arch15.md)

<!--

...and the cluster is ready to receive containers.

![Workload in Docker Containers](img/magnum_architecture_15.PNG)

-->

include(common/arch/arch16.md)

<!--

And now the user comes along and starts talking to the Kubernetes API.
There may be any number of problems with that, but this is the point where
we'd like to refer you to Magnum's own [troubleshooting guide](https://docs.openstack.org/magnum/latest/admin/troubleshooting-guide.html)
which has a lot of on troubleshooting information on Kubernetes.

![Kubernetes Credentials from Magnum API](img/magnum_architecture_16.PNG)

-->

## Kubernetes Failures

* kubectl version

* kubectl get nodes

* Troubleshooting:

  * Configuration issue: check the master and minion config files in /etc/kubernetes/

* Pods deployment stuck in ContainerCreating state

 * Check kube-controller, kube-apiserver and etcd service on master node.

  * Check if *cluster_user_trust* is set in the magnum config file

* Pods stuck in status Pending

* Troubleshooting:

 * Check internet access on the minion nodes.

* Pods and services deployed but application is unreachable

* Troubleshooting:

  * Check if neutron is working properly by pinging between the minion nodes.
  * Check if the docker0 and flannel0 interfaces are configured correctly.
  * Check if node IP's are in the correct flannel subnet, if not docker daemon
    is not configured correct with parameter --bip.
  * Check if flannel is running properly.
  * Check kube_proxy to check if the problem caused  is only on a kubernetes
    level.

<!--

A few things can go wrong like the apiserver is down which you will see with
the kubectl version command or the minion nodes are not reachable which will
result in  kubectl get nodes returning nothing which again mostly is a config
related issue.

The pod can be stuck in creating state due to several reasons but the most
likely could be that the kubernetes services or etcd is down. Another common
reason when it happens is when cluster_user_trust is not set in the magnum
config. This happens in case the OpenStack services need to be reached as a
part of the pod creation for eg when using cinder as the volume driver for the
cluster.

The pod status is Pending while the Docker image is being downloaded, so if
the status does not change for a long time, log into the minion node and check
for Cluster internet access.

Note: This is specific to the default network driver flannel.
There are different levels at which the network could be broken leading to
connectivity issues. Firstly, make sure that neutron is working properly and
that all the nodes in the cluster are able to ping each other. The networking
between pods is different and separate from the neutron network set up for the
cluster. Kubernetes presents a flat network space for the pods and services and
uses different network drivers to provide this network model. Start by checking
the interfaces and the docker deamon. Then check flannel which is the default
network driver for magnum which provides a flat network space for the
containers in a cluster. Therefore, if Flannel fails, some containers will not
be able to access services from other containers in the cluster. Lastly, the
containers created by Kubernetes for pods will be on the same IP subnet as the
containers created directly in Docker and so they will have the same connectivity.
However, the pods still may not be able to reach each other because normally they
connect through some Kubernetes services rather than directly. The services are
supported by the kube-proxy and rules inserted into the iptables, therefore their
networking paths have some extra hops and there may be problems here.

-->



