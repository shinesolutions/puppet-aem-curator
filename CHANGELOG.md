### 0.9.12
*

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
