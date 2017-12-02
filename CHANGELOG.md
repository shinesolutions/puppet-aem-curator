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
