## Preliminaries: Slides and Transcript

include(src/slides.md)

## This Session

* What it is:

  * Primer on Monasca architecture

  * Overview of Monasca repositories

  * Introduction to the specifics of Monasca development

* What it is not

  * General introduction to OpenStack development

  * Refer to [Code & Documentation Contributor Guide](https://docs.openstack.org/contributors/code-and-documentation/index.html)
    for that.

# Monasca Architecture

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

  * Central documentation repository for Monasca

  * Contains data model for configuration database

  * Contains database migrations for configuration database (being added in
    Rocky)

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

## Monasca Agent (`monasca-agent`)

![User and Monasca API](img/architecture3.Png)

## Monasca Agent (`monasca-agent`)

* Repository

  * https://github.com/openstack/monasca-agent

* Purpose

  * Collect metrics on monitored systems and forward them to `monasca-api`

* Development Information

  * Check plugins (for collecting metrics) in `monasca_agent/collector/checks_d`

  * Setup plugins (for detecting/configuring checks with `monasca-setup`) in
    `monasca_setup/detection/plugins`

  * Please create both if you add a new check.

## Monasca Client (`python-monascaclient`)

![User and Monasca API](img/architecture4.Png)

## Monasca Client (`python-monascaclient`)

* Repository

  * https://github.com/openstack/python-monascaclient

* Purpose

  * Python client library and CLI client for the Monasca Metrics API

  * Used by users to retrieve metrics/manipulate alarms and by all components
    that communicate with the Metrics API

## Horizon plugin (`monasca-ui`)

![User and Monasca API](img/architecture5.Png)

## Horizon plugin (`monasca-ui`)

* Repository

  * https://github.com/openstack/monasca-ui

* Purpose

  * Configuration of alarms/thresholds

  * Visualizing alarms

  * Provide links to metrics and log dashboards

* Development Information

## Message Queue: Interconnects Monasca Components

* Repository

  * N/A (third party component; usually Kafka)

* Purpose

  * Shuttle metrics, notifications and log entries back and forth between
    components

## Message Queue

![Message Queue](img/architecture6.Png)

## Notification Engine (`monasca-notification`)

![Notification Engine](img/architecture7.Png)

## Notification Engine (`monasca-notification`)

* Repository

  * https://github.com/openstack/monasca-notification

* Purpose

  * Sends notifications if triggered by alarm

  * Supports E-Mail, Webhooks and various chat protocols

## Threshold Engine (`monasca-thresh`)

![Treshold Engine](img/architecture8.Png)

## Threshold Engine (`monasca-thresh`)

* Repository

  * https://github.com/openstack/monasca-thresh

* Purpose

  * Listen in on metrics and check them against alarm thresholds

  * Pass metrics that exceed thresholds to `monasca-notification`

* Development Information

## Transform Engine (`monasca-transform`)

![Transform Engine](img/architecture9.Png)

## Transform Engine (`monasca-transform`)

* Repository

  * https://github.com/openstack/monasca-transform

* Purpose

  * Republish transformed (usually aggregated) metrics as synthetic new metrics

* Development Information

## Persister (`monasca-persister`)

![Persister](img/architecture10.Png)

## Persister (`monasca-persister`)

* Repository

  * https://github.com/openstack/monasca-persister

* Purpose

  * Consumes metrics from message queue

  * Stores metrics in time series database

* Development Information

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
