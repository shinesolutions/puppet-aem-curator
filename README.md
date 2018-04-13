[![Build Status](https://img.shields.io/travis/shinesolutions/puppet-aem-curator.svg)](http://travis-ci.org/shinesolutions/puppet-aem-curator)
[![Published Version](https://img.shields.io/puppetforge/v/shinesolutions/aem_curator.svg)](http://forge.puppet.com/shinesolutions/aem_curator)
[![Downloads Count](https://img.shields.io/puppetforge/dt/shinesolutions/aem_curator.svg)](http://forge.puppet.com/shinesolutions/aem_curator)

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

Install
-------

    puppet module install shinesolutions-aem_curator

Or via a Puppetfile:

    mod 'shinesolutions/aem_curator'

If you want to use the master version:

    mod 'shinesolutions/aem_curator', :git => 'https://github.com/shinesolutions/puppet-aem-curator'

Usage
-----

TODO
