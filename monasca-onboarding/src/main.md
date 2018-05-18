# Preliminaries

<!--

# Preliminaries

-->

## Slides and Transcript

include(src/slides.md)

<!--

The slides and a transcript for this session are available online. We will
display a QR encoded, shortened URL for the tarball at the end, so don't worry
about writing down the URLs now.

-->

## This Session

* What it is:

  * Primer on Monasca

  * Overview of Monasca repositories and architecture

  * Introduction to the specifics of Monasca development

  * How can you contribute?

* What it is not

  * General introduction to OpenStack development

  * Refer to [Code & Documentation Contributor Guide](https://docs.openstack.org/contributors/code-and-documentation/index.html)
    for that.

<!--

## This Session

Before we begin, a quick rundown on what we'll cover:

We'll start out with a quick primer on Monasca, what it is and what it does.

Next we'll take you on a guided tour of Monasca's architecture diagram. We'll
intermingle this with information on which repository holds each component and
some development hints.

After that, end we will show you various ways to build a development
environment and how to test your code.

Finally we will show you how we organize and priorize development

We do assume you already are familiar with the OpenStack development process
and tools. If you are not, please read the 
[Code & Documentation Contributor Guide](https://docs.openstack.org/contributors/code-and-documentation/index.html).

-->

## What is Monasca?

* Monitoring and Logging as a Service

  * Highly scalable

  * Fault tolerant

  * High Performance

  * Multi-tenant

<!--

## What is Monasca?

So, what is Monasca?

In a nutshell, it's Monitoring and Logging as a Service.

It's highly scalable: we took care to make all components clusterable and
horizontally scalable, so that you can simply add more machines to resolve most
bottlenecks.

We also tried to make Monasca as fault tolerant as possible, so that no metrics or
logs are lost, even if there are network outages.

-->

## What is Monasca? (cont.)

* Features:

  * Metrics with dimensions (key/value pairs) as metadata

  * Real-time alerting

  * Pluggable notification engine

  * Flexible aggregation engine

<!--

Let's take a look at what Monasca can do for you:

We can gather all sorts of metrics and attach arbitrary dimensions to them. The
most common one is of course the host name, but you could attach all sorts of
other dimensions to identify a particular metric. For instance a VM's libvirt
ID if you gather a particular metric for all VMs running on a host.

We have an alerting framework where you can define all sorts of thresholds on
arbitrary metrics.

This ties into the notification engine which can send notifications on any or
all channels it's got a plugin for.

Last but not least we also have an aggregation engine for turning a flood of
individual metrics into a synthetic compound metric. Anybody who has ever
worked with Grafana's aggregation functions knows why *that* is useful...

-->

## Sources of documentation

* https://docs.openstack.org/monasca-api
* https://wiki.openstack.org/wiki/Monasca
* http://monasca.io/

<!--

We have various places where we keep the documentation for Monasca:

* https://docs.openstack.org/monasca-api

* https://docs.openstack.org/monasca-log-api

* https://wiki.openstack.org/wiki/Monasca

* http://monasca.io/

The most up-to-date is usually the stuff on
[docs.openstack.org](https://docs.openstack.org) since that is generated
directly from the `monasca-api` and `monasca-log-api` repositories.

-->

## Main contributors

* Fujitsu

* HPE

* OP5

* StackHPC

* SUSE

<!--

The main contributors to Monasca are Fujitsu, HPE, OP5, StackHPC and SUSE at
the moment.

-->

# Monasca Metrics Architecture

<!--

# Architecture and Development

We will now give you a guided tour of Monasca's architecture mixed in
with a quick run-down on each component.

We will include extra information relevant to developers where applicable.

-->

## Metrics API (`monasca-api`)

![Monasca API](img/architecture1.Png)

<!--

## Monasca Metrics API

The Monasca metrics API is the central piece of Monasca.

It receives metrics from agents, makes these metrics available to clients and
is used for defining alarms and thresholds.

-->

## Metrics API (`monasca-api`)

![Configuration Database](img/architecture2.Png)

<!--

Alarm definitions, thresholds and various other things are stored in a
configuration database.

This is a plain old SQL database, usually MariaDB since OpenStack has pretty
much standardized on MariaDB. 

Various Monasca components use it for things such as alarm state or user
defined runtime state such as alarm definitions.

-->

## Metrics API (`monasca-api`)

* Repository

  * https://github.com/openstack/monasca-api

* Purpose

  * Receives metrics from agents

  * Makes metrics available for visualization/processing

  * Interface for modifying configuration database (alarms, notifications, ...)

* Development Information

  * Most important documentation repository for Monasca: source for
    https://docs.openstack.org/monasca-api

  * API reference: https://github.com/openstack/monasca-api/blob/master/docs/monasca-api-spec.md

  * Contains data model for configuration database
    (`monasca-api/monasca_api/common/repositories`)

  * Contains database migrations for configuration database (being added in
    OpenStack Rocky)

<!--

## Metrics API (`monasca-api`)

You will find the Metrics API in the
[monasca-api](https://github.com/openstack/monasca-api) repository.

The Metrics API receives metrics data from metrics agents and exposes the
metrics stored in the time series database (more on that later).

It is also the interface for modifying the configuration database.

Which is to say, if you want to define alarms or set alarm thresholds, the
Metrics API is what you talk to. This happens either directly through a Monasca
client or indirectly through the Monasca UI which uses the Monasca client in
its backend.

For developers there are a couple of interesting things in the `monasca-api`
repository:

1) It is the central documentation repository for Monasca. The things you find
   on https://docs.openstack.org/monasca-api/latest/ are generated from the
   `monasca-api` repository.

2) The repository contains full [API reference](https://github.com/openstack/monasca-api/blob/master/docs/monasca-api-spec.md)
   documentation with all important concepts explained.

3) It contains the data model for the configuration database that is used by
   various Monasca services. Whenever you add or remove tables or columns you
   will need to edit the modules in the
   `monasca-api/monasca_api/common/repositories` directory.

4) As of the OpenStack's Rocky release, `monasca-api` will contain the alembic
   migrations for changes to the configuration database. Let's look at that in
   some detail:

-->

## Creating Database Migrations

* Generate skeleton revision

```
$ include(cmd/alembic-newrevision.sh)include(output/alembic-newrevision)
```

* Edit revision

```
include(cmd/edit-revision.sh)
```

<!--

## Creating Database Migrations

If you have made changes to the data model, you will also need to create a
database migration.

These database migrations allow operators to apply your changes to an existing
database.

We use [Alembic](http://alembic.zzzcomputing.com) for this.

Run the following commands on your Devstack instance to generate a new skeleton
migration:

```
$ include(cmd/alembic-newrevision.sh)include(output/alembic-newrevision)
```

`alembic` will output the newly created revision's file name.

Add your data model changes to the `upgrade()` method in this file.

Please also add code that removes your changes to the `downgrade()` method.

Otherwise people will not be able to revert migrations later.

-->

## Metrics API (`monasca-api`)

![Configuration Database](img/architecture2.Png)

## Monasca Agent (`monasca-agent`)

![Monasca Agent](img/architecture3.Png)

<!--

## Monasca Agent (`monasca-agent`)

Another crucial component is the Monasca agent.

-->

## Monasca Agent (`monasca-agent`)

* Repository

  * https://github.com/openstack/monasca-agent

* Purpose

  * Collect metrics on monitored systems and forward them to `monasca-api`

  * Easily extendible by adding custom plugins

* Development Information

  * Check plugins (for collecting metrics) in `monasca_agent/collector/checks_d`

  * Detection plugins (for detecting/configuring checks with `monasca-setup`) in
    `monasca_setup/detection/plugins`

  * Please create both if you add a new check.

  * Detailed documentation available in README

<!--

You will find the Monasca agent in the
[monasca-agent](https://github.com/openstack/monasca-agent) repository.

The agent is the boots-on-the-ground component of Monasca: it runs on the
systems being monitored by Monasca, where it collects metrics and forwards them
to monasca-api.

Please note that it only collects metrics. For logs you need a separate agent.
The most common is
[Logstash](https://github.com/logstash-plugins/logstash-output-monasca_log_api)
with the Monasca output plugin.

Custom plugins for metrics specific to your deployment can also be easily
integrated: there are magic directories where you can simply drop them. Since
you are prospective Monasca developers we strongly suggest you contribute them
upstream, though.

Let's take a look at how plugins work (this is the same for both official and
"magic directory" plugins). There are two types of plugins:

1) Check plugins: You will find these in the `monasca_agent/collector/checks_d`
   directory. You create one of these if you want to add a new type of check to
   monasca-agent.

2) Detection plugins: You will find these in the
   `monasca_setup/detection/plugins` directory. These plugins are used by
   `monasca-setup` which automatically detects things to be monitored and
   configures `monasca-agent` accordingly.

If you add a new check plugin to the official `monasca-agent` source tree,
please also try to add a detection plugin.  Otherwise people will always have
to configure your check manually.

Please refer to the documentation in the
[monasca-agent](https://github.com/openstack/monasca-agent) repository for
information on plugin development. We have detailed instructions for both
official and "magic directory" plugins in there.

-->

## Monasca Agent (`monasca-agent`)

![Monasca Agent](img/architecture3.Png)

## Monasca Client (`python-monascaclient`)

![User and Monasca API](img/architecture4.Png)

## Monasca Client (`python-monascaclient`)

* Repository

  * https://github.com/openstack/python-monascaclient

* Purpose

  * Python client library and CLI client for the Monasca Metrics API

  * Used by users to retrieve metrics/manipulate alarms and by all components
    that communicate with the Metrics API

* Development Information

  * If you extend the Metrics API, you will have to implement the client side
    of that extension in `python-monascaclient`.

<!--

## Monasca client

You will find the Monasca client in the
[python-monascaclient](https://github.com/openstack/python-monascaclient) repository.

Just like with other OpenStack components, `python-monascaclient` contains the
client library for talking to the Monasca API, along with a command line
client.

In Monasca's case the command client is mainly useful for listing/examining
metrics and handling alarms. The client library is used by all Moasca
components that talk to the Monasca API.

It should go without saying that you will need to modify `python-monascaclient`
as well if you make changes to the Metrics API.

-->

## Monasca Client (`python-monascaclient`)

![Monasca Client](img/architecture4.Png)

## Horizon Plugin (`monasca-ui`)

![Horizon Plugin](img/architecture5.Png)

## Horizon Plugin (`monasca-ui`)

* Repository

  * https://github.com/openstack/monasca-ui

* Purpose

  * Configuration of alarms/thresholds

  * Visualizing alarms

  * Provide links to metrics and log dashboards

<!--

## Horizon Plugin (`monasca-ui`)

You will find the Horizon plugin for Monasca in the
[monasca-ui](https://github.com/openstack/monasca-ui) repository.

The Monasca Horizon plugin is fairly bare bones. Its chief purpose is
providing a friendly interface for dealing with alarms and notifications:

it allows the user to define these through a dialog based UI with sanity checks
and tooltips. It also visualizes alarms and notifications.

Its secondary purpose is providing links to Grafana and Kibana dashboards which
are used to visualize metrics and logs, respectively.

-->

## Horizon Plugin (`monasca-ui`)

![Horizon Plugin](img/architecture5.Png)

## Message Queue: Interconnects Monasca Components

* Repository

  * N/A (third party component; Apache Kafka)

* Purpose

  * Shuttle metrics, notifications and log entries back and forth between
    components

<!--

-->

## Message Queue

![Message Queue](img/architecture6.Png)

<!--

## Message Queue

For the next component we do not have a repository of our own, but since it's
part of the official architecture diagram we will mention it for completeness'
sake: much like other OpenStack serivces Monasca uses a message queue to allow
its components to communicate amongst each other.

While it is theoretically possible to use RabbitMQ for this (like other
OpenStack services), most Monasca installations out there use Kafka for
performance reasons.

The message queue is primarily used to get metrics and log entries to the
respective persister services. Beyond that, `monasca-threshold` listens in on
metrics (and triggers `monasca-notification` via the message queue if any alarm
thresholds are exceeded).

-->

## Notification Engine (`monasca-notification`)

![Notification Engine](img/architecture7.Png)

## Notification Engine (`monasca-notification`)

* Repository

  * https://github.com/openstack/monasca-notification

* Purpose

  * Sends notifications if triggered by alarm

  * Supports E-Mail, Webhooks and various chat protocols

* Development Information

  * Plugin based

  * Plugins in `monasca_notification/plugins/`

  * Plugins must inherit from `monasca_notification.plugins.abstract_notifier.AbstractNotifier`

  * Plugins must be registered in configuration file

<!--

## Notification Engine

The Notification Engine is part of Monasca once more. You will find it in the
[monasca-notification](https://github.com/openstack/monasca-notification)
repository.

As mentioned, it listens to messages from `monasca-threshold` on the the
message queue.

Once these arrive it will send notifications through various channels.
Currently we support E-Mail, IRC, Slack, and Jira among others.

Notifications are plugin based. If you have a communications channel you want
to create a plugin for, just add a plugin to the
`monasca_notification/plugins/` directory.

To use your new plugin you need to register it in the Notification Engine's
configuration file, `notification.yaml`.

-->

## Notification Engine (`monasca-notification`)

![Notification Engine](img/architecture7.Png)

## Threshold Engine (`monasca-thresh`)

![Treshold Engine](img/architecture8.Png)

## Threshold Engine (`monasca-thresh`)

* Repository

  * https://github.com/openstack/monasca-thresh

* Purpose

  * Listen in on metrics and check them against alarm thresholds

  * Produces messages for `monasca-notification` if thresholds exceeded

* Development Information

  * Implemented in Java

  * Contributions may entail changes to `monasca-common`

  * Uses Apache Storm for processing metrics

<!--

## Threshold Engine (`monasca-thresh`)

The other side of notification is taken care of by the Monasca Threshold
engine. You will find this component in the
[monasca-thresh](https://github.com/openstack/monasca-thresh) repository.

This components listens in on metrics as they rush by on the message queue and
checks whether they exceed any alarm thresholds. If they do, `monasca-thresh`
publishes an alarm to the message queue. That message is then consumed by
`monasca-notification`. At the same time the alarm will be recorded in the
Monasca database so it can be visualized in the Monasca UI.

From the development side, `monasca-thresh` is a bit of an odd duck: it's one
of the services that is entirely implemented in Java with no Python
implementation existing at the moment.

`monasca-thresh` uses some shared code from the Java part of the
`monasca-common` library, so you may have to modify `monasca-common` as well if
you contribute code to `monasca-thresh`.

Last but not least, `monasca-thresh` does not do the heavy lifting all by
itself. Instead it uses Apache Storm to process metrics.

-->

## Threshold Engine (`monasca-thresh`)

![Treshold Engine](img/architecture8.Png)

## Transform Engine (`monasca-transform`)

![Transform Engine](img/architecture9.Png)

## Transform Engine (`monasca-transform`)

* Repository

  * https://github.com/openstack/monasca-transform

* Purpose

  * Republish transformed (usually aggregated) metrics as synthetic new metrics

<!--

## Transform Engine (`monasca-transform`)

Another component in the metrics processing pipeline is `monasca-transform`.
You will find it in the
[monasca-transform](https://github.com/openstack/monasca-transform) repository.

This component takes more of an active role: it consumes metrics the Metrics
API publishes on the message queue and republishes the metrics themselves and
the resulting after performing various transformations on them.

The most common transformation is aggregating individual metrics into
bigger-picture metrics (e.g. summing up the `m1.xlarge` VMs on each compute
node and publishing that sum as a synthetic metric for each compute node).

-->

## Transform Engine (`monasca-transform`)

![Transform Engine](img/architecture9.Png)


## Persister (`monasca-persister`)

![Persister](img/architecture10.Png)

## Persister (`monasca-persister`)

* Repository

  * https://github.com/openstack/monasca-persister

* Purpose

  * Consumes metrics from message queue

  * Stores metrics in time series database

* Development Information

  * Two implementations: Java and Python

  * Contributions may entail changes to `monasca-common`

<!--

## Persister (`monasca-persister`)

`monasca-persister` is the key element in the metrics processing pipeline.
You will find it in the [monasca-persister](https://github.com/openstack/monasca-persister) repository.

When all is said and done, its job is very simple:

It consumes the metrics `monasca-api` and `monasca-transformer` publish to the
message queue and stores them in the time series database.

There are two `monasca-persister` implementations: a Python and a Java. We are
planning on deprecating the Java one but for now contributions should still
target both.

As with other components, `monasca-persister` uses shared code from
`monasca-common`, so you may have to submit changes to `monasca-common` as well
if you contribute to `monasca-persister`.

-->

## Persister (`monasca-persister`)

![Persister](img/architecture10.Png)

## Time Series Database for Measurements

![Time Series Database](img/architecture11.Png)

## Time Series Database for Measurements

* Repository

  * N/A (third party component; can be Cassandra, InfluxDB or Vertica)

* Purpose

  * Store metrics

* Development Information

  * To support a new type of time series database, you will need to add code
    to `monasca-common`, `monasca-api` and `monasca-persister`.

<!--

## Time Series Database for Measurements

Last but not least, we have the heart of Monasca metrics: the time series
database.

Again, that's a third-party application such as Cassandra, InfluxDB or Vertica.

This database is where we store our metrics data.

Since sometimes new time series databases pop up or become popular, we may have
to add support for them to Monasca. To do that we will usually have to modify

1) `monasca-common`, which contains some database code shared by all components.

2) `monasca-persister`, which writes to the time series database.

3) `monasaca-api`, which reads from the time series database.

-->

# Monasca Logging Architecture

<!--

Metrics are but one side of the equation. Monasca also takes care of logs and
we've got another architecture diagram for that. This one is a bit shorter
though.

-->

include(src/logging.md)

# Development Environment

<!--

# Development Environment

Now that we've seen both the metrics and logging architecture, we'll take a
look at the various ways to get a development environment going.

-->

## Tutorial

* Interactive Jupyter notebook

* Demonstrates main Monasca functionalities

* https://github.com/witekest/monasca-bootcamp/

<!--

## Tutorial

To give you a feel for how Monasca works from a user's perspective we have
prepared an interactive Jupyter notebook. If you have never used Monasca
before, you might want to give it a try. Otherwise you can dive right in
and build a development environment. There are various ways to set one of these
up:

-->


## Devstack Setup for Monasca

* `local.conf` for default (Python based) Monasca stack

      enable_plugin monasca-api \
            git://git.openstack.org/openstack/monasca-api

* `local.conf` setting for Java based persister

      MONASCA_PERSISTER_IMPLEMENTATION_LANG=java

<!--

## Devstack Setup for Monasca

If you already have your own way to deploy Devstack, these are the `local.conf`
settings you will need to deploy it with Monasca. It's the same as for other
OpenStack projects: just enable the `monasca-api` plugin.

One setting of interest may be `MONASCA_PERSISTER_IMPLEMENTATION_LANG` and its
analogues for other components. If you work on any components with dual
implementations in Java and Python you may need these kinds of settings.

-->

## Devstack Setup with Vagrant

      # cd monasca-api/devstack
      # vagrant up

<!--

## Devstack Setup with Vagrant

If you do not have a Devstack setup, yet, you can build one with a simple
`vagrant up` in the [monasca-api](https://github.com/openstack/monasca-api.git)
repository's `devstack/` directory.

-->

## monasca-docker

* Containerized Monasca deployed with Docker Compose

      # git clone https://github.com/monasca/monasca-docker
      # cd monasca-docker
      # docker-compose up

<!--

## monasca-docker

Last but not least you can deploy containerized Monasca with Docker Compose:

      # git clone https://github.com/monasca/monasca-docker
      # cd monasca-docker
      # docker-compose up

-->

## Running unit tests

      # cd $REPO
      # tox
      # tox -e py27,py35
      # tox -e pep8

<!--

## Running unit tests

Now for running tests...

Unit tests are pretty straightforward, same as for other OpenStack projects.
Just `cd` to the repository you modified and run tox. If you don't want to wait
too long, specify only the tests you are interested.

-->

## Running integration (tempest) tests in Devstack

* Add *monasca-tempest-plugin* to `local.conf`

      enable_plugin monasca-tempest-plugin \
        https://git.openstack.org/openstack/monasca-tempest-plugin

* Run tests

      # cd /opt/stack/tempest
      # tempest run -r monasca_tempest_tests.tests.api
      # tempest run -r monasca_tempest_tests.tests.log_api

<!--

## Running integration (tempest) tests in Devstack

Our tempest tests are also standard OpenStack fare:

Before you deploy Devstack, enable the Monasca tempest plugin in your `local.conf`:

    enable_plugin monasca-tempest-plugin https://git.openstack.org/openstack/monasca-tempest-plugin

Once you've got your Devstack instance up and running you can run them in the usual manner:

      # cd /opt/stack/tempest
      # tempest run -r monasca_tempest_tests.tests.api
      # tempest run -r monasca_tempest_tests.tests.log_api

-->

## Running tempest tests with monasca-docker

* Add section to `docker-compose.yaml`:

      tempest-tests:
        image: monasca/tempest-tests:latest
        environment:
          KEYSTONE_SERVER: "keystone"
          STAY_ALIVE_ON_FAILURE: "true"
          MONASCA_WAIT_FOR_API: "true"

* Run tests

      # docker-compose up -d tempest-tests

<!--

## Running tempest tests with monasca-docker

If you prefer Docker over DevStack, you can run tempest tests with
`monasca-docker` as well.

To that end you will need to add this little snippet to `docker-compose.yaml`

      tempest-tests:
        image: monasca/tempest-tests:latest
        environment:
          KEYSTONE_SERVER: "keystone"
          STAY_ALIVE_ON_FAILURE: "true"
          MONASCA_WAIT_FOR_API: "true"

...and launch the tempest tests with the following command:

      # docker-compose up -d tempest-tests

-->

# Become part of our community

<!--

So much for the technical part. We'd like to conclude with a few notes on the
Monasca community and our contribution process.

-->

## Why Contribute?

* "Our software comes with a `monasca-agent` / `monasca-notification' plugin

* Modular

* Customisable

* Small and friendly community

<!--

## Why Contribute?

We don't know how many of you already have your own reasons to contribute to
Monasca, but here's a few from our side:

First of all you might be interested in contributing plugins to `monasca-agent`
and/or `monasca-notification` if you are working on something that needs to be
monitored or a communication tool that we do not have a notification plugin
for.

For especially this part of Monasca is very modular and customizable. Hurdles
for entry are very low and the benefit will be mutual: you can claim Monasca
support and we get a fresh plugin.

And no matter the contribution you make, we are a small and friendly community.
You can get things done fairly quickly in Monasca.

-->

## How to contribute?

* [Contributor Guide](https://docs.openstack.org/monasca-api/latest/contributor/index.html)

* We use StoryBoard!

  * Bugs

  * Feature requests

* Specifications repository
  - [openstack/monasca-specs](http://specs.openstack.org/openstack/monasca-specs/)

<!--

## How to contribute?

First of all, we do have a contributor guide with far more information than we
could fit into this presentation, so be sure to check it out.

One notable thing about the Monasca community is that we use Storyboard for
bugs and feature requests. So please don't look for Monasca bugs on Launchpad
or file them there. We may not even notice them if you do.

You will find our specifications in the
[openstack/monasca-specs](http://specs.openstack.org/openstack/monasca-specs/).
If you think something is missing from Monasca, take a look at this repository
- somebody might be working on it already.

-->

## Work to do

* Project priorities

  - http://specs.openstack.org/openstack/monasca-specs/priorities/rocky-priorities.html

* Important Tasks and Reviews

  - https://storyboard.openstack.org/#!/board/60

<!--

## Work to do

One thing you will also find in the specifications repository is our list of
priorities for any given release, such as 
[this one for Rocky](http://specs.openstack.org/openstack/monasca-specs/priorities/rocky-priorities.html).

For an overview of what we are working on, check out our 
[storyboard page](https://storyboard.openstack.org/#!/board/60).
You will often find discussion and background on the stories we maintain there.

-->

## Where can you help?

* Reviews

* Bugfixes and Bug Reports

* Community wide goals

* Installers

* Documentation

<!--

## Where can you help?

As for things you can help with...the usual:

* Like most Openstack projects we've got a packed review pipeline, so people
  who take some of the pressure off us are always welcome.

* Then there's always bugs to fix, of course. Bug reports are welcome, too.
  There are a few `monasca-agent` plugins that don't see a lot of use but may
  nonetheless be broken. If you happen to use one of these and discover bugs
  please do report them.

* Every OpenStack release brings one or two community goals, such as the
  implementation of Oslo's policy-in-code for Queens. Implementing them is
  usually not a glamorous job but it needs to be done and often it involves a
  lot of refactoring. So we greatly appreciate help with that.

* One sore point with Monasca is installation. You have seen how many moving
  parts Monasca has - setting it up is a major undertaking. So if you have
  Ansible, Chef, Docker, Helm or Kubernetes experience, by all means lets talk.
  More ways to set up Monasca are always a good thing.

* Documentation is always a sore point. We've got a few very good pieces of
  documentation, such as the plugin development guide for `monasca-agent`, but
  we've also got some parts of Monasca where we have little to no
  documentation. If you happen to discover how one of these undocumented
  subsystems works the hard way, please consider writing down what you learned.
  We'd be happy to integrate that into our official documentation!

-->

# Questions?

# Thank You!
