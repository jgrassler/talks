# Overview

## Preliminaries: Slides and Transcript

include(src/slides.md)

# Monasca Architecture

<!--

# Monasca Architecture

First of all let's take a look at Monasca's architecture to give you an
overview of Monasca's sub projects and show you how and where they tie into 3rd
party applications such as Kafka or InfluxDB.

-->

## User...

include(src/arch0.md)

<!--

## User...

Like many stories in our profession, this one starts with a user. That user
operates a Monasca client.

![User and Monasca API](img/sample0.PNG)

-->

include(src/arch1.md)

<!--

## User and Monasca API

A client alone is not very useful, so on the other side we have the Monasca
metrics and log APIs running on the cloud's OpenStack controller or a dedicated
Monasca API node.  The user interacts with Monasca through this API.

![User and Monasca API](img/sample1.PNG)

-->

## Creating Database Migrations

* Generate skeleton revision

```
$ include(cmd/alembic-newrevision.sh)
include(output/alembic-newrevision)
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
$ include(cmd/alembic-newrevision.sh)
include(output/alembic-newrevision)
```

`alembic` will output the newly created revision's file name. Add your data
model changes to the `upgrade()` method in this file. Please also add code that
removes your changes to the `downgrade()` method.

-->
