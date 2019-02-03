# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.9.1] - 2019-02-03

## Changed
- Add parameter to force removal of the AEM Global Truststore for reconfiguration & truststore migration
- Add credentials to last aem_health_check

## Added
- Add AEM Package Manager readiness check for reconfiguration
- Add new feature to remove AEM Global truststore during reconfiguration

### Fixed
- Fix aem62_sp1_cfp18 package_version property

## [1.9.0] - 2019-02-03

### Added
- Add new check for AEM Package Manager readiness shinesolutions/aem-aws-stack-builder#214

## [1.8.0] - 2019-02-03

### Added
- Add new AEM profile: aem62_sp1_cfp18
- Upgrade aem_resources to 3.6.0

## [1.7.0] - 2019-01-28

### Added
- Add new AEM profile: aem64_sp3
- Add post start sleep timer to give the AEM service more time to start before configuring AEM shinesolutions/aem-aws-stack-builder#214

## [1.6.0] - 2019-01-23

### Added
- Add `aem_license_base` variable which specifies the location of the license file

## [1.5.0] - 2019-01-08

### Added
- New manifest for configuring AEM Bundles
- New bundle configuration for Apache HTTP Components Proxy Configuration shinesolutions/aem-aws-stack-builder#235
- Add feature for AEM Global Truststore migration shinesolutions/aem-aws-stack-builder#229

### Changed
- Upgrade aem_resources to 3.5.0
- Improved provisioning process for Author & Publish shinesolutions/aem-aws-stack-builder#214

### Removed

## [1.4.0] - 2018-12-17

### Added
- Add feature for automating AEM Upgrade
- Add new AEM profile: aem65

### Changed
- Fixed logic error in config_saml manifest
- Upgrade aem_resources to 3.4.0

## [1.3.0] - 2018-11-25

### Added
- Add feature to configure SAML
- Add feature to configure AEM Trusttore
- Add feature to configure AEM Authorizable Keystore
- Add feature to manage AEM Truststore certificates
- Add feature to manage AEM Authorizable Keystore certificates
- Add action manifests for enabling/disabling SAML

## [1.2.4] - 2018-11-05

### Added
- Add Amazon Linux 2 to supported OS list in Puppet metadata

### Changed
- Fix parameters for "Wait until login page is ready" to consume parameters from aem-aws-stack-provisioner for all checks #76

## [1.2.3] - 2018-10-19

### Added
- Add wait until AEM Author Standby port is listening #75
- Add Puppet resource stopped status check for AEM services at the end of installation

### Changed
- Change default JMX ports to 5982 for AEM Author and 5983 for AEM Publish
- Disable collectd repo management to avoid any outbound connection #71
- Upgrade aem_resources to 3.2.1

## [1.2.2] - 2018-10-05

### Removed
- Remove collectd installation due to collectd provisioning already exists on Packer AEM #71

## [1.2.1] - 2018-10-05

### Added
- Add parameter to enable/disable installation of collectd #68
- Add step to install collectd after installation of AEM for Author & Publish #71

### Changed
- Upgrade InSpec to 2.3.10 with new vendoring structure #60

## [1.2.0] - 2018-10-05

### Added
- Add additional checks during configuring AEM Author & AEM Publisher #63
- Add parameter deployment_sleep_seconds for resource deploy_packages
- Add feature to delete old bak files from the repository during offline-compaction
- Add install AEM profile action
- Introduce pdk as Puppet module build
- Add new AEM profile: aem64_sp2

### Changed
- Updated parameters for "Wait until login page is ready" to consume parameters from aem-aws-stack-provisioner
- Lock inspec version to 2.2.78 #60
- Simplify AEM profile installation logic #7
- Drop Puppet 4 support, add Puppet 6 support
- Upgrade aem_resources to 3.2.0

### Removed
- Remove support for Ruby 2.1 & 2.2 due to dependency issues

## [1.1.2] - 2018-08-09

### Changed
- Upgrade aem_resources to 3.1.1 for aem_user_alias support

## [1.1.1] - 2018-08-08

