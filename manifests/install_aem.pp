# == Class: config::aem
#
#  Shared Resources used by other AEM modules
#
# === Parameters
#
# [*tmp_dir*]
#   A temporary directory used for staging
#
# [*run_mode*]
#   The AEM role to install. Should be 'publish' or 'author'.
#
# [*aem_port*]
#   TCP port AEM will listen on.
#
# [*aem_ssl_port*]
#   SSL port AEM will listen on.
#
# [*aem_quickstart_source*]
# [*aem_license_source*]
# [*aem_artifacts_base*]
#   URLs (s3://, http:// or file://) for the AEM jar, license and package
#   files.
#
# [*aem_healthcheck_version*]
#   The version of the AEM healthcheck service to install.
#
# [*aem_base*]
#   Base directory for installing AEM.
#
# [*aem_sample_content*]
#   Boolean that determines whether the AEM sample content should be installed.
#
# [*aem_jvm_mem_opts*]
#   Extra memory options to be passed to the JVM.
#
# [*setup_repository_volume*]
#   Boolean that determines whether a separate volume is formatted and mounted
#   for the AEM repository.
#
# [*repository_volume_device*]
#   The device for format and mount for the AEM repository.
#
# [*repository_volume_mount_point*]
#   The mount point for the AEM repository volume.
#
# [*aem_keystore_path*]
#   The full path to the Java keystore that will store the X.509 certificate
#   and private key to be used by AEM.
#
# [*aem_keystore_password*]
#   The password for the AEM Java keystore.
#
# [*cert_base_url*]
#   Base URL (supported by the puppet-archive module) to download the X.509
#   certificate and private key to be used with Apache.
#
# [*tmp_dir*]
#   A temporary directory used to store the X.509 certificate and private key
#   while building the PEM file for Apache.
#
# [*post_install_sleep_secs*]
#   Number of seconds to sleep to allow AEM to settle. If installation fails,
#   try turning this up.
#
# [*jvm_opts*]
#   An array of command line options to pass to the JVM when starting AEM.
#
# [*aem_cfp_class*]
# the Puppet class name that used to install an AEM CFP
# === Authors
#
# Andy Wang <andy.wang@shinesolutions.com>
# James Sinclair <james.sinclair@shinesolutions.com>
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#

