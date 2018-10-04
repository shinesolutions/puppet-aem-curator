### 0.11.0
* Updated parameters for "Wait until login page is ready" to consume parameters from aem-aws-stack-provisioner
* Add additional checks during configuring AEM Author & AEM Publisher #63
* Add parameter deployment_sleep_seconds for resource deploy_packages
* Lock inspec version to 2.2.78 #60
* Remove support for Ruby 2.1 & 2.2 due to dependency issues
* Add feature to delete old bak files from the repository during offline-compaction
* Add install AEM profile action
* Simplify AEM profile installation logic #7

### 0.10.6
* Upgrade aem_resources to 2.3.1 for aem_user_alias support

### 0.10.5
* Add support for reconfiguring existing AEM installations
* Place AEM Healthcheck installation to own manifest
* Place AEM Configuration to own manifest
* Add feature to change existing system users passwords
* Improved credentials handling for system users

### 0.10.4
* Set repository ownership when configuring AEM Author Primary, Author Standby, and Publish
* Fix temp directory clean up at the end of artifacts deployment

### 0.10.3
* Add 0.10.x AEM profiles: aem62_sp1_cfp15, aem63_sp2_cfp2, aem64_sp1

### 0.10.2
* Add log rotation to author standby promotion

### 0.10.1
* Rename AEM 6.3 SP2 asset name to be identical to Adobe Package Share's

### 0.10.0
* Switch InSpec deps to released versions
* Add manifest for logrotation configuration
* Add AEM profiles: aem63_sp2, aem63_sp2_cfp1

### 0.9.30
* Add retries setting for deploying a single artifact #28

### 0.9.29
* Add AEM start opts support to AEM instance installation
* Backup import no longer fails when the package already exists

### 0.9.28
* Move snapshot attachment step to aem-aws-stack-provisioner
* Extract all scheduled jobs provisioning to config_aem_scheduled_jobs
* Fix missing Puppet exit code translation on all aem-tools

### 0.9.27
* Fix path conflict on flush dispatcher cache action

### 0.9.26
* Modify flush dispatcher cache action to remove only JCR sub-directories under docroot
* Add timeout setting to author and publish configuration manifests

### 0.9.25
* Clean up temp directory at the end of deploy artifacts
* Add parameter allowing additional java opts settings for author and publish

### 0.9.24
* Fix parameter passing on deploy artifact and export backups

### 0.9.23
* Add log_dir parameter to deploy artifact templates processing
* Add list packages support to aem-tools

### 0.9.22
* Fix incorrect match regex for Collectd CloudWatch config #25

### 0.9.21
* Set retry settings to AEM package deployment actions #28
* Add new AEM profile: aem64
* Move stack prefix and component details as a constant value dimension for Collectd CloudWatch config #25

### 0.9.20
* Add aem_id parameter to actions with on-demand AEM target

### 0.9.19
* Fix injection of aem_username & aem_password to action manifests #26
* Move export backup and import backup scripts provisioning to aem-aws-stack-provisioner
* Move AEM Author standby promotion instance rename to aem-aws-stack-provisioner
* Add InSpec testing for aem-tools actions
* Fix incorrect artifact name for aem63_sp1_cfp13

### 0.9.18
* Allow default aem_id via Hiera configuration for action manifests

### 0.9.17
* Add new AEM profile: aem63_sp1_cfp13 #21
* Add ssl_cert parameter to dispatcher templates
* Move aem_resources-generated virtual hosts config to virtual hosts directory

### 0.9.16
* Add complete dispatcher template parameters to all dispatcher template processing #19

### 0.9.15
* Move AEM Tools directory ensure to aem-aws-stack-provisioner
* Remove flush dispatcher cache script from config_aem_tools

### 0.9.14
* Add new manifest for Dispatcher aem-tools
* Add new aem-tool flush-dispatcher-cache

### 0.9.13
* Fix incorrect manifest for deploy-artifact aem-tools script
* Add integrated export-package,export-packages and import-packages from aem-aws-stack-provisioner to aem-curator

### 0.9.12
* Add multi AEM instances support to collectd config
* Fix aem63_sp1_cfp2 artifact file name and package name #6
* Add Author Standby component bean whitelisting

### 0.9.11
* Add new AEM profile: aem63_sp1_cfp2 #6
* Add aem_version to Author Standby and Author Primary OSGI configuration

### 0.9.10
* Migrate artifacts deployment tools from aem-aws-stack-provisioner to aem_curator
* Add feature enable jmxremote at AEM Author and Publish java instances
* Configure CloudWatch collectd plugin's proxy support only if proxy fact is set
* Add disable-crxde to aem-tools
* Drop Ruby 2.0 support

### 0.9.9
* Migrate all AEM Tools files and templates from aem-aws-stack-provisioner to aem_curator
* Migrate AWS-related scripts from aem_curator to aem-aws-stack-provisioner
* Parameterise all references to AWS S3
* Add multi AEM instances support to offline compaction and enable CRXDE
* Extract deployment support to config_aem_deployer manifest

### 0.9.8
* Localise global facts aem_password_reset_version, oak_run_version

### 0.9.7
* Remove publish_dispatcher_allowed_client, pairinstanceid, and publishdispatcherhost global facts
* Add config_author_dispatcher class
* Add config_author_standby class

### 0.9.6
* Add readiness checks during installation and configuration of AEM Dispatcher
* Added variable jvm_mem_opts to configure JVM Memory for AEM Author and Publisher

### 0.9.5
* config_publish_dispatcher no longer deploys artifacts (moved to aem-aws-stack-provisioner) due to AWS-specific check
* Fix Dispatcher artifacts descriptor generator script name

### 0.9.4
* Add enable_default_password flag for creating system users password with default value (i.e. same as username)
* Add enable_crxde flag for enabling CRXDE access

### 0.9.3
* Add new AEM profiles: aem62_sp1_cfp2, aem62_sp1_cfp9, aem63_sp1
* Rename jvm_opts param to aem_jvm_opts

### 0.9.2
* Introduce AEM profile concept which defines AEM base installation along with extra packages (hotfixes, service packs, cumulative fix packs)
* AEM and license files now have predetermined names, consistent with extra packages
* Add aem63 profile for vanilla AEM 6.3 base installation

### 0.9.1
* Add dependencies to metadata

### 0.9.0
* Initial version
* config_publish_dispatcher: Publisher Host definitions replaced: $publish_host class variable replaced $::publishhost
* config_publish: Flush agent definitions replaced: $publishdispatcherhost, $pairinstanceid class variable replaced $::publishdispatcherhost, $::pairinstanceid
* Move AEM Tools into its own manifest config_aem_tools.pp
* Migrate AEM installation manifests from packer-aem
* Add multi AEM instances support at manifests level by replacing classes with definitions and by introducing aem_id attributes
* Move collectd into its own manifest config_collectd.pp
* Each AEM installation has its own user and group named aem-<aem_id>
* Introduce vanilla AEM 6.2 option without hotfix, service pack, and cumulative fix pack packages
