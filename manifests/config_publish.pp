#== Class: aem_curator::config_publish
# Configuration AEM Publisher
#
# === Parameters
# [*jvm_mem_opts*]
#   User defined JVM Memory options to be passed to AEM Publisher
#
# [*jmxremote_port*]
#   User defined Port on which JMXRemote is listening
#
# [*jvm_opts*]
#   User defined additional JVM options
#
# [*aem_home_dir*]
#  Path to the AEM Application home directory
#  default: /opt/aem/publish
#
# [*publish_standby_osgi_config*]
#  publish Standby OSGI configuration as hashmap.
#  default: undef
#
# [*aem_context_root*]
#  Set CONTEXT_ROOT in AEM start-env binary
#  default: undef
#
# [*aem_debug_port*]
#  Enable AEM Debug port
#  default: undef
#
# [*aem_osgi_configs*]
#  A Hashmap of OSGI to configure on AEM.
#  A list of examples can be found here https://github.com/bstopp/puppet-aem/blob/1441ee00f4669b56e43476273bba5073f0985fbc/docs/aem-instance/OSGi-Configurations.md
#  default: {}
#
# [*aem_runmodes*]
#  A list of additional runmodes for AEM
#  default: []
#
# [*aem_crx_packages*]
#   A list of CRX packages.
#   Allowed values are  s3: | http: | https: | file:
#  default: undef
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#


File {
  backup => false,
}

