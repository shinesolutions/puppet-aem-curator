File {
  backup => false,
}

define aem_curator::reconfig_aem (
  $aem_id                            = undef,
  $aem_username                      = undef,
  $aem_password                      = undef,
  $enable_aem_reconfiguration        = true,
  $enable_truststore_removal         = true,
  $aem_base                          = '/opt',
  $aem_healthcheck_source            = undef,
  $aem_healthcheck_version           = undef,
  $aem_ssl_keystore_password         = undef,
  $aem_keystore_path                 = undef,
  $aem_ssl_port                      = undef,
  $aem_system_users                  = undef,
  $cert_base_url                     = undef,
  $credentials_hash                  = undef,
  $data_volume_mount_point           = undef,
  $enable_create_system_users        = true,
  $force                             = true,
  $enable_aem_installation_migration = true,
  $post_install_sleep_secs           = 120,
  $retries_base_sleep_seconds        = 10,
  $retries_max_sleep_seconds         = 10,
  $retries_max_tries                 = 120,
  $run_mode                          = undef,
  $tmp_dir                           = undef,
) {
  if $enable_aem_reconfiguration {

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

    # When `force` is set to true, it blows up the configurations on the repository
    # Otherwise, the configurations are kept and will be overwritten
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

    if $enable_truststore_removal {
      aem_resources::remove_truststore { "${aem_id}: Delete AEM Global Truststore":
        aem_id       => $aem_id,
        aem_username => $aem_username,
        aem_password => $aem_password,
        force        => false,
        before       => Exec["service aem-${aem_id} stop"],
      }
    }

    if $enable_aem_installation_migration {
      # Migrating the AEM installation directories to the mounted data filesystem.
      # Before migrating we are preparing the current repository as prior
      # AEM OpenCloud version 3.11.0 the data filesystem only contains the repository.
      # This is necessary as with AEM 6.4 the AEM installation directory
      # and repository directory needs to be consistent.

      $aem_installation_new_directory = "${data_volume_mount_point}/${aem_id}"
      $aem_installation_old_directory = "${aem_base}/aem/${aem_id}"
      $source_repository_dir = "${aem_installation_old_directory}/crx-quickstart/repository"
      $tmp_repository_dir = "${data_volume_mount_point}/repository"
      $dest_repository_dir = "${aem_installation_new_directory}/crx-quickstart/repository"

      if !defined(File[$aem_installation_new_directory]) {
        file { "${aem_id}: Create ${tmp_repository_dir}":
          ensure  => directory,
          path    => $tmp_repository_dir,
          before  => Exec["${aem_id}: Fix data volume permissions"],
          require => Exec["service aem-${aem_id} stop"]
        } -> exec { "${aem_id}: Move ${source_repository_dir} to ${tmp_repository_dir}":
          command => "mv ${source_repository_dir}/* ${tmp_repository_dir}/",
          returns => [
            '0',
            '1'
          ]
        } -> exec { "${aem_id}: Remove ${source_repository_dir}":
          command => "rm -f ${source_repository_dir}",
          returns => [
            '0'
          ]
        } -> exec { "${aem_id}: Move ${aem_installation_old_directory} to ${aem_installation_new_directory}":
          command => "mv ${aem_installation_old_directory} ${aem_installation_new_directory}",
          returns => [
            '0'
          ]
        } -> exec { "${aem_id}: Move ${tmp_repository_dir} to ${dest_repository_dir}":
          command => "mv ${tmp_repository_dir} ${dest_repository_dir}",
          returns => [
            '0'
          ]
        } -> exec { "${aem_id}: Remove ${aem_installation_old_directory}":
          command => "rm -fr ${aem_installation_old_directory}",
          returns => [
            '0'
          ]
        } -> exec { "${aem_id}: Set link from ${aem_installation_old_directory} to ${aem_installation_new_directory}":
          command => "ln -s ${aem_installation_new_directory} ${aem_installation_old_directory}",
          returns => [
            '0'
          ]
        }
      }

      exec { "${aem_id}: Fix data volume permissions":
        command => "chown -R aem-${aem_id}:aem-${aem_id} ${data_volume_mount_point}",
        before  => Exec["service aem-${aem_id} start"],
        require => Exec["service aem-${aem_id} stop"],
      }
    }

    exec { "service aem-${aem_id} stop":
      before  => Exec["service aem-${aem_id} start"],
    }

    exec { "service aem-${aem_id} start":
      require => Exec["service aem-${aem_id} stop"],
    } -> exec { "${aem_id}: Manual delay to let AEM become ready":
      command => "sleep ${post_install_sleep_secs}",
    } -> aem_aem { "${aem_id}: Wait until login page is ready after installing AEM Healthcheck":
      ensure => login_page_is_ready,
      aem_id => $aem_id,
    } -> aem_aem { "${aem_id}: Wait until aem health check is ok":
      ensure => aem_health_check_is_ok,
      tags   => 'shallow',
      aem_id => $aem_id,
    } -> aem_aem { "${aem_id}: Wait until CRX Package Manager is ready before reconfiguration":
      ensure                     => aem_package_manager_is_ready,
      retries_max_tries          => $retries_max_tries,
      retries_base_sleep_seconds => $retries_base_sleep_seconds,
      retries_max_sleep_seconds  => $retries_max_sleep_seconds,
      aem_id                     => $aem_id,
      aem_username               => $aem_username,
      aem_password               => $aem_password,
    }

    aem_curator::config_aem { "Configure AEM ${aem_id}":
      aem_base                   => $aem_base,
      aem_id                     => $aem_id,
      aem_keystore_password      => $aem_ssl_keystore_password,
      aem_keystore_path          => $aem_keystore_path,
      aem_ssl_port               => $aem_ssl_port,
      aem_system_users           => $aem_system_users,
      cert_base_url              => $cert_base_url,
      enable_create_system_users => $enable_create_system_users,
      credentials_hash           => $credentials_hash,
      run_mode                   => $run_mode,
      tmp_dir                    => $tmp_dir,
      require                    => Aem_aem["${aem_id}: Wait until CRX Package Manager is ready before reconfiguration"]
    } -> aem_aem { "${aem_id}: Wait until login page is ready after reconfiguration":
      ensure => login_page_is_ready,
      aem_id => $aem_id,
    } -> aem_aem { "${aem_id}: Wait until aem health check is ok after reconfiguration":
      ensure => aem_health_check_is_ok,
      tags   => 'deep',
      aem_id => $aem_id
    } -> aem_aem { "${aem_id}: Wait until CRX Package Manager is ready after reconfiguration":
      ensure                     => aem_package_manager_is_ready,
      retries_max_tries          => $retries_max_tries,
      retries_base_sleep_seconds => $retries_base_sleep_seconds,
      retries_max_sleep_seconds  => $retries_max_sleep_seconds,
      aem_id                     => $aem_id,
      aem_username               => $aem_username,
      aem_password               => $aem_password,
    }
  }
}
