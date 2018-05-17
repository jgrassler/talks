# Preliminaries

<!--

# Preliminaries

-->

## Slides and Transcript

include(src/slides.md)

## This Session

* What it is:

  * Primer on Monasca and its architecture

  * Overview of Monasca repositories

  * Introduction to the specifics of Monasca development

* What it is not

  * General introduction to OpenStack development

  * Refer to [Code & Documentation Contributor Guide](https://docs.openstack.org/contributors/code-and-documentation/index.html)
    for that.

## What is Monasca?

* Monitoring/Logging-as-a-Service
  - highly scalable
  - fault tolerant
  - performant
  - multi-tenant

## What is Monasca?

* Features:
  - metrics with dimensions (key/value pairs) as metadata
  - real-time alerting
  - pluggable notification engine
  - flexible aggregation engine

## Sources of documentation

* https://docs.openstack.org/monasca-api
* https://wiki.openstack.org/wiki/Monasca
* http://monasca.io/

## Main contributors

* Fujitsu
* HPE
* OP5
* StackHPC
* SUSE

## Why would you want to contribute?



# Monasca Metrics Architecture

<!--

# Architecture and Development

We will now give you a guided tour of Monasca's architecture diagram mixed in
with a quick rundown on each component. We will include extra information
relevant to developers where applicable.

-->

## Metrics API (`monasca-api`)

![Monasca API](img/architecture1.Png)

<!--

## Monasca Metrics API

The Monasca metrics API is the center piece of Monasca. It receives metrics
from agents, makes these metrics available to clients and is used for defining
alarms and thresholds.

-->

## Metrics API (`monasca-api`)

![Configuration Database](img/architecture2.Png)

<!--

Alarm definitions and thresholds and various other things are stored in a
configuration database (usually MariaDB) which is accessed by various Monasca
components. Among other things monasca-api contains the schema migrations for
this database.

-->

## Metrics API (`monasca-api`)

* Repository

  * https://github.com/openstack/monasca-api

* Purpose

  * Receives metrics from agents

  * Makes metrics available for visualization/processing

  * Interface for modifying configuration database

* Development Information

  * Most important documentation repository for Monasca: source for
    https://docs.openstack.org/monasca-api/latest/

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

It is also the interface for modifying the configuration database. Which is to
say, if you want to define alarms or set alarm thresholds the Metrics API is
what you talk to, either directly through a Monasca client or indirectly
through the Monasca UI which also talks to the Metrics API.

For developers there are a couple of interesting things in the `monasca-api`
repository:

1) It is the central documentation repository for Monasca. The things you find
   on https://docs.openstack.org/monasca-api/latest/ are generated from the
   `monasca-api` repository.

2) It contains the data model for the configuration database that is used by
   various Monasca services. Whenever you add or remove tables or columns you
   will need to edit the modules in the
   `monasca-api/monasca_api/common/repositories` directory.

