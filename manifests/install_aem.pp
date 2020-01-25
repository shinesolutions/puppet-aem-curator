# == Class: aem_curator::install_aem
#
#  Shared Resources used by other AEM modules
#
# === Parameters
#
# [*tmp_dir*]
#   A temporary directory used for staging
#
# [*run_modes*]
#   List of additional AEM run modes
#
# [*aem_port*]
#   TCP port AEM will listen on.
#
# [*aem_ssl_port*]
#   SSL port AEM will listen on.
#
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
# [*aem_osgi_configs*]
#   OSGi configurations to be present before AEM's first start.
#
# [*setup_repository_volume*]
#   Boolean that determines whether a separate volume is formatted and mounted
#   for the AEM repository.
#
# [*data_volume_device*]
#   The device for format and mount for the AEM repository.
#
# [*data_volume_mount_point*]
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
# [*aem_jvm_opts*]
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
  $aem_license_base,
  $aem_artifacts_base,
  $aem_healthcheck_version,
  $aem_host,
  $aem_port,
  $aem_ssl_port,
  $run_modes,
  $tmp_dir,
  $aem_debug_port                = undef,
  $aem_base                      = '/opt',
  $aem_debug                     = false,
  $aem_healthcheck_source        = undef,
  $aem_id                        = undef,
  $aem_type                      = undef,
  $aem_jvm_mem_opts              = '-Xss4m -Xmx8192m',
  $aem_keystore_password         = undef,
  $aem_keystore_path             = undef,
  $aem_profile                   = 'aem62_sp1_cfp3',
  $aem_sample_content            = false,
  $cert_base_url                 = undef,
  $aem_jvm_opts                  = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],
  $aem_osgi_configs              = undef,
  $post_install_sleep_secs       = 120,
  $post_stop_sleep_secs          = 120,
  $puppet_conf_dir               = '/etc/puppetlabs/puppet/',
  $data_volume_device            = '/dev/xvdb',
  $data_volume_mount_point       = '/mnt/ebs1',
  $retries_base_sleep_seconds    = 10,
  $retries_max_sleep_seconds     = 10,
  $retries_max_tries             = 120,
  $setup_repository_volume       = false,
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
      command => "mkfs -t ext4 ${data_volume_device}",
    } -> file { $data_volume_mount_point:
      ensure => directory,
      mode   => '0755',
    } -> mount { $data_volume_mount_point:
      ensure   => mounted,
      device   => $data_volume_device,
      fstype   => 'ext4',
      options  => 'nofail,defaults,noatime',
      remounts => false,
      atboot   => false,
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

  aem_curator::install_aem_profile { "${aem_id}: Install AEM profile ${aem_profile}":
    aem_artifacts_base      => $aem_artifacts_base,
    aem_license_base        => $aem_license_base,
    aem_base                => $aem_base,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_healthcheck_source  => $aem_healthcheck_source,
    aem_id                  => $aem_id,
    aem_type                => $aem_type,
    aem_jvm_mem_opts        => $aem_jvm_mem_opts,
    aem_port                => $aem_port,
    aem_debug_port          => $aem_debug_port,
    aem_profile             => $aem_profile,
    aem_sample_content      => $aem_sample_content,
    aem_ssl_port            => $aem_ssl_port,
    aem_jvm_opts            => $aem_jvm_opts,
    aem_osgi_configs        => $aem_osgi_configs,
    post_install_sleep_secs => $post_install_sleep_secs,
    run_modes               => $run_modes,
    tmp_dir                 => $tmp_dir,
  } -> aem_curator::config_aem { "${aem_id}: Configure AEM":
    aem_base              => $aem_base,
    aem_id                => $aem_id,
    aem_keystore_password => $aem_keystore_password,
    aem_keystore_path     => $aem_keystore_path,
    aem_ssl_port          => $aem_ssl_port,
    cert_base_url         => $cert_base_url,
    run_mode              => $aem_id,
    tmp_dir               => $tmp_dir
  }

  if $setup_repository_volume {
    exec { "service aem-${aem_id} stop":
      require => [
        Aem_curator::Config_aem["${aem_id}: Configure AEM"],
        Mount[$data_volume_mount_point],
      ],
    } -> exec { "${aem_id}: Wait post AEM stop":
      command => "sleep ${post_stop_sleep_secs}",
    } -> exec { "${aem_id}: Ensure AEM resource is stopped":
      command => "/opt/puppetlabs/bin/puppet resource service aem-${aem_id} ensure=stopped",
    } -> exec { "mv ${aem_base}/aem/${aem_id} ${data_volume_mount_point}/${aem_id}":
    } -> exec { "${aem_id}: Set link from ${data_volume_mount_point}/${aem_id} to ${aem_base}/aem/${aem_id}":
      command => "ln -s ${data_volume_mount_point}/${aem_id} ${aem_base}/aem/${aem_id}",
      returns => [
        '0'
      ]
    } -> exec { "${aem_id}: Fix repository mount permissions":
      command => "chown -R aem-${aem_id}:aem-${aem_id} ${data_volume_mount_point}",
    }
  } else {
    exec { "service aem-${aem_id} stop":
      require => [
        Aem_curator::Config_aem["${aem_id}: Configure AEM"],
      ],
    } -> exec { "${aem_id}: Wait post AEM stop":
      command => "sleep ${post_stop_sleep_secs}",
    } -> exec { "${aem_id}: Ensure AEM resource is stopped":
      command => "/opt/puppetlabs/bin/puppet resource service aem-${aem_id} ensure=stopped",
    }
  }

}
