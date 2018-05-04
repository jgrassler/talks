# Overview

include(common/slides.md)

include(common/intro.md)

<!--

## How does it work?

Let's take a closer look at how exactly Magnum builds its clusters and gives
you access to them. We'll start with a user's perspective.

### User's point of view

First of all, the user describes the container infrastructure they want in terms
of a cluster template. A cluster template is a data structure defining one or
more cluster's properties, which is to say it can be shared by multiple
cluster's. A cluster template defines which container orchestration engine
(such as Kubernetes) to use for the cluster, or which Glance image to run on
its instances.

Once there is a cluster template, the user requests creation of one or more
Magnum clusters based on this template's properties. Magnum will then do its
magic in the background and eventually it will hopefully report success. Now
the user can request access credentials for the container orchestration engine
from the Magnum API and use the orchestration engine's API to deploy their
workload.

### Magnum's point of view

When Magnum receives a request for cluster template creation it simply stores
it in the database. The interesting bit happens when it receives a request to
create a cluster based on that cluster template: now it uses the information
from the cluster template to stitch together a tailor-made Heat template for
deploying a cluster with these properties. It then passes that template to Heat
for building the cluster. While Heat is working on it, Magnum will continuously
poll the Heat API for the resulting Heat stack's state. Once it transitions to
CREATE_COMPLETE, the Magnum cluster will transition to CREATE_COMPLETE as well.

-->

# Magnum Under The Hood

## User...

include(common/arch/arch0.md)

<!--

# Magnum Under The Hood

Now that we've got a general idea of what Magnum is all about we'll zoom in a
bit and take a look at how it accomplishes its job.

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

include(common/arch/arch5.md)

<!--

# API to Conductor: "Create Cluster, please"

Now that the Magnum API has gotten a request to create a cluster, it does what
most OpenStack API services do when they receive a request to create a
resource: it passes a RabbitMQ message to its backend service,
magnum-conductor, which is tasked with the actual work of creating the cluster.

![API to Conductor: "Create Cluster, please"](img/magnum_architecture_5.PNG)

-->

include(common/arch/arch6.md)

<!--

# Generate a Heat Template Matching Cluster

Now magnum-conductor looks at both the Cluster's and the Cluster Template's
attributes and uses that information to stitch together a Heat template
implementing the cluster the user requested, in our case a Kubernetes cluster
on OpenSUSE. Magnum comes with drivers for various operating systems and
orchestration engines. All of these come with Heat templates that get assembled
into a nested Heat stack and lots of little shell scripts to deploy the cluster
instances that Magnum will mix and match inside the Heat templates' user data
payloads. I marked this step in red since we'll refer back to it later.

![Generate a Heat Template Matching Cluster](img/magnum_architecture_6.PNG)

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
networks, assigns Floating IPs and all the ingredients that go into a working
Heat stack. I won't go into any detail on this now, because last year's
[Heat workshop](https://github.com/SUSE/cloud/tree/master/presentations/2016-support-enablement-training/heat-workshop)
covers that part in far more detail than we could possibly fit here. At the
end of this process we'll have Nova instances with network connectivity up and
running, and we're primarily interested of what happens inside these.

![Heat Creates VMs and Plumbing](img/magnum_architecture_8.PNG)

-->

include(common/arch/arch9.md)

<!--

# VMs Run Container Friendly OS Image

First of all, the VMs run a container friendly operating system image. That may
be our own OpenSUSE Kubernetes image, Fedora Atomic, CoreOS or Ubuntu Mesos.
That image should have all or at least most packages required for running the
requested container orchestration engine already installed and Magnum will
mostly only configure them.

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

## Slides and Transcript

include(common/slides.md)

<!--

This concludes the introduction part. We are putting up the URL to the slides
again, because the slides and the supporting material (especially the little
code snippets you can paste from in a pinch) will come in handy for the hand-on
part. Does everybody have the slides? If you do not, please download them now.

-->