define aem_curator::install_aem (
  $tmp_dir,

  $run_mode,
  $aem_host,
  $aem_port,
  $aem_ssl_port,
  $aem_quickstart_source,
  $aem_license_source,
  $aem_artifacts_base,
  $aem_healthcheck_version,

  $aem_base           = '/opt',
  $aem_sample_content = false,
  $aem_jvm_mem_opts   = '-Xss4m -Xmx8192m',

  $setup_repository_volume       = false,
  $repository_volume_device      = '/dev/xvdb',
  $repository_volume_mount_point = '/mnt/ebs1',

  $aem_keystore_path     = undef,
  $aem_keystore_password = undef,
  $cert_base_url         = undef,

  $post_install_sleep_secs = 120,
  $post_stop_sleep_secs    = 120,

  $retries_max_tries          = 120,
  $retries_base_sleep_seconds = 10,
  $retries_max_sleep_seconds  = 10,

  $jvm_opts = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],

  $aem_version = '6.2',
  $aem_extras  = 'sp1_cfp3',

  $aem_debug          = false,
  $aem_id             = 'aem',
  $puppet_conf_dir    = '/etc/puppetlabs/puppet/',
) {

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  Aem_aem {
    retries_max_tries          => $retries_max_tries,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
  }

  if $setup_repository_volume {
    exec { "${aem_id}: Prepare device for the AEM repository":
      command => "mkfs -t ext4 ${repository_volume_device}",
    } -> file { $repository_volume_mount_point:
      ensure => directory,
      mode   => '0755',
    } -> mount { $repository_volume_mount_point:
      ensure   => mounted,
      device   => $repository_volume_device,
      fstype   => 'ext4',
      options  => 'nofail,defaults,noatime',
      remounts => false,
      atboot   => false,
    } -> exec { "${aem_id}: Fix repository mount permissions":
      command => "chown aem-${aem_id}:aem-${aem_id} ${repository_volume_mount_point}",
      require => User["aem-${aem_id}"],
    }
  }

  if !defined(File["${aem_base}/aem"]) {
    file { "${aem_base}/aem":
      ensure => directory,
      mode   => '0775',
    }
  }

  file { "${aem_base}/aem/${aem_id}":
    ensure => directory,
    mode   => '0775',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  }

  aem_resources::puppet_aem_resources_set_config { "${aem_id}: Set puppet-aem-resources config file":
    conf_dir => $puppet_conf_dir,
    protocol => 'http',
    host     => $aem_host,
    port     => $aem_port,
    debug    => $aem_debug,
    aem_id   => $aem_id,
  }

  aem_curator::install_aem62 { "${aem_id}: Install AEM":
    tmp_dir                 => $tmp_dir,
    run_mode                => $run_mode,
    aem_port                => $aem_port,
    aem_quickstart_source   => $aem_quickstart_source,
    aem_license_source      => $aem_license_source,
    aem_artifacts_base      => $aem_artifacts_base,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_base                => $aem_base,
    aem_sample_content      => $aem_sample_content,
    aem_jvm_mem_opts        => $aem_jvm_mem_opts,
    jvm_opts                => $jvm_opts,
    post_install_sleep_secs => $post_install_sleep_secs,
    aem_id                  => $aem_id,
  } -> aem_curator::install_aem62_sp1_cfp3 { "${aem_id}: Install extra AEM packages":
    tmp_dir            => $tmp_dir,
    aem_artifacts_base => $aem_artifacts_base,
    aem_id             => $aem_id,
  } -> aem_resources::create_system_users { "${aem_id}: Create system users":
    # Create system users and configure their usernames for password reset during provisioning
    orchestrator_password => 'orchestrator',
    replicator_password   => 'replicator',
    deployer_password     => 'deployer',
    exporter_password     => 'exporter',
    importer_password     => 'importer',
    aem_id                => $aem_id,
  } -> aem_node { "${aem_id}: Create AEM Password Reset Activator config node":
    ensure => present,
    name   => 'com.shinesolutions.aem.passwordreset.Activator',
    path   => "/apps/system/config.${run_mode}",
    type   => 'sling:OsgiConfig',
    aem_id => $aem_id,
  } -> aem_config_property { "${aem_id}: Configure system usernames for AEM Password Reset Activator to process":
    ensure           => present,
    name             => 'pwdreset.authorizables',
    type             => 'String[]',
    value            => ['admin', 'orchestrator', 'replicator', 'deployer', 'exporter', 'importer'],
    run_mode         => $run_mode,
    config_node_name => 'com.shinesolutions.aem.passwordreset.Activator',
    aem_id           => $aem_id,
  } -> aem_user { "${aem_id}: Update replication-service user permission":
    # Deny replicate permission for replication-service user to prevent agents from being published
    ensure     => has_permission,
    name       => 'replication-service',
    path       => '/home/users/system/',
    permission => {
      '/etc/replication/agents.author'  => ['replicate:false'],
      '/etc/replication/agents.publish' => ['replicate:false'],
    },
    aem_id     => $aem_id,
  } -> aem_node { "${aem_id}: Create AEM Health Check Servlet config node":
    ensure => present,
    name   => 'com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck',
    path   => "/apps/system/config.${run_mode}",
    type   => 'sling:OsgiConfig',
    aem_id => $aem_id,
  } -> aem_config_property { "${aem_id}: Configure AEM Health Check Servlet ignored bundles":
    ensure           => present,
    name             => 'bundles.ignored',
    type             => 'String[]',
    run_mode         => $run_mode,
    config_node_name => 'com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck',
    value            => [
      'org.apache.sling.jcr.webdav',
      'org.apache.sling.jcr.davex',
      'com.adobe.acs.acs-aem-commons-bundle-twitter',
    ],
    aem_id           => $aem_id,
  }

  $provisioning_steps = [
    Aem_config_property["${aem_id}: Configure AEM Health Check Servlet ignored bundles"],
    Aem_user["${aem_id}: Update replication-service user permission"],
  ]

  if $run_mode == 'author' {
    aem_resources::author_remove_default_agents { "${aem_id}: Remove default author agents":
      aem_id  => $aem_id,
      require => Aem_aem["${aem_id}: Wait until aem health check is ok"]
    }
    $all_provisioning_steps = concat(
      $provisioning_steps,
      Aem_resources::Author_remove_default_agents["${aem_id}: Remove default author agents"],
    )
  } else {
    aem_resources::publish_remove_default_agents { "${aem_id}: Remove default publish agents":
      aem_id  => $aem_id,
      require => Aem_aem["${aem_id}: Wait until aem health check is ok"]
    }
    $all_provisioning_steps = concat(
      $provisioning_steps,
      Aem_resources::Publish_remove_default_agents["${aem_id}: Remove default publish agents"],
    )
  }

  # Ensure login page is still ready after all provisioning steps and before stopping AEM.
  aem_aem { "${aem_id}: Ensure login page is ready":
    ensure  => login_page_is_ready,
    require => $all_provisioning_steps,
    aem_id  => $aem_id,
  }

  $keystore_path = pick(
    $aem_keystore_path,
    "${aem_base}/aem/${aem_id}/crx-quickstart/ssl/aem.ks",
  )

  file { dirname($keystore_path):
    ensure  => directory,
    mode    => '0770',
    owner   => "aem-${aem_id}",
    group   => "aem-${aem_id}",
    require => [
      Aem_aem["${aem_id}: Ensure login page is ready"],
    ],
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

  $x509_parts = [ 'key', 'cert' ]
  $x509_parts.each |$idx, $part| {
    ensure_resource(
      'archive',
      "${tmp_dir}/${aem_id}/aem.${part}",
      {
        'ensure' => 'present',
        'source' => "${cert_base_url}/aem.${part}",
      },
    )
  }
  $java_ks_require = $x509_parts.map |$part| {
    Archive["${tmp_dir}/${aem_id}/aem.${part}"]
  }

  java_ks { "cqse:${keystore_path}":
    ensure       => latest,
    certificate  => "${tmp_dir}/${aem_id}/aem.cert",
    private_key  => "${tmp_dir}/${aem_id}/aem.key",
    password     => $aem_keystore_password,
    trustcacerts => true,
    require      => $java_ks_require,
  } -> aem_resources::author_publish_enable_ssl { "${aem_id}: Enable SSL":
    run_mode            => $run_mode,
    port                => $aem_ssl_port,
    keystore            => $keystore_path,
    keystore_password   => $aem_keystore_password,
    keystore_key_alias  => 'cqse',
    truststore          => '/usr/java/default/jre/lib/security/cacerts',
    truststore_password => 'changeit',
    aem_id              => $aem_id,
  } -> exec { "rm -f ${aem_base}/aem/${aem_id}/aem-healthcheck-content-*.zip":
  }

  if $setup_repository_volume {
    exec { "service aem-${aem_id} stop":
      require => [
        Exec["rm -f ${aem_base}/aem/${aem_id}/aem-healthcheck-content-*.zip"],
        Mount[$repository_volume_mount_point],
      ],
    } -> exec { "${aem_id}: Wait post AEM stop":
      command => "sleep ${post_stop_sleep_secs}",
    } -> exec { "mv ${aem_base}/aem/${aem_id}/crx-quickstart/repository/* ${repository_volume_mount_point}/":
    } -> file { "${aem_base}/aem/${aem_id}/crx-quickstart/repository/":
      ensure => 'link',
      owner  => "aem-${aem_id}",
      group  => "aem-${aem_id}",
      force  => true,
      target => $repository_volume_mount_point,
    }
  }

}
