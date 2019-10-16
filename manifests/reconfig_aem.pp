File {
  backup => false,
}

define aem_curator::reconfig_aem (
  $aem_id                     = undef,
  $aem_username               = undef,
  $aem_password               = undef,
  $enable_aem_reconfiguration = false,
  $enable_truststore_removal  = true,
  $enable_clean_directories   = false,
  $aem_base                   = '/opt',
  $aem_healthcheck_source     = undef,
  $aem_healthcheck_version    = undef,
  $aem_ssl_keystore_password  = undef,
  $aem_keystore_path          = undef,
  $aem_ssl_port               = undef,
  $aem_system_users           = undef,
  $credentials_hash           = undef,
  $crx_quickstart_dir         = undef,
  $enable_create_system_users = true,
  $force                      = true,
  $post_install_sleep_secs    = 120,
  $retries_base_sleep_seconds = 10,
  $retries_max_sleep_seconds  = 10,
  $retries_max_tries          = 120,
  $run_mode                   = undef,
  $tmp_dir                    = undef,
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

    $tmp_dir_final = "${tmp_dir}/${aem_id}"

    # When `force` is set to true, it blows up the configurations on the repository
    # Otherwise, the configurations are kept and will be overwritten
    if $force {
      aem_node { "${aem_id}: Delete path /apps/system/config":
        ensure  => absent,
        path    => '/apps/system',
        name    => 'config',
        aem_id  => $aem_id,
        before  => [
                    Aem_aem["${aem_id}: Wait until CRX Package Manager is ready before reconfiguration"]
                  ],
        require => [
                      Aem_aem["${aem_id}: Wait until aem health check is ok"]
                    ],
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
        before       => [
                          Aem_aem["${aem_id}: Wait until CRX Package Manager is ready before reconfiguration"]
                        ],
        require      => [
                          Aem_aem["${aem_id}: Wait until aem health check is ok"]
                        ],
      }
    }

    ###########################################################################
    # If clean dir is enabled clean up directories in list
    # If not enabled cleanup only any existing aem-healthcheck packages
    ###########################################################################
    if $enable_clean_directories {
        $list_clean_directories = [
        'install',
        ]
        #
        # since we are only cleaning the install dir
        # we clean during runtime.
        #
        $list_clean_directories.each | Integer $index, String $clean_directory| {
          exec { "${aem_id}: Clean directory ${crx_quickstart_dir}/${clean_directory}/":
            command => "rm -fr ${crx_quickstart_dir}/${clean_directory}/*",
            before  => [
                        Aem_aem["${aem_id}: Wait until CRX Package Manager is ready before reconfiguration"]
                      ],
            require => [
                          Aem_aem["${aem_id}: Wait until aem health check is ok"]
                        ],
          } -> exec { "${aem_id}: sleep ${post_install_sleep_secs} seconds for package uninstallations":
            command => "sleep ${post_install_sleep_secs}",
          }
        }

        aem_curator::install_aem_healthcheck {"${aem_id}: Install AEM Healthcheck":
          aem_base                => $aem_base,
          aem_healthcheck_source  => $aem_healthcheck_source,
          aem_healthcheck_version => $aem_healthcheck_version,
          aem_id                  => $aem_id,
          tmp_dir                 => $tmp_dir_final,
          before                  => [
                                      Aem_aem["${aem_id}: Wait until CRX Package Manager is ready before reconfiguration"]
                                      ],
          require                 => [
                                      Aem_aem["${aem_id}: Wait until aem health check is ok"]
                                      ],
        }
    }

    aem_aem { "${aem_id}: Wait until login page is ready to start reconfiguration":
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
      cert_base_url              => "file://${tmp_dir_final}/certs",
      enable_create_system_users => $enable_create_system_users,
      credentials_hash           => $credentials_hash,
      run_mode                   => $run_mode,
      tmp_dir                    => $tmp_dir_final,
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
