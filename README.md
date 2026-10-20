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

Puppet AEM Curator is designed to provision an AEM environment in two phases,
described under [Usage](#usage):

1. Installation of AEM
2. Configuration and running of AEM

Puppet AEM Curator is part of [AEM OpenCloud](https://aemopencloud.io) platform but it can be used as a stand-alone.

Learn more about this module:

* [Installation](#installation)
* [Usage](#usage)
* [Result Model](#result-model)
* [Error Handling](#error-handling)
* [Testing](#testing)
* [Versions History](#versions-history)

## Installation

Requirements:

* OpenVox 9 (Puppet >= 9.0.0 < 10.0.0): the shinesolutions/aem_resources types
  need ruby_aem 4, which needs the Ruby 4 that only OpenVox 9 agents ship
* Amazon Linux 2023 or Rocky Linux 10
* The Puppet modules listed in `metadata.json`, installed automatically as dependencies.
  bstopp/aem is no longer required: the parts this module used are ported into
  aem_curator (`aem_curator::aem_instance`, `aem_curator::aem_package`,
  `aem_curator::aem_service` and the `aem_curator_installer` type) and
  aem_resources, from bstopp/aem 3.0.0 (Apache-2.0, Copyright (C) 2015-2016
  Bryan Stopp), see [NOTICE](NOTICE)

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

### Phase 1: Installation of AEM

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

### Phase 2: Configuration and running of AEM

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

### Dispatcher and legacy facts

`aem_curator::install_dispatcher` uses adobeinc/dispatcher 1.0.0, which reads the
legacy fact `$::osfamily`. OpenVox 9 doesn't provide legacy facts by default, so
run Puppet with `include_legacy_facts = true` in `puppet.conf` or with
`puppet apply --include_legacy_facts` when it applies `install_dispatcher`, until
that module is replaced. Otherwise the catalog fails with "Unknown variable".

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

## Result Model

Applying `aem_curator::install_author` or `aem_curator::install_publish` (through
`aem_curator::install_aem` and the AEM profile's `install_aem62`/`63`/`64`/`65`)
results in:

| Resource | Result |
| --- | --- |
| AEM directories | `<aem_base>/aem` and `<aem_base>/aem/<aem_id>`, owned by `aem-<aem_id>` |
| System user and group | `aem-<aem_id>` |
| License and quickstart jar | `license.properties` (mode `0440`) and `aem-<aem_id>-<aem_port>.jar`, downloaded from `aem_license_base` and `aem_artifacts_base` |
| AEM Health Check package | Downloaded to `<tmp_dir>/<aem_id>` and copied into `crx-quickstart/install`, which AEM installs when it starts |
| AEM installation | The jar unpacked into `<aem_base>/aem/<aem_id>/crx-quickstart`, with the `start` and `start-env` scripts written by `aem_resources::instance_config` |
| systemd unit | `/lib/systemd/system/aem-<aem_id>.service`, see [AEM service](#aem-service) |
| Repository | Created by starting AEM once and waiting until it answers on `http://localhost:<aem_port>/` (`aem_curator_installer`) |
| Puppet AEM Resources config | Written into `/etc/puppetlabs/puppet/` for the aem_resources types |
| Service | `aem-<aem_id>` started (not enabled at boot) for the AEM profile and configuration steps, then stopped with `systemctl stop` |

With `setup_repository_volume`, the AEM directory is moved to an ext4 volume
created on `data_volume_device`, mounted on `data_volume_mount_point` and linked
back to `<aem_base>/aem/<aem_id>`.

Applying `aem_curator::config_author_primary`, `aem_curator::config_author_standby`
or `aem_curator::config_publish` results in AEM configured with the
environment-specific details and running, see
[Phase 2](#phase-2-configuration-and-running-of-aem).

The `aem_curator::action_*` classes each run one AEM management action with the
aem_resources types. Their parameters default to the caller's top-scope variables
(e.g. `FACTER_aem_id`) through `getvar('::name')`, which gives `undef` when the
variable isn't set.

## Error Handling

The Puppet run fails when:

* A class or defined type is declared without one of its mandatory parameters.
* A parameter of `aem_curator::aem_instance` has an unsupported value: `ensure`
  (`present`, `absent`), `status` (`enabled`, `disabled`, `running`,
  `unmanaged`), `type` (`author`, `publish`, `standby`), `version`, the port
  numbers, or a `home` or `source` that isn't an absolute path.
* The license, quickstart jar or AEM Health Check package can't be downloaded.
* AEM doesn't answer on `http://localhost:<aem_port>/` within `timeout` (600
  seconds by default) after `aem_curator_installer` starts it.
* The AEM login page isn't ready, or the AEM health check isn't OK, within the
  retries of the `aem_aem` resources (e.g. 120 tries, 5 seconds apart, for the
  login page after installation).
* `aem_curator::install_dispatcher` is applied without legacy facts, see
  [Dispatcher and legacy facts](#dispatcher-and-legacy-facts).

What isn't checked:

* `aem_curator::aem_package` only unpacks the quickstart jar when `java` is on
  the `PATH` and the jar exists. Otherwise it skips the unpack without an error,
  and the run fails later on the AEM files the unpack creates.
* `aem_curator_installer` only checks that AEM answers with a success, redirect
  or `401` response; it doesn't check the bundles or packages.
* The `aem_curator::action_*` classes don't check that the top-scope variables
  they read are set; an unset one is `undef`.
* systemd kills AEM when a graceful stop takes longer than `TimeoutStopSec`
  (4 minutes by default), see [AEM service](#aem-service).

## Testing

Run the commands below in
[aem-platform-buildenv](https://github.com/shinesolutions/aem-platform-buildenv)
(`shinesolutions/aem-platform-buildenv:6.4.1`, the image the CI and publish
workflows use), as CI does. Install the Ruby gems and the InSpec AEM profile first:

    make deps

| Command | Runs |
| --- | --- |
| `make test` | Lint, syntax and `metadata.json` checks, unit specs and static checks |
| `make lint` | Puppet lint, syntax, `metadata.json` lint, RuboCop, yamllint on every YAML file, markdownlint on every hand-written Markdown file and the `.rtk.json` check only |
| `make acceptance` | Acceptance tests with Beaker on every nodeset in `spec/acceptance/nodesets` (Amazon Linux 2023 and Rocky Linux 10), in Docker containers |
| `make ci` | Everything CI runs, cheapest first: deps, RuboCop, yamllint, markdownlint and the `.rtk.json` check, `make test`, acceptance tests and packaging |
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
