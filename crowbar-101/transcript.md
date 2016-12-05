

Crowbar is the installation and configuration management framework we use for a
bunch of SUSE products things right now.

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

Once a barclamp is activated the default configuration from the data bag is
saved in the Crowbar database and becomes the barclamp's runtime configuration.
We refer to this runtime configuration as the barclamp's *proposal*.

Beyond this, a barclamp has the three usual model-view-controller components on
the Rails application side: The model takes care of various tasks related to
handling a proposal's data such as generating random passwords upon first
creation. The view consists of a HAML file defining form fields and a locale
file with descriptions of the form fields (at least English should be present).
There is a controller, too, but we rarely use it (for most barclamps it only
contains minimal boilerplate code).




Let's take a look at how a barclamp is parametrized now. I'll show two possible
ways. The third would involve write your own a REST client for the Crowbar API,
but let's not do that just yet and start with the first for now, which is the
Crowbar web UI.




To change a barclamp's configuration through the web UI you just navigate to
the Barclamp's page, and edit the fields in there to your Heart's content and
hit the "Apply" button. Note that this may not give you access to all settings.
Some settings may be defined in the data bag but have no UI setting, owing to
the fact that they are rarely needed and would thus needlessly clutter the UI
for must users. If you want to access these settings you can link the "Raw"
link at the top right to edit the barclamp's proposal in JSON format.




Once you hit "Save", the updated proposal gets stored in Crowbar's database.




From there the barclamp's chef cookbook is parametrized with the updated
proposal.




Eventually the clients come along and query Crowbar's chef server, running the
recipes their role recipes assign them with the parameters from the updated
proposal.




Experienced sysadmins (and developers) sometimes to get a bit grumpy when they
are forced to use a web interface for their daily work. To make them happy,
Crowbar comes with a REST API and a command line client to drive it.




The workflow for this approach to configuring Crowbar only differs at the
beginning. Namely you use the crowbar command line client to edit a barclamp's
proposal. This will give you the same JSON data structure you can access
through the Web UIs raw view.




Once you are done editing, the CLI client sends the modified proposal to
Crowbar's REST API which stores it in the database.




From here on the data flow is identical. First the chef cookbook is
parametrized with the updated proposal...




..and then the chef clients come along again and apply their recipes.




As mentioned in the beginning, Crowbar is open source. We are hosting it on
Github and you are free to submit pull requests against it. A word on the
repositories: We've got the main application in the `crowbar` repository and
groups of barclamps in `crowbar-<something`. For instance, basic system setup,
such as setting root passwords and configuring NTP is in `crowbar-core`, while
all OpenStack services are in `crowbar-openstack`. If you want to get in touch
with Crowbar developers you can use the mailing list or `#crowbar` on FreeNode.
On a more general note, you will find most of our developers on FreeNode if you
need to get in touch.




Contributions to Crowbar mostly follow the normal Github workflow. You fork the
repository you intend to modify, create a topic branch and submit a pull
request once you are happy with what you have got. The next step is making two
reviewers and our CI tests happy. The first test (Hound) is usually very quick
to run (and fail). Once you've fixed the style errors it complains about the
next major test is `mkcloud`: our CI will build a virtualized OpenStack cloud
using Crowbar packages built from your pull requests. If this passes as well
and two Crowbar developers greenlight your patch, it will get merged into
`master`. If you need your change in an older Crowbar release (SUSE OpenStack
Cloud uses `stable/3.0`, for example) you will then need to submit a second
pull request to backport it into the older release.




After this whirlwind tour of Crowbar we can delve a little deeper and take a
detailed look at all that goes into creating a new barclamp. Due to the brevity
we will omit a lot of detail, but this part should at least leave you with a
good idea of where to look for things.




To give you real life code I picked a commit we merged in the none-too-recent
past: the initial Barbican barclamp. If you look at the Git history you'll
notice additional feature additions and fixes to the Barbican barclamp, but
this commit contains all the parts a barclamp needs to work. I will use its
paths and filenames from here on out so as not to tie my tongue in knots with
an unwieldy term along the lines of <insert-your-barclamp-name-here>.

One more note: while this example is part of the `crowbar-openstack`
repository, other barclamp collections follow the same directory structure, so
this should apply to these as well.




Before you start writing a chef cookbook, it makes sense to define the
parameters, Crowbar's users should later be able to pass into your chef
cookbook. To this end you create a `template-barbican.schema` to define the
fields in your data bag and a `template-barbican.json` containing the default
configuration payload. Since both files are in JSON format and thus a bit
cumbersome to write from scratch we recommend copying and then modifying these
files from another barclamp.

One caveat for `template-barbican.schema`: this file needs to have the correct
value in its schema-revision field. This is the base schema revision for the
current Crowbar release. Right now this is 100, but with the next Crowbar
release it will get bumped by a large enough number to allow ample room for
selective backporting. Once a barclamp exists, any change to its data bag needs
to come along with two things:

* You need to increment its schema-revision by 1

* You need to add a migration for the new schema revision to
  `migrate/barbican`.




Once you know what parameters you will have available from the data bag you can
write the chef cookbook that will deploy your service. This cookbook goes into
chef/cookbooks/barbican, so as a first step create that directory.

At a bare minimum it will need a `recipes/` directory which holds chef recipes
and a `metadata.rb` which contains a barclamp description and cookbook
dependency declarations (for instance, your cookbook might depend on the
apache2 cookbook). The `recipes/` directory will need to contain at least one
role recipe to reference in the next step. Technically you could reference a
regular recipe, but that's the first step down the road to unmaintainable code,
so let's not go there.

There are plenty of other cookbooks in the `chef/cookbooks` directory, by the
way. Feel free to use these for inspiration when you write your own cookbook.




Once your chef cookbook, along with at least one role recipe is finished, you
need to make Crowbar aware of these roles. You do this by creating a role
definition for each of your roles in the `chef/roles/` directory. Again, there
are plenty of role definitions already in place for other barclamps, so feel
free to use these for inspiration.

A quick word on roles: for every barclamp you can assign one or more of its
roles to individual nodes. For instance you'd probably assign the
`nova-compute-kvm` role to a compute node and `nova-controller` to your
OpenStack cloud's controller.




Now we are almost done. All that remains is the bare minimum of UI components
and metadata for the Crowbar App required to integrate your barclamp into the
Crowbar Rails application.

First of all, we'll need the file barbican.yml which contains metadata that
describes the Barbican Barclamp from the Rails application's point of view.
Also, we create the stub executable `crowbar_barbican` in the `bin/` directory.
In both cases you can use the corresponding files from other barclamps for
inspiration.

Now we'll create the MVC parts of the barclamp, starting with the controller.
As I mentioned, we rarely do anything in the controllers so you probably won't
either. Just copy one of the stub controllers, such as NovaController.rb and
modify it.

Next you'll need to create an UI model. That one is a bit more involved since
we usually have a fair amount of logic in there, and so might you. Just have a
look at the other controllers in `app/models` to get a feel for what your model
might need.

Now only the UI view and labels are missing. If you want to have form fields
for your parameters this will be a bit of work. Otherwise just adapt the files
from the Barbican barclamp to get a UI view that does nothing apart from
deployment control buttons and an edit link for the raw view.


