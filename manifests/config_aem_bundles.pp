define aem_curator::config_aem_bundles (
  $enable_apache_proxy_config,
  $apache_proxy_host,
  $apache_proxy_port,
  $apache_proxy_user,
  $apache_proxy_password,
  $apache_proxy_exceptions,
  $login_ready_max_tries,
  $login_ready_base_sleep_seconds,
  $login_ready_max_sleep_seconds,
  $aem_id,
) {

  if $enable_apache_proxy_config {
    aem_node { "${aem_id}: Create Apache http proxy configuration config node":
      ensure => present,
      name   => 'org.apache.http.proxyconfigurator.config',
      path   => '/apps/system/config',
      type   => 'sling:OsgiConfig',
      aem_id => $aem_id,
    } -> aem_config_property { "${aem_id}: Configure Proxy host for Apache http proxy configuration":
      ensure           => present,
      name             => 'proxy.host',
      type             => 'String',
      value            => $apache_proxy_host,
      config_node_name => 'org.apache.http.proxyconfigurator.config',
      aem_id           => $aem_id,
    } -> aem_config_property { "${aem_id}: Configure Proxy port for Apache http proxy configuration":
      ensure           => present,
      name             => 'proxy.port',
      type             => 'Long',
      value            => $apache_proxy_port,
      config_node_name => 'org.apache.http.proxyconfigurator.config',
      aem_id           => $aem_id,
    } -> aem_config_property { "${aem_id}: Configure Proxy exceptions for Apache http proxy configuration":
      ensure           => present,
      name             => 'proxy.exceptions',
      type             => 'String[]',
      value            => $apache_proxy_exceptions,
      config_node_name => 'org.apache.http.proxyconfigurator.config',
      aem_id           => $aem_id,
      before           => Aem_config_property["${aem_id}: Enable configuration for Apache http proxy configuration"]
    }

    if $apache_proxy_user != '' {
      aem_config_property { "${aem_id}: Configure Proxy user for Apache http proxy configuration":
        ensure           => present,
        name             => 'proxy.user',
        type             => 'String',
        value            => $apache_proxy_user,
        config_node_name => 'org.apache.http.proxyconfigurator.config',
        aem_id           => $aem_id,
        before           => Aem_config_property["${aem_id}: Enable configuration for Apache http proxy configuration"],
        require          => Aem_config_property["${aem_id}: Configure Proxy exceptions for Apache http proxy configuration"],
      }
    }

    if $apache_proxy_password != '' {
      aem_config_property { "${aem_id}: Configure Proxy password for Apache http proxy configuration":
       ensure           => present,
       name             => 'proxy.password',
       type             => 'String',
       value            => $apache_proxy_password,
       config_node_name => 'org.apache.http.proxyconfigurator.config',
       aem_id           => $aem_id,
       require          => Aem_config_property["${aem_id}: Configure Proxy user for Apache http proxy configuration"],
       before           => Aem_config_property["${aem_id}: Enable configuration for Apache http proxy configuration"]
     }
    }

    aem_config_property { "${aem_id}: Enable configuration for Apache http proxy configuration":
      ensure           => present,
      name             => 'proxy.enabled',
      type             => 'Boolean',
      value            => $enable_apache_proxy_config,
      config_node_name => 'org.apache.http.proxyconfigurator.config',
      aem_id           => $aem_id,
    } -> aem_aem { "${aem_id}: Wait until login page is ready after configuring Apache http proxy":
      ensure                     => login_page_is_ready,
      retries_max_tries          => $login_ready_max_tries,
      retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
      retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
      aem_id                     => $aem_id,
    } -> aem_aem { "${aem_id}: Wait until aem health check is ok after configuring Apache http proxy":
      ensure                     => aem_health_check_is_ok,
      retries_max_tries          => $login_ready_max_tries,
      retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
      retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
      tags                       => 'deep',
      aem_id                     => $aem_id,
    }
  }
}
