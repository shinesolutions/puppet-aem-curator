# == Define: aem_curator::upgrade_aem
#
#  Shared Resources used by other AEM modules
#
# === Parameters
#
# [*aem_base*]
#   Base directory for installing AEM.
#
# [*aem_id*]
#   AEM instance id e.g. author or publish.
#
# [*aem_port*]
#   AEM instance port to start the AEM instance to run the AEM Upgrade
#
# [*aem_upgrade_version*]
#   AEM version to upgrade to e.g. 6.4
#
# [*base_dir*]
#   Base directory e.g. /opt/shinesolutions
#
# [*post_upgrade_sleep_secs*]
#   Post upgrade sleep timer in seconds
#
# [*tmp_dir*]
#   A temporary directory used for staging
#
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
  $aem_base                = '/opt/aem',
  $aem_id                  = 'aem',
  $aem_port                = '4502',
  $post_upgrade_sleep_secs = '600',
  $aem_upgrade_version     = '6.4',
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
  }

  exec { "${aem_id}: Delete temp directory ${tmp_dir}/${aem_id}":
    command => "rm -fr ${tmp_dir}/${aem_id}",
    require => Exec["${aem_id}: Upgrade AEM ${aem_id} to version ${aem_upgrade_version}"]
  }
}
