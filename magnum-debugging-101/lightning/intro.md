## Magnum: tl;dr

* What?
  * Containers as a Service with orchestration
* What? (plain english)
  * Creates VMs with turnkey Kubernetes/Swarm/Mesos cluster set up on them
* How
  * Magnum creates VMs via Heat and configures Kubernetes/Swarm/Mesos with
    `cloud-init`

<!--

If you are watching this, you are probably aware of what Magnum is and how it
roughly works. Just to make sure, a very quick rundown:

It provides Containers as a Service with orchestration. In plain English that
means it creates a bunch of VMs with a turnkey Kubernetes, Swarm or Mesos
running on them. Under the hood it uses Heat and `cloud-init` to build these
clusters.

-->