class aem_curator::config_publish (
  $aem_password_reset_source,
  $aem_password_reset_version,
  $aem_system_users,
  $credentials_file,
  $crx_quickstart_dir,
  $enable_crxde,
  $enable_default_passwords,
  $exec_path,
  $login_ready_base_sleep_seconds,
  $login_ready_max_sleep_seconds,
  $login_ready_max_tries,
  $publish_port,
  $publish_protocol,
  $publish_dispatcher_id,
  $publish_dispatcher_host,
  $publish_timeout,
  $puppet_conf_dir,
  $tmp_dir,
  $aem_base                                      = '/opt',
  $aem_context_root                              = undef,
  $aem_crx_packages                              = undef,
  $aem_debug_port                                = undef,
  $aem_healthcheck_source                        = undef,
  $aem_healthcheck_version                       = undef,
  $aem_home_dir                                  = '/opt/aem/publish',
  $aem_id                                        = 'publish',
  $aem_keystore_path                             = undef,
  $aem_osgi_configs                              = {},
  $aem_runmodes                                  = [],
  $aem_ssl_keystore_password                     = undef,
  $certificate_arn                               = undef,
  $certificate_key_arn                           = undef,
  $data_volume_mount_point                       = undef,
  $delete_repository_index                       = false,
  $enable_aem_reconfiguration                    = false,
  $enable_aem_installation_migration             = false,
  $enable_aem_reconfiguratiton_clean_directories = false,
  $enable_aem_clean_directories                  = false,
  $enable_create_flush_agents                    = false,
  $enable_create_outbox_replication_agents       = false,
  $enable_post_start_sleep                       = false,
  $enable_remove_all_agents                      = false,
  $enable_truststore_creation                    = false,
  $enable_truststore_migration                   = false,
  $enable_truststore_removal                     = false,
  $post_start_sleep_seconds                      = '120',
  $publish_ssl_port                              = undef,
  $jmxremote_port                                = '59183',
  $jvm_mem_opts                                  = undef,
  $jvm_opts                                      = undef,
  $run_mode                                      = 'publish',
  $truststore_password                           = undef,
) {

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

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  exec { "${aem_id}: Set repository ownership":
    command => "chown -R aem-${aem_id}:aem-${aem_id} ${data_volume_mount_point}",
    before  => Service['aem-publish'],
  }

  if $delete_repository_index {
    file { "${crx_quickstart_dir}/repository/index/":
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
      before  => Service['aem-publish'],
    }
  }

  # If reconfiguration is enabled run pre-reconfiguration manifest.
  # The pre-reconfiguration will execute all offline tasks including
  # updating the crx-quickstart/bin/start-env. If not enabled we update
  # start-env as usual.
  if $enable_aem_reconfiguration {
    aem_curator::reconfig_pre_aem{ "${aem_id}: Execute Pre-reconfiguration for AEM":
      aem_base                          => $aem_base,
      aem_id                            => $aem_id,
      enable_aem_reconfiguration        => $enable_aem_reconfiguration,
      enable_aem_installation_migration => $enable_aem_installation_migration,
      enable_clean_directories          => $enable_aem_reconfiguratiton_clean_directories,
      certificate_arn                   => $certificate_arn,
      certificate_key_arn               => $certificate_key_arn,
      crx_quickstart_dir                => $crx_quickstart_dir,
      data_volume_mount_point           => $data_volume_mount_point,
      tmp_dir                           => "${tmp_dir}/${aem_id}",
      before                            => [
                                            File["${crx_quickstart_dir}/install/"]
                                          ],
    }
  }

  # Updating provided JVM Options with JMXRemote JVM options if port is provided
  if $jmxremote_port {
    $jmxremote_options = [
      '-Dcom.sun.management.jmxremote',
      "-Dcom.sun.management.jmxremote.port=${jmxremote_port}",
      '-Dcom.sun.management.jmxremote.authenticate=false',
      '-Dcom.sun.management.jmxremote.ssl=false',
      '-Dcom.sun.management.jmxremote.local.only=true',
      '-Djava.rmi.server.hostname=localhost'
    ]
    $_jvm_opts_list = concat([$jvm_opts], $jmxremote_options)
    $_jvm_opts = $_jvm_opts_list.join(' ')
  } else {
    $_jvm_opts = $jvm_opts
  }

  if $enable_post_start_sleep {
    exec { "${aem_id}: Sleep ${post_start_sleep_seconds} seconds after starting AEM Service":
      command => "sleep ${post_start_sleep_seconds}",
      require => Service['aem-publish'],
      before  => Aem_aem["${aem_id}: Wait until login page is ready"]
    }
  }

  if $enable_aem_clean_directories {
    $list_clean_directories = [
      'logs',
      'threaddumps'
    ]

    $list_clean_directories.each | Integer $index, String $clean_directory| {
      exec { "${aem_id}: Cleaning directory ${crx_quickstart_dir}/${clean_directory}/":
        command => "rm -fr ${crx_quickstart_dir}/${clean_directory}/*",
        before  => File["${crx_quickstart_dir}/install/"],
      }
    }
  }

  #
  # If reconfiguration is enabled & clean directories for reconfiguration
  # is enabled than we don't install AEM Healthcheck because it's already
  # done during the reconfiguration process. Otherwise install aem healthcheck
  # apart from the reconfiguration process.
  #
  unless $enable_aem_reconfiguratiton_clean_directories {
  #
  # remove any aem-healthcheck-content package from the install directory
  # If install dir isn't cleaned up a step before per default
  #
  if !('install' in $list_clean_directories) {
  exec { "${aem_id}: remove ${crx_quickstart_dir}/install/aem-healthcheck-content-*.zip":
    command => "rm -fr ${crx_quickstart_dir}/install/aem-healthcheck-content-*.zip",
    before  => [
      Service['aem-publish']
      ],
    }
  }

  aem_curator::install_aem_healthcheck {"${aem_id}: Install AEM Healthcheck":
    aem_base                => $aem_base,
    aem_healthcheck_source  => $aem_healthcheck_source,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_id                  => $aem_id,
    tmp_dir                 => $tmp_dir,
    require                 => [
                                Service['aem-publish'],
                              ],
    before                  => [
                                Aem_aem["${aem_id}: Wait until login page is ready"],
                              ]
    }
  }

  aem_resources::puppet_aem_resources_set_config { 'Set puppet-aem-resources config file for publish':
    conf_dir => $puppet_conf_dir,
    timeout  => $publish_timeout,
    protocol => $publish_protocol,
    host     => 'localhost',
    port     => $publish_port,
    debug    => false,
    aem_id   => $aem_id,
  }  -> aem_resources::publish_set_config { 'Set publish config':
    aem_context_root => $aem_context_root,
    aem_crx_packages => $aem_crx_packages,
    aem_debug_port   => $aem_debug_port,
    aem_home_dir     => $aem_home_dir,
    aem_id           => $aem_id,
    aem_port         => $publish_port,
    aem_runmodes     => $aem_runmodes,
    aem_user         => "aem-${aem_id}",
    aem_user_group   => "aem-${aem_id}",
    jvm_mem_opts     => $jvm_mem_opts,
    jvm_opts         => $_jvm_opts,
    osgi_configs     => $aem_osgi_configs
  } -> archive { "${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip":
    ensure => present,
    source => $aem_password_reset_source,
    user   => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  } -> file { "${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip":
    ensure => present,
    mode   => '0640',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  } -> file {"${crx_quickstart_dir}/install/org.apache.sling.jcr.base.internal.LoginAdminWhitelist.fragment-passwordreset.config":
    ensure => present,
    source => 'puppet:///modules/aem_curator/crx-quickstart/install/org.apache.sling.jcr.base.internal.LoginAdminWhitelist.fragment-passwordreset.config',
    mode   => '0775',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  } -> service { 'aem-publish':
    ensure => 'running',
    enable => true,
  } -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until CRX Package Manager is ready" :
    ensure                     => aem_package_manager_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_curator::reconfig_aem{ "${aem_id}: Reconfigure AEM":
    aem_base                   => $aem_base,
    aem_healthcheck_source     => $aem_healthcheck_source,
    aem_healthcheck_version    => $aem_healthcheck_version,
    aem_id                     => $aem_id,
    aem_keystore_path          => $aem_keystore_path,
    aem_ssl_keystore_password  => $aem_ssl_keystore_password,
    aem_ssl_port               => $publish_ssl_port,
    aem_system_users           => $aem_system_users,
    credentials_hash           => $credentials_hash,
    crx_quickstart_dir         => $crx_quickstart_dir,
    enable_aem_reconfiguration => $enable_aem_reconfiguration,
    enable_clean_directories   => $enable_aem_reconfiguratiton_clean_directories,
    enable_truststore_removal  => $enable_truststore_removal,
    run_mode                   => $run_mode,
    tmp_dir                    => $tmp_dir,
  } -> aem_bundle { "${aem_id}: Stop webdav bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.webdav',
    aem_id => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until login page is ready after stopping webdav bundle":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after stopping webdav bundle":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
  } -> aem_bundle { "${aem_id}: Stop davex bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.davex',
    aem_id => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until login page is ready after stopping davex bundle":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after stopping davex bundle":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
  } -> aem_curator::config_aem_crxde { "${aem_id}: Configure CRXDE":
    aem_id       => $aem_id,
    enable_crxde => $enable_crxde,
    run_mode     => $run_mode,
  } -> aem_aem { "${aem_id}: Wait until login page is ready after configuring CRXDE":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after configuring CRXDE":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
  } -> aem_curator::config_aem_agents { "${aem_id}: Remove all agents":
    run_mode                 => 'publish',
    aem_id                   => $aem_id,
    enable_remove_all_agents => $enable_remove_all_agents,
  } -> aem_aem { "${aem_id}: Wait until login page is ready after removing all agents":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after removing all agents":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
  } -> aem_curator::config_truststore { "${aem_id}: Configure AEM Truststore":
    aem_id                      => $aem_id,
    enable_truststore_creation  => $enable_truststore_creation,
    enable_truststore_migration => $enable_truststore_migration,
    truststore_password         => $truststore_password,
    tmp_dir                     => $tmp_dir
  } -> aem_aem { "${aem_id}: Wait until login page is ready after configuring AEM Truststore":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after configuring AEM Truststore":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until CRX Package Manager is ready before removing password reset package":
    ensure                     => aem_package_manager_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> exec { "${aem_id}: Remove file org.apache.sling.jcr.base.internal.LoginAdminWhitelist.fragment-passwordreset.config":
    command => "rm -f ${crx_quickstart_dir}/install/org.apache.sling.jcr.base.internal.LoginAdminWhitelist.fragment-passwordreset.config",
  } -> aem_package { "${aem_id}: Remove password reset package":
    ensure  => absent,
    name    => 'aem-password-reset-content',
    group   => 'shinesolutions',
    version => $aem_password_reset_version,
    aem_id  => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until login page is ready after removing password reset package":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after removing password reset package":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
  } -> aem_curator::config_aem_agents { "${aem_id}: Create flush agent":
    run_mode                   => 'publish',
    aem_id                     => $aem_id,
    enable_create_flush_agents => $enable_create_flush_agents,
    log_level                  => 'info',
    dispatcher_id              => $publish_dispatcher_id,
    dispatcher_host_url        => $publish_dispatcher_host,
  } -> aem_aem { "${aem_id}: Wait until login page is ready after creating flush agent":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after creating flush agent":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
  } -> aem_curator::config_aem_agents { "${aem_id}: Create outbox replication agent":
    run_mode                                => 'publish',
    aem_id                                  => $aem_id,
    enable_create_outbox_replication_agents => $enable_create_outbox_replication_agents,
    log_level                               => 'info',
    dispatcher_id                           => $publish_dispatcher_id,
    replication_agent_user_id               => 'replicator'
  } -> aem_aem { "${aem_id}: Wait until login page is ready after creating outbox replication agent":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after creating outbox replication agent":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
  } -> aem_curator::config_aem_system_users { "${aem_id}: Configure system users":
    aem_id                   => $aem_id,
    aem_system_users         => $aem_system_users,
    credentials_hash         => $credentials_hash,
    enable_default_passwords => $enable_default_passwords,
  } -> aem_aem { "${aem_id}: Wait until login page is ready after configuring system users":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after configuring system users":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
    aem_username               => 'orchestrator',
    aem_password               => $credentials_hash['orchestrator'],
  } -> exec { "${aem_id}: Cleanup password reset package after installation":
    command => "rm -f ${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip"
  }
}
