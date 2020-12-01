[![Build Status](https://github.com/shinesolutions/puppet-aem-curator/workflows/CI/badge.svg)](https://github.com/shinesolutions/puppet-aem-curator/actions?query=workflow%3ACI)
[![Published Version](https://img.shields.io/puppetforge/v/shinesolutions/aem_curator.svg)](http://forge.puppet.com/shinesolutions/aem_curator)
[![Downloads Count](https://img.shields.io/puppetforge/dt/shinesolutions/aem_curator.svg)](http://forge.puppet.com/shinesolutions/aem_curator)
[![Known Vulnerabilities](https://snyk.io/test/github/shinesolutions/puppet-aem-curator/badge.svg)](https://snyk.io/test/github/shinesolutions/puppet-aem-curator)

Puppet AEM Curator
------------------

A Puppet module for installing and configuring a curated set of Adobe Experience Manager (AEM) components.

This module supports AEM installation for various versions along with a combination of Service Packs, Cumulative Fix Packs, and hotfixes. Those combinations are bundled into what this module calls [AEM Profiles](https://github.com/shinesolutions/puppet-aem-curator/blob/master/docs/aem-profiles-artifacts.md).

Other than AEM installation, it also supports some common AEM management events:
* Deployment of a single AEM package or a single Dispatcher package
* Deployment of multiple AEM packages and Dispatcher packages declared in a descriptor file
* Enable and disable CRXDE
* Promote an AEM Author Standby to AEM Author Primary
* Flush AEM Dispatcher cache
* Export a single AEM package for backup
* Export multiple AEM packages for backup, declared in a descriptor file
* Import a single backup AEM package
* List AEM packages
* AEM Upgrade automation

Puppet AEM Curator is designed to provision an AEM environment in two phases:

1. Installation of AEM
2. Configuration and running of AEM

*Phase 1: Installation of AEM*

A single AEM installation can take quite a while. Rough timing of an AEM installation
(on AWS EC2 instance type [m4.2xlarge](https://aws.amazon.com/ec2/instance-types/))
which includes variation of service packs, cumulative fix packs, and hotfixes,
can take about half an hour plus.

Due to the above, the desire is to take a machine image of this AEM installation,
so we don't have to reinstall AEM every time a new AEM environment is created.
This AEM installation can then be used across multiple environments, hence the
installation cost is only once per AEM / service pack / cumulative fix version
for a given machine image.

The installation is implemented in the following manifests:
* [install_author.pp](https://github.com/shinesolutions/puppet-aem-curator/blob/master/manifests/install_author.pp)
* [install_publish.pp](https://github.com/shinesolutions/puppet-aem-curator/blob/master/manifests/install_publish.pp)

The above manifests result in AEM being gracefully stopped in order to ensure the
correctness of the repository.

*Phase 2: Configuration and running of AEM*

The configuration and running of AEM ends up with the AEM instance being provisioned
with environment-specific details (e.g. an admin password that is unique to that
environment, a configuration file that uses the ip address of the server, etc).
The idea here is that we can stand up dozens of AEM environments without installing
AEM each and every time. It simply uses the machine image taken on step one above
(Installation of AEM).

The configuration and running are implemented in the following manifests:
* [config_author_primary.pp](https://github.com/shinesolutions/puppet-aem-curator/blob/master/manifests/config_author_primary.pp)
* [config_author_standby.pp](https://github.com/shinesolutions/puppet-aem-curator/blob/master/manifests/config_author_standby.pp)
* [config_publish.pp](https://github.com/shinesolutions/puppet-aem-curator/blob/master/manifests/config_publish.pp)

The above manifests result in AEM being configured, up and running, ready to accept
incoming requests.

Learn more about Puppet AEM Curator:

* [Installation](https://github.com/shinesolutions/puppet-aem-curator#installation)
* [Usage](https://github.com/shinesolutions/puppet-aem-curator#usage)

Puppet AEM Curator is part of [AEM OpenCloud](https://aemopencloud.io) platform but it can be used as a stand-alone.

Installation
------------

    puppet module install shinesolutions-aem_curator

Or via a Puppetfile:

    mod 'shinesolutions/aem_curator'

If you want to use the master version:

    mod 'shinesolutions/aem_curator', :git => 'https://github.com/shinesolutions/puppet-aem-curator'

Usage
-----

TODO: example class/definition calls
