#== Class: aem_curator::config_author_primary
# Configuration AEM Author
#
# === Parameters
# [*jvm_mem_opts*]
#   User defined JVM Memory options to be passed to the AEM Author
#
# [*jmxremote_port*]
#   User defined Port on which JMXRemote is listening
#
# [*jvm_opts*]
#   User defined additional JVM options

# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#

File {
  backup => false,
}

class aem_curator::config_author_primary (
  $aem_password_reset_source,
  $aem_password_reset_version,
  $aem_system_users,
  $author_port,
  $author_protocol,
  $author_timeout,
  $credentials_file,
  $crx_quickstart_dir,
  $enable_crxde,
  $enable_default_passwords,
  $login_ready_base_sleep_seconds,
  $login_ready_max_sleep_seconds,
  $login_ready_max_tries,
  $puppet_conf_dir,
  $tmp_dir,
  $aem_base                                              = undef,
  $aem_healthcheck_source                                = undef,
  $aem_healthcheck_version                               = undef,
  $aem_id                                                = 'author',
  $aem_ssl_keystore_password                             = undef,
  $aem_keystore_path                                     = undef,
  $enable_aem_reconfiguration                            = false,
  $enable_truststore_migration                           = false,
  $enable_authorizable_keystore_creation                 = false,
  $enable_post_start_sleep                               = false,
  $enable_saml                                           = false,
  $enable_truststore_creation                            = false,
  $author_ssl_port                                       = undef,
  $aem_version                                           = '6.2',
  $cert_base_url                                         = undef,
  $enable_create_system_users                            = undef,
  $delete_repository_index                               = false,
  $post_start_sleep_seconds                              = '120',
  $proxy_enabled                                         = false,
  $proxy_host                                            = undef,
  $proxy_port                                            = undef,
  $proxy_user                                            = undef,
  $proxy_password                                        = undef,
  $proxy_exceptions                                      = undef,
  $jmxremote_port                                        = '5982',
  $jvm_mem_opts                                          = undef,
  $jvm_opts                                              = undef,
  $run_mode                                              = 'author',
  $truststore_password                                   = undef,
  $saml_configuration                                    = {},
  $enable_authorizable_keystore_certificate_chain_upload = false,
  $enable_saml_certificate_upload                        = false,
) {

  if !defined(File[$tmp_dir]) {
    file { $tmp_dir:
      ensure => directory,
    }
  }

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  exec { "${aem_id}: Set repository ownership":
    command => "chown -R aem-${aem_id}:aem-${aem_id} ${crx_quickstart_dir}/repository/",
    before  => Service['aem-author'],
  }

  if $delete_repository_index {

    file { "${crx_quickstart_dir}/repository/index/":
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
      before  => Service['aem-author'],
    }

  }

  if $jvm_mem_opts {
    file_line { "${aem_id}: Set JVM memory opts":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_MEM_OPTS='${jvm_mem_opts}'",
      match  => '^JVM_MEM_OPTS',
    }
  }

  if $jmxremote_port {
    file_line { "${aem_id}: enable JMXRemote":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${jmxremote_port} -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=true -Djava.rmi.server.hostname=localhost\"",
      after  => '^JVM_OPTS',
      notify => Service['aem-author'],
    }
  }

  if $jvm_opts {
    file_line { "${aem_id}: Add custom JVM OPTS settings":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_OPTS=\"\$JVM_OPTS ${jvm_opts} \"",
      after  => '^JVM_OPTS=\"\$JVM_OPTS',
      notify => Service['aem-author'],
    }
  }

  if $enable_post_start_sleep {
    exec { "${aem_id}: Sleep ${post_start_sleep_seconds} seconds after starting AEM Service":
      command => "sleep ${post_start_sleep_seconds}",
      require => Service['aem-author'],
      before  => Aem_aem["${aem_id}: Wait until login page is ready"]
    }
  }

  file { "${crx_quickstart_dir}/install/":
    ensure => directory,
    mode   => '0775',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  } -> archive { "${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip":
    ensure => present,
    source => $aem_password_reset_source,
  } -> aem_resources::puppet_aem_resources_set_config { 'Set puppet-aem-resources config file for author-primary':
    conf_dir => $puppet_conf_dir,
    timeout  => $author_timeout,
    protocol => $author_protocol,
    host     => 'localhost',
    port     => $author_port,
    debug    => false,
    aem_id   => $aem_id,
  } -> aem_resources::author_primary_set_config { 'Set author-primary config':
    crx_quickstart_dir => $crx_quickstart_dir,
    aem_version        => $aem_version,
  } -> service { 'aem-author':
    ensure => 'running',
    enable => true,
  } -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_curator::reconfig_aem{ "${aem_id}: Reconfigure AEM":
    aem_base                   => $aem_base,
    aem_id                     => $aem_id,
    aem_healthcheck_source     => $aem_healthcheck_source,
    aem_healthcheck_version    => $aem_healthcheck_version,
    aem_ssl_keystore_password  => $aem_ssl_keystore_password,
    aem_keystore_path          => $aem_keystore_path,
    enable_aem_reconfiguration => $enable_aem_reconfiguration,
    aem_ssl_port               => $author_ssl_port,
    aem_system_users           => $aem_system_users,
    cert_base_url              => $cert_base_url,
    enable_create_system_users => $enable_create_system_users,
    credentials_hash           => $credentials_hash,
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
  } -> aem_aem { "${aem_id}: Remove all agents":
    ensure   => all_agents_removed,
    run_mode => 'author',
    aem_id   => $aem_id,
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
  } -> aem_curator::config_saml { "${aem_id}: Configure SAML authentication":
    aem_id                                                => $aem_id,
    aem_system_users                                      => $aem_system_users,
    enable_saml                                           => $enable_saml,
    enable_authorizable_keystore_creation                 => $enable_authorizable_keystore_creation,
    saml_configuration                                    => $saml_configuration,
    enable_authorizable_keystore_certificate_chain_upload => $enable_authorizable_keystore_certificate_chain_upload,
    enable_saml_certificate_upload                        => $enable_saml_certificate_upload,
    tmp_dir                                               => $tmp_dir
  } -> aem_curator::config_aem_bundles{ "${aem_id}: Configure AEM Bundles":
    enable_apache_proxy_config     => $proxy_enabled,
    apache_proxy_host              => $proxy_host,
    apache_proxy_port              => $proxy_port,
    apache_proxy_user              => $proxy_user,
    apache_proxy_password          => $proxy_password,
    apache_proxy_exceptions        => $proxy_exceptions,
    login_ready_max_tries          => $login_ready_max_tries,
    login_ready_base_sleep_seconds => $login_ready_base_sleep_seconds,
    login_ready_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                         => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until login page is ready after configuring SAML authentication":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok after configuring SAML authentication":
    ensure                     => aem_health_check_is_ok,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    tags                       => 'deep',
    aem_id                     => $aem_id,
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
  } -> file { "${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip":
    ensure => absent,
  }

}
