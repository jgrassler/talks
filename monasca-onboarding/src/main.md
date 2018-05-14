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

## Monasca Metrics API

![User and Monasca API](img/architecture1.Png)

<!--

## Monasca Metrics API

-->

## Configuration Database

![User and Monasca API](img/architecture2.Png)


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

## Monasca Components

![User and Monasca API](img/architecture3.Png)

## Monasca Components

![User and Monasca API](img/architecture4.Png)

## Monasca Components

## Monasca Components

![User and Monasca API](img/architecture5.Png)

## Monasca Components

![User and Monasca API](img/architecture6.Png)

## Monasca Components

![User and Monasca API](img/architecture7.Png)

## Monasca Components

![User and Monasca API](img/architecture8.Png)

## Monasca Components

![User and Monasca API](img/architecture9.Png)

## Monasca Components

![User and Monasca API](img/architecture10.Png)

## Monasca Components

![User and Monasca API](img/architecture11.Png)