### Changed
- Fix pre-6.4 incorrect config path for AEM Password Reset and AEM Health Check

## [1.1.0] - 2018-08-02

### Added
- Add support for reconfiguring existing AEM installations
- Add feature to change existing system users passwords

### Changed
- Place AEM Healthcheck installation to own manifest
- Place AEM Configuration to own manifest
- Improved credentials handling for system users

## [1.0.3] - 2018-07-23

### Changed
- Fix temp directory clean up at the end of artifacts deployment

## [1.0.2] - 2018-07-17

### Changed
- Set repository ownership when configuring AEM Author Primary, Author Standby, and Publish

## [1.0.1] - 2018-07-11

### Added
- Add 1.x.x AEM profiles: aem62_sp1_cfp15, aem63_sp2_cfp2, aem64_sp1

## [1.0.0] - 2018-06-25

### Changed
- Modify config path to /apps/system/config for AEM 6.4 support

## [0.9.9] - 2018-01-07

### Added
- Add multi AEM instances support to offline compaction and enable CRXDE

### Changed
- Parameterise all references to AWS S3
- Extract deployment support to config_aem_deployer manifest

### Removed
- Migrate all AEM Tools files and templates from aem-aws-stack-provisioner to aem_curator
- Migrate AWS-related scripts from aem_curator to aem-aws-stack-provisioner

## [0.9.8] - 2018-01-03

### Changed
- Localise global facts aem_password_reset_version, oak_run_version

## [0.9.7] - 2017-12-29

### Added
- Add config_author_dispatcher class
- Add config_author_standby class

### Removed
- Remove publish_dispatcher_allowed_client, pairinstanceid, and publishdispatcherhost global facts

## [0.9.6] - 2017-12-20

### Added
- Add readiness checks during installation and configuration of AEM Dispatcher
- Added variable jvm_mem_opts to configure JVM Memory for AEM Author and Publisher

## [0.9.5] - 2017-12-11

### Changed
- config_publish_dispatcher no longer deploys artifacts (moved to aem-aws-stack-provisioner) due to AWS-specific check
- Fix Dispatcher artifacts descriptor generator script name

## [0.9.4] - 2017-12-04

### Added
- Add enable_default_password flag for creating system users password with default value (i.e. same as username)
- Add enable_crxde flag for enabling CRXDE access

## [0.9.30] - 2018-05-18

### Added
- Add retries setting for deploying a single artifact #28

## [0.9.3] - 2017-11-27

### Added
- Add new AEM profiles: aem62_sp1_cfp2, aem62_sp1_cfp9, aem63_sp1

### Changed
- Rename jvm_opts param to aem_jvm_opts

## [0.9.29] - 2018-05-10

### Added
- Add AEM start opts support to AEM instance installation

### Changed
- Backup import no longer fails when the package already exists

## [0.9.28] - 2018-05-04

### Changed
- Extract all scheduled jobs provisioning to config_aem_scheduled_jobs
- Fix missing Puppet exit code translation on all aem-tools

### Removed
- Move snapshot attachment step to aem-aws-stack-provisioner

## [0.9.27] - 2018-04-25

### Changed
- Fix path conflict on flush dispatcher cache action

## [0.9.26] - 2018-04-24

### Added
- Add timeout setting to author and publish configuration manifests

### Changed
- Modify flush dispatcher cache action to remove only JCR sub-directories under docroot

## [0.9.25] - 2018-04-23

### Added
- Add parameter allowing additional java opts settings for author and publish

### Changed
- Clean up temp directory at the end of deploy artifacts

## [0.9.24] - 2018-04-20

### Changed
- Fix parameter passing on deploy artifact and export backups

## [0.9.23] - 2018-04-19

### Added
- Add log_dir parameter to deploy artifact templates processing
- Add list packages support to aem-tools

## [0.9.22] - 2018-04-16

### Changed
- Fix incorrect match regex for Collectd CloudWatch config #25

## [0.9.21] - 2018-04-13

### Added
- Add new AEM profile: aem64

### Changed
- Set retry settings to AEM package deployment actions #28

