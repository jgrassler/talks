## What is Magnum?

* Overview

  * Fairly new OpenStack service (started in Kilo)

  * Provides CaaS (Containers as a Service) with orchestration

  * Supported Container orchestration engines: Kubernetes, Docker Swarm, Ubuntu Mesos

* Underlying Technologies

  * Various Linux images supported (CoreOS, Fedora Atomic, OpenSUSE)

  * [Heat](https://wiki.openstack.org/wiki/Heat) for providing the VMs/networks making up the cluster

  * [Flannel](https://coreos.com/flannel/docs/latest/) overlay network: allows communication between containers on different hosts

  * [cloud-init](https://cloudinit.readthedocs.io/) for setting up container infrastructure on cluster VMs

<!--

# Overview

## What is Magnum?

Magnum is a fairly new OpenStack service. It became part of OpenStack with the
Kilo release. If I were to sum it up in one sentence I'd say it provides
Containers-as-a-Service with orchestration. The emphasis is on "orchestration".
Magnum can build Kubernetes, Docker Swarm or Ubunutu Mesos clusters using the
standard OpenStack building blocks - Nova instances, Neutron networks, Cinder
volumes and others, all tied together with a Magnum generated Heat template.

Under the hood, Magnum uses Heat and cloud-init to create its infrastructure,
and Flannel to build an overlay network between instances. The Docker
containers can use this overlay network for internal communication.

-->

## How does it work?

* User's point of view

  * Describe cluster infrastructure (e.g. orchestration engine, Glance image) in terms of *Cluster Templates*.

  * Create a Magnum *Cluster* in an OpenStack project based on this Cluster Template.

  * Access cluster's native API (Docker, Kubernetes) and deploy containerized workload on it.

* Magnum's point of view

  * Generate the appropriate Heat template for the orchestration engine/Linux image combination specified by the user.

  * Parametrize and instantiate the Heat stack and wait for it to deploy.

  * Report success to the user.

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
