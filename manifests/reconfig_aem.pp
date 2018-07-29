File {
  backup => false,
}

define aem_curator::reconfig_aem (
  $aem_id                     = undef,
  $aem_username               = undef,
  $aem_password               = undef,
  $aem_reconfiguration        = true,
  $aem_base                   = '/opt',
  $aem_healthcheck_source     = undef,
  $aem_healthcheck_version    = undef,
  $aem_keystore_password      = undef,
  $aem_keystore_path          = undef,
  $aem_ssl_port               = undef,
  $aem_system_users           = undef,
  $cert_base_url              = undef,
  $enable_create_system_users = true,
  $credentials_hash           = undef,
  $force                      = true,
  $post_install_sleep_secs    = 120,
  $retries_base_sleep_seconds = 10,
  $retries_max_sleep_seconds  = 10,
  $retries_max_tries          = 120,
  $run_mode                   = undef,
  $tmp_dir                    = undef,
) {
  if $aem_reconfiguration {

    Aem_aem {
      retries_max_tries          => $retries_max_tries,
      retries_base_sleep_seconds => $retries_base_sleep_seconds,
      retries_max_sleep_seconds  => $retries_max_sleep_seconds,
    }

    if !defined(File[$tmp_dir]) {
      file { $tmp_dir:
        ensure => directory,
      }
    }
    if !defined(File["${tmp_dir}/${aem_id}"]) {
      file { "${tmp_dir}/${aem_id}":
        ensure => directory,
        mode   => '0700',
      }
    }

    if $force {
      aem_node { "${aem_id}: Delete path /apps/system/config":
        ensure => absent,
        path   => '/apps/system',
        name   => 'config',
        aem_id => $aem_id,
        before => Exec["service aem-${aem_id} stop"]
      } -> exec { "[${aem_id}] Wait after deletion of /apps/system/config":
        command => 'sleep 15',
        path    => ['/usr/bin', '/usr/sbin', '/bin'],
      } -> aem_node { "${aem_id}: Delete path /apps/system/config.${run_mode}":
        ensure => absent,
        path   => '/apps/system',
        name   => "config.${run_mode}",
        aem_id => $aem_id,
      } -> exec { "[${aem_id}] Wait after deletion of /apps/system/config.${run_mode}":
        command => 'sleep 15',
        path    => ['/usr/bin', '/usr/sbin', '/bin'],
      }
    }

    exec { "rm -f ${aem_base}/aem/${aem_id}/crx-quickstart/install/aem-healthcheck-content-*.zip":
    } -> exec { "service aem-${aem_id} stop":
    } -> aem_curator::install_aem_healthcheck {"${aem_id}: Install AEM Healthcheck":
      aem_base                => $aem_base,
      aem_healthcheck_source  => $aem_healthcheck_source,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_id                  => $aem_id,
      tmp_dir                 => $tmp_dir,
    } -> exec { "service aem-${aem_id} start":
    } -> exec { "${aem_id}: Manual delay to let AEM become ready":
      command => "sleep ${post_install_sleep_secs}",
    } -> aem_aem { "${aem_id}: Wait until login page is ready after installing AEM Healthcheck":
      ensure => login_page_is_ready,
      aem_id => $aem_id,
    } -> aem_aem { "${aem_id}: Wait until aem health check is ok":
      ensure => aem_health_check_is_ok,
      tags   => 'shallow',
      aem_id => $aem_id,
    }

    aem_curator::config_aem { "Configure AEM ${aem_id}":
        aem_base                   => $aem_base,
        aem_id                     => $aem_id,
        aem_keystore_password      => $aem_keystore_password,
        aem_keystore_path          => $aem_keystore_path,
        aem_ssl_port               => $aem_ssl_port,
        aem_system_users           => $aem_system_users,
        cert_base_url              => $cert_base_url,
        enable_create_system_users => $enable_create_system_users,
        credentials_hash           => $credentials_hash,
        run_mode                   => $run_mode,
        tmp_dir                    => $tmp_dir,
        require                    => Aem_aem["${aem_id}: Wait until aem health check is ok"]
    } -> aem_aem { "${aem_id}: Wait until login page is ready after reconfiguration":
      ensure => login_page_is_ready,
      aem_id => $aem_id,
    } -> aem_aem { "${aem_id}: Wait until aem health check is ok after reconfiguration":
      ensure => aem_health_check_is_ok,
      tags   => 'deep',
      aem_id => $aem_id
    }
  }
}