### Removed
- Move stack prefix and component details as a constant value dimension for Collectd CloudWatch config #25

## [0.9.20] - 2018-04-11

### Added
- Add aem_id parameter to actions with on-demand AEM target

## [0.9.2] - 2017-11-13

### Added
- Introduce AEM profile concept which defines AEM base installation along with extra packages (hotfixes, service packs, cumulative fix packs)
- Add aem63 profile for vanilla AEM 6.3 base installation

### Changed
- AEM and license files now have predetermined names, consistent with extra packages

## [0.9.19] - 2018-04-10

### Added
- Add InSpec testing for aem-tools actions

### Changed
- Fix injection of aem_username & aem_password to action manifests #26
- Fix incorrect artifact name for aem63_sp1_cfp13

### Removed
- Move export backup and import backup scripts provisioning to aem-aws-stack-provisioner
- Move AEM Author standby promotion instance rename to aem-aws-stack-provisioner

## [0.9.18] - unknown

### Changed
- Allow default aem_id via Hiera configuration for action manifests

## [0.9.17] - 2018-03-26

### Added
- Add new AEM profile: aem63_sp1_cfp13 #21
- Add ssl_cert parameter to dispatcher templates

### Removed
- Move aem_resources-generated virtual hosts config to virtual hosts directory

## [0.9.16] - 2018-03-20

### Added
- Add complete dispatcher template parameters to all dispatcher template processing #19

## [0.9.15] - 2018-03-15

### Removed
- Move AEM Tools directory ensure to aem-aws-stack-provisioner
- Remove flush dispatcher cache script from config_aem_tools

## [0.9.14] - 2018-03-08

### Added
- Add new manifest for Dispatcher aem-tools
- Add new aem-tool flush-dispatcher-cache

## [0.9.13] - 2018-02-27

### Added
- Add integrated export-package,export-packages and import-packages from aem-aws-stack-provisioner to aem-curator

### Changed
- Fix incorrect manifest for deploy-artifact aem-tools script

## [0.9.12] - 2018-02-01

### Added
- Add multi AEM instances support to collectd config
- Add Author Standby component bean whitelisting

### Changed
- Fix aem63_sp1_cfp2 artifact file name and package name #6

## [0.9.11] - 2018-01-30

### Added
- Add new AEM profile: aem63_sp1_cfp2 #6
- Add aem_version to Author Standby and Author Primary OSGI configuration

## [0.9.10] - 2018-01-29

### Added
- Add feature enable jmxremote at AEM Author and Publish java instances
- Add disable-crxde to aem-tools

### Changed
- Configure CloudWatch collectd plugin's proxy support only if proxy fact is set
- Drop Ruby 2.0 support

### Removed
- Migrate artifacts deployment tools from aem-aws-stack-provisioner to aem_curator

## [0.9.1] - 2017-11-10

### Added
- Add dependencies to metadata

## [0.9.0] - 2017-11-08

### Added
- Initial version
- Add multi AEM instances support at manifests level by replacing classes with definitions and by introducing aem_id attributes
- Introduce vanilla AEM 6.2 option without hotfix, service pack, and cumulative fix pack packages

### Changed
- config_publish_dispatcher: Publisher Host definitions replaced: $publish_host class variable replaced $::publishhost
- config_publish: Flush agent definitions replaced: $publishdispatcherhost, $pairinstanceid class variable replaced $::publishdispatcherhost, $::pairinstanceid
- Each AEM installation has its own user and group named aem-<aem_id>

### Removed
- Move AEM Tools into its own manifest config_aem_tools.pp
- Migrate AEM installation manifests from packer-aem
- Move collectd into its own manifest config_collectd.pp

## [0.10.2] - 2018-06-02

### Added
- Add log rotation to author standby promotion

## [0.10.1] - 2018-05-31

### Changed
- Rename AEM 6.3 SP2 asset name to be identical to Adobe Package Share's

## [0.10.0] - 2018-05-30

### Added
- Add manifest for logrotation configuration
- Add AEM profiles: aem63_sp2, aem63_sp2_cfp1

### Changed
- Switch InSpec deps to released versions
