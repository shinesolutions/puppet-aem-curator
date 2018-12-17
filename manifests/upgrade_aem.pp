# == Define: aem_curator::upgrade_aem
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

define aem_curator::upgrade_aem (
  $base_dir,
  $tmp_dir,
  $aem_base                       = '/opt/aem',
  $aem_id                         = 'aem',
  $aem_port                       = '4502',
  $post_upgrade_sleep_secs        = '600',
  $aem_upgrade_version            = '6.4',
  $login_ready_max_tries          = '120',
  $login_ready_base_sleep_seconds = '5',
  $login_ready_max_sleep_seconds  = '10',
) {

  file { $tmp_dir:
    ensure => directory,
    before => Service["aem-${aem_id}"]
  } -> file { "${tmp_dir}/${aem_id}":
    ensure => directory,
    mode   => '0700',
  }

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  # Set parameter for AEM Upgrade
  $home = "${aem_base}/aem/${aem_id}"
  $crx_dir = "${home}/crx-quickstart"
  $aem_tools_dir = "${base_dir}/aem-tools"

  exec { "${aem_id}: Ensure AEM resource is stopped":
    command => "/opt/puppetlabs/bin/puppet resource service aem-${aem_id} ensure=stopped",
    before  => Exec["${aem_id}: Upgrade AEM ${aem_id} to version ${aem_upgrade_version}"]
  }

  exec { "${aem_id}: Upgrade AEM ${aem_id} to version ${aem_upgrade_version}":
    command => "${aem_tools_dir}/upgrade/upgrade-aem-script.sh ${aem_id} ${aem_base} ${aem_upgrade_version} ${$aem_port} ${post_upgrade_sleep_secs}",
  } -> service { "aem-${aem_id}":
    ensure => 'running',
    enable => true,
  } -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  }

  exec { "${aem_id}: Delete temp directory ${tmp_dir}/${aem_id}":
    command => "rm -fr ${tmp_dir}/${aem_id}",
    require => Exec["${aem_id}: Upgrade AEM ${aem_id} to version ${aem_upgrade_version}"]
  }
}
