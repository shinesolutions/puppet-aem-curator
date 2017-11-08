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
