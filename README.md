[![Build Status](https://github.com/shinesolutions/puppet-aem-curator/workflows/CI/badge.svg)](https://github.com/shinesolutions/puppet-aem-curator/actions?query=workflow%3ACI)
[![Published Version](https://img.shields.io/puppetforge/v/shinesolutions/aem_curator.svg)](http://forge.puppet.com/shinesolutions/aem_curator)
[![Downloads Count](https://img.shields.io/puppetforge/dt/shinesolutions/aem_curator.svg)](http://forge.puppet.com/shinesolutions/aem_curator)
[![Known Vulnerabilities](https://snyk.io/test/github/shinesolutions/puppet-aem-curator/badge.svg)](https://snyk.io/test/github/shinesolutions/puppet-aem-curator)

# shinesolutions-aem_curator

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

## Phase 1: Installation of AEM

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

## Phase 2: Configuration and running of AEM

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

Puppet AEM Curator is part of [AEM OpenCloud](https://aemopencloud.io) platform but it can be used as a stand-alone.

Learn more about this module:

* [Installation](#installation)
* [Usage](#usage)
* [Testing](#testing)
* [Versions History](#versions-history)

## Installation

Requirements:

* OpenVox 9 (Puppet >= 9.0.0 < 10.0.0): the shinesolutions/aem_resources types
  need ruby_aem 4, which needs the Ruby 4 that only OpenVox 9 agents ship
* Amazon Linux 2023 or Rocky Linux 10
* The Puppet modules listed in `metadata.json`, installed automatically as dependencies.
  bstopp/aem is no longer required: the parts this module used are ported into
  aem_curator (`aem_curator::aem_instance`, `aem_curator::aem_service`) and
  aem_resources, see [NOTICE](NOTICE)

Install the module using the `puppet` command:

    puppet module install shinesolutions-aem_curator

Or via a Puppetfile:

    mod 'shinesolutions/aem_curator'

If you want to use the master version:

    mod 'shinesolutions/aem_curator', :git => 'https://github.com/shinesolutions/puppet-aem-curator'

## Usage

The module's classes and defined types, and their parameters, are documented in
the comments in each manifest file. HTML documentation can be generated into the
`docs/` folder with `make docs`.

The parameters available to Dispatcher EPP templates are described in
[Dispatcher Template Parameters](docs/dispatcher-template-parameters.md).

### AEM service

`aem_curator::aem_service` (declared by `aem_curator::aem_instance`) manages AEM
as the systemd service `aem-<aem_id>` with the unit
`/lib/systemd/system/aem-<aem_id>.service`, on both Amazon Linux 2023 and Rocky
Linux 10. The SysV init script that bstopp/aem used on Amazon Linux is no longer
supported. The service name is unchanged, so `systemctl` and
`puppet resource service aem-<aem_id>` work as before.

**Stop timeout:** the unit sets `TimeoutStopSec=4min`. If a graceful stop takes
longer than 4 minutes, for example while AEM finishes an offline compaction or a
backup, systemd kills AEM. The old init script on Amazon Linux waited without a
limit. To change it, pass `service_options` to `aem_curator::aem_instance` or
`aem_curator::aem_service` (the default is
`{ 'TimeoutStopSec' => '4min', 'KillSignal' => 'SIGCONT', 'PrivateTmp' => true }`).

### InSpec AEM profile

`make deps` vendors [inspec-aem](https://github.com/shinesolutions/inspec-aem)
2.0.0, declared in `inspec.yml`, into `files/test/inspec/inspec-aem`. The
aem-tools scripts run its controls with `inspec exec` on the AEM hosts, which
need Ruby 4 with ruby_aem 4.0.2 and Cinc InSpec 7.2.1.

## Testing

Run the commands below in
[aem-platform-buildenv](https://github.com/shinesolutions/aem-platform-buildenv),
as CI does. Install the Ruby gems and the InSpec AEM profile first:

    make deps

| Command | Runs |
| --- | --- |
| `make test` | Lint, syntax and `metadata.json` checks, unit specs and static checks |
| `make lint` | Puppet lint, syntax, `metadata.json` lint, RuboCop, yamllint and markdownlint only |
| `make acceptance` | Acceptance tests with Beaker on every nodeset in `spec/acceptance/nodesets` (Amazon Linux 2023 and Rocky Linux 10), in Docker containers |
| `make ci` | Everything CI runs: deps, unit and acceptance tests, and packaging |
| `make docs` | Generate the HTML reference into `docs/` |

The unit and acceptance tests only cover the classes and defined types that
apply with their default parameters. Installing, configuring and running AEM
needs AEM artifacts, a license and environment-specific parameters.

## Versions History

See [CHANGELOG.md](CHANGELOG.md) for the changes in each version.

Releases are published to the [Puppet Forge](https://forge.puppet.com/modules/shinesolutions/aem_curator)
and tagged `<version>` in git. Between releases, `metadata.json` holds the next
pre-release version, e.g. `4.1.10-pre.0`. To release:

1. Check that the `## [Unreleased]` entries in CHANGELOG.md on `main` describe
   everything in this release.
2. In GitHub Actions, run the **Release Major**, **Release Minor** or **Release
   Patch** workflow. It uses [RTK](https://github.com/cliffano/rtk), configured
   in `.rtk.json`, to set the release version in `metadata.json` and CHANGELOG.md,
   commit and tag it `<version>`, commit the next pre-release version, and push
   the commits and the tag. To do the same locally, run `make release` in
   aem-platform-buildenv, then push the commits and the tag.
3. The pushed tag triggers the **Publish Puppet Module** workflow, which builds
   the module and runs `make publish`: `make publish-check` checks the module is
   ready, then the package is pushed to the Forge. Publishing needs a Forge API
   key in `BLACKSMITH_FORGE_API_KEY`.