3) As of the OpenStack's Rocky release, `monasca-api` will contain the alembic
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
database migration. These database migrations allow operators to apply your
changes to an existing database. We use [Alembic](http://alembic.zzzcomputing.com) for
this. Run the following commands on your Devstack instance to generate a new
skeleton migration:

```
$ include(cmd/alembic-newrevision.sh)include(output/alembic-newrevision)
```

`alembic` will output the newly created revision's file name. Add your data
model changes to the `upgrade()` method in this file. Please also add code that
removes your changes to the `downgrade()` method. Otherwise people will not be
able to revert migrations later.

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

  * Only metrics: logs are collected/forwarded by Logstash with
    [Monasca plugin](https://github.com/logstash-plugins/logstash-output-monasca_log_api)

* Development Information

  * Check plugins (for collecting metrics) in `monasca_agent/collector/checks_d`

  * Detection plugins (for detecting/configuring checks with `monasca-setup`) in
    `monasca_setup/detection/plugins`

  * Please create both if you add a new check.

<!--

You'll find the Monasca agent in the
[monasca-agent](https://github.com/openstack/monasca-agent) repository.

The agent is the boots-on-the-ground component of Monasca: it runs on the
systems being monitored by Monasca, where it collects metrics and forwards them
to monasca-api.

Please note that it only collects metrics. For logs you need a separate agent.
The most common is
[Logstash](https://github.com/logstash-plugins/logstash-output-monasca_log_api)
with the Monasca output plugin.

The most important thing to bear in mind for `monasca-agent` developers is its
plugin architecture. There are two sorts of plugins:

1) Check plugins: You will find these in the `monasca_agent/collector/checks_d`
   directory. You create one of these if you want to add a new type of check to
   monasca-agent.

2) Detection plugins: You will find these in the
   `monasca_setup/detection/plugins` directory. These plugins are used by
   `monasca-setup` which automatically detects things to be monitored and
   configures `monasca-agent` accordingly.

If you add a new check plugin, please also try to add a detection plugin.
Otherwise people will always have to configure your check manually.

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
providing a friendly interface for dealing with alarms and notifications: it
allows the user to define these through a dialog based UI with sanity checks
and tooltips. It also visualizes alarms and notifications.

Its secondary purpose is providing links to Grafana and Kibana dashboards which
are used to visualize metrics and logs, respectively.

-->

## Horizon Plugin (`monasca-ui`)

![Horizon Plugin](img/architecture5.Png)

## Message Queue: Interconnects Monasca Components

* Repository

  * N/A (third party component; usually Kafka)

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

  * Pass metrics that exceed thresholds to `monasca-notification`

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
publishes an alarm to the message queue (that message is then consumed by
`monasca-notification`). At the same time the alarm will be recorded in the
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
`monasca-common`, so you may have to submit changes to `monasca-common` as
well if you contribute to `monasca-persister`.

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

include(src/logging.md)

## Tutorial

* Interactive Jupyter playbook
* Demonstrates main Monasca functionalities
* https://github.com/witekest/monasca-bootcamp/

# Development environment

## Devstack Setup for Monasca

* `local.conf` for default (Python based) Monasca stack

      enable_plugin monasca-api \
            git://git.openstack.org/openstack/monasca-api

* `local.conf` additions for Java based Monasca stack

      MONASCA_API_IMPLEMENTATION_LANG=java

## Devstack Setup with Vagrant

      # cd monasca-api/devstack
      # vagrant up

## monasca-docker

* Containerized Monasca deployed with Docker Compose

      # git clone [...]
      # cd monasca-docker
      # docker-compose up

* https://github.com/monasca/monasca-docker

## Running unit tests

      # tox -e py27,py35

## Running integration (tempest) tests in Devstack

* add *monasca-tempest-plugin* to `local.conf`

      enable_plugin monasca-tempest-plugin \
        https://git.openstack.org/openstack/monasca-tempest-plugin

* run tests

      # cd /opt/stack/tempest
      # tempest run -r \
        monasca_tempest_tests.tests.api

      # tempest run -r \
        monasca_tempest_tests.tests.log_api

## Running tempest tests with monasca-docker

* add section to `docker-compose.yaml`:

      tempest-tests:
        image: monasca/tempest-tests:latest
        environment:
          KEYSTONE_SERVER: "keystone"
          STAY_ALIVE_ON_FAILURE: "true"
          MONASCA_WAIT_FOR_API: "true"

* run tests

      # docker-compose up -d tempest-tests

## How to contribute?

* [Contributor Guide](https://docs.openstack.org/monasca-api/latest/contributor/index.html)
* We use StoryBoard!
  - bugs
  - feature requests
* Specifications repository
  - [openstack/monasca-specs](http://specs.openstack.org/openstack/monasca-specs/)

## Work to do

* Project priorities
  - http://specs.openstack.org/openstack/monasca-specs/priorities/rocky-priorities.html
* Important Tasks and Reviews
  - https://storyboard.openstack.org/#!/board/60

## Where can you help?

* Reviews
* Bugfixes
* Community wide goals
* Installers
* Documentation

# Questions?

# Thank You
