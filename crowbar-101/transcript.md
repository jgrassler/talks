

Crowbar is the installation and configuration management framework tool we use
for a bunch of SUSE products things right now.

Originally Crowbar was started by Dell as a tool to install and configure
distributed applications such as OpenStack on a cluster of machines. SUSE took
over in 2013 and we have been maintaining it ever since.

It's mainly used for SUSE OpenStack Cloud but it can also be used to set up
Ceph or Cloud Foundry.

Crowbar is configured and operated through a Ruby on Rails web interface which
also exports a REST API. On the other side we have a command line client to
talk to this REST API - much like the OpenStack CLI clients.




Let's have a look at Crowbar's features now and get a feel for what it can and
cannot do.

First of all, it can deal with mostly unprepared bare metal machines. All they
need to do is attempt to PXE boot. Crowbar will then automatically discover
them and display the machines that successfully booted in its Nodes view. You
can then assign names to these nodes, install an operating system on them and
apply barclamps to them.

Speaking of which: barclamps are the bread and butter of crowbar. A barclamp
is a plugin for configuring a service, such as OpenStack Nova. Note that a
service in this case can be - and usually is - a distributed system of multiple
different daemons running on multiple different machines.

Crowbar allows you to mix and match barclamps depending to a certain extent.
Concretely, if you use it to deploy an OpenStack cloud you can chose to deploy
only the services you want to deploy. For instance, you could omit Swift if you
don't need object storage.




Now that we have a general idea of what a barclamp is, we can have a closer
look at the implementation details. Barclamps consist of various components:

First and foremost they contain a chef cookbooks that is used for deploying the
service the barclamp is in charge of. Usually this chef cookbook consists of
multiple recipes. There may be dedicated recipes for deploying the API and
backend services, or for creating keystone and database users, for instance.
Services such as Neutron, Nova or Cinder will also have role recipes
aggregating the daemons and agents running on compute nodes and controllers,
respectively.

These chef recipes are not static of course. They can be parametrized through
Crowbar. We've got a fair amount of knobs and dials to adjust there - according
to a colleague who recently did a presentation on Crowbar we currently have
about 1500 individual settings across Crowbar. Since setting all of these
explicitely would be quite a burden on the user we provide sensible defaults in
the shape of `data bags`. The data bag for a barclamp consists of a JSON
formatted data structure with all the default settings and a JSON formatted
schema file which defines the data type and optional validation constraints for
each setting.


