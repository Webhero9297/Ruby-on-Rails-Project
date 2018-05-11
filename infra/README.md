Intervac infrastructure
=======================

This directory holds intervac infrastructure files. The main idea,
that is far to be completed, is to use immutable infrastructure and
have the ability to destroy and create servers easyly.

Contents
--------

This directory contains:

`Vagrantfile`: an easy way to provision a virtual machine locally in
order to try the Ansible file.

`Dockerfile` was used to understand what we would need to do to make the
application to work on Ubuntu 16.04. In its current state we can provision the
whole Intervac application under ruby 2.2 and Ubuntu Xenial.

Automation
----------

Intervac is using [Ansible](https://github.com/ansible/ansible) for
server creation and automation. There is a script called `run` to
execute the automation for a given environment. It is a simple script,
read it for more information.

All the rules needed to provision a new server are available on
`intervac.yml` file.

### Steps to build a new server

Here are the steps needed to build a new server.

First of all, create a new server based on the latest version of
Ubuntu. From here you can run Ansible as root, for the first installation.

Just be aware to change the `run` script to not ask for password and
use the root user on port 22.

The run script will create a new user called `sysop` and open port
**4195**. Now you cna use `run` script as is.

After executing the `run` script, the server should be ready for the
application. To make it work, you have to create the appropriate
deploy file in `config/deploy` directory and `cap ENVIRONMENT deploy`
it.

Now you have the server and application deployed and just need to do
the adjustments to make the application work. Configure `mongoid.yml`
and `database.yml` to point the the correct places and everything
should be up and running.

Backups
-------

Currently, our backup is not automated. We're using Dropbox to keep
the daily database backup while we are planning to use a service for
our MongoDB.

There is a script file called `dropbox.py` in the $HOME directory of
_intervac_ user. This script is responsible for dealing with the
Dropbox package (downloaded from Dropbox website and installed
manually).

To get the Dropdox daemon up and running:

    $HOME/dropbox.py start

It is configured to autostart with the server, the script can
configure the daemon to do that as well.

Ask the Intervac webmaster about the user and password for the Dropbox
account.
