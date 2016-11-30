# Introduction

## Crowbar Overview

* Open Source installation and configuration management framework 

* Originally started by Dell, continued by SUSE

* Mainly used for SUSE OpenStack Cloud, Ceph, Cloud Foundry

* Configured through Ruby on Rails Web UI and REST API with command line
  clients

<!--

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

-->

## Features

* PXE boot discovery and installation for bare metal nodes

* Easily extensible through *bar clamps*, one per OpenStack component

* Chef based configuration management for all supported services

* Pick and chose from the barclamps you actually need

<!--

Let's have a look at Crowbar's features.

First of all, it can deal with mostly unprepared bare metal machines. All they
need to do is attempt to PXE boot. Crowbar will then automatically discover
them and display the machines that successfully booted in its Nodes view. You
can then assign names to these nodes, install an operating system on them and
apply barclamps to them.

Speaking of which: barclamps are the bread and butter of crowbar. A barclamp
is a plugin for configuring a service, such as OpenStack Nova. Note that a
service in this case can be - and usually is - a distributed system of multiple
different daemons running on multiple different machines.

-->

## Barclamps: Crowbar's Configuration Modules

* Chef recipes for configuration management

* Default parameters for chef recipes from *data bags*: JSON data with schema

* Barclamp view in Crowbar Web UI for customizing parameters

* Validation code and UI elements in Rails application

## Web UI workflow (1)

![params1](img/ui1.PNG)

## Web UI workflow (2)

![params1](img/ui2.PNG)

## Web UI workflow (3)

![params1](img/ui3.PNG)

## Web UI workflow (4)

![params1](img/ui4.PNG)

## Web UI workflow (5)

![params1](img/ui5.PNG)

## CLI/REST API workflow (1)

![params1](img/cli1.PNG)

## CLI/REST API workflow (2)

![params1](img/cli2.PNG)

## CLI/REST API workflow (3)

![params1](img/cli3.PNG)

## CLI/REST API workflow (4)

![params1](img/cli4.PNG)

## CLI/REST API workflow (5)

![params1](img/cli5.PNG)

## Development: Crowbar Repositories

* Main application: https://github.com/crowbar

* Core barclamps: https://github.com/crowbar-core

* OpenStack barclamps: https://github.com/crowbar/crowbar-openstack

## Development: Contribution workflow

* Fork the repository you intend to contribute to on Github and create a topic
  branch

* Once you are done with your modifications submit a pull request

* Acceptance Criteria:

  * Two positive reviews

  * All CI tests pass

## Development: Getting in Touch

* Mailing list: `crowbar@googlegroups.com`

* IRC: `#crowbar` on FreeNode

# Case Study: Creating a New OpenStack Barclamp

## Example Barclamp: Barbican

* Example for case study: (The Barbican barclamp)

* See commit `cc1fea37169a4769257e0894f4363eccd241187a` for details

* Preparation: Fork https://github.com/crowbar/crowbar-openstack and create
  topic branch

## Step 1: Creating a Chef Cookbok

*Note: all paths on this slide are relative to `chef/cookbooks/barbican`*

* Create Chef recipes in `recipes/` 

  * Create 1 or more role recipes to aggregate recipes

* Declare dependencies in metadata.rb

## Step 2: Parameters in Data Bags

*Note: all paths on this slide are relative to `chef/data_bags/`*

* Create `template-barbican.schema`: JSON formatted schema. Describes parameter types.

* Create `template-barbican.json`: JSON formatted data structure with default paramaters

## Step 3: Roles

* Available role recipes need to be know Crowbar App

* Add a role definition for each role recipe in `chef/roles/`.

## Step 4: Register Barclamp in the Crowbar App

*Note: all paths on this slide are relative to `crowbar_framework/`*

Minimal changes:

* Create UI controller: `app/controllers/barbican_controller.rb`

* Create UI model: `app/models/barbican_service.rb`

* Create UI view: `app/views/barclamp/barbican/_edit_attributes.html.haml`

* Create UI labels: `config/locales/barbican/en.yml`
