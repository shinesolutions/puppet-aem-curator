# == Class: aem_curator::upgrade_repo_migration
#
#  Manifest to run the repository migration as preperation for the upgrade.
#
# === Parameters
# [*aem_base*]
#   Base directory for installing AEM.
#
# [*aem_id*]
#   The AEM role to install. Should be 'publish' or 'author'.
#
# [*aem_port*]
#   TCP port AEM will listen on.
# [*post_stop_sleep_secs*]
#   Seconds to sleep after AEM was stopped
#
# [*retries_max_tries*]
#   Maximum retries for module aem_aem
#
# [*retries_base_sleep_seconds*]
#   retries base sleep in second for module aem_aem
#
# [*retries_max_sleep_seconds*]
#   retries max sleep in second for module aem_aem
#
# [*tmp_dir*]
#   A temporary directory used for staging
#
# [*source_crx2oak*]
#   URLs (s3://, http:// or file://) for the CRX2OAK jar
#
# === Authors
#
#
# === Copyright
#
# Copyright © 2018 Shine Solutions Group, unless otherwise noted.
#

define aem_curator::upgrade_repo_migration (
  $aem_port                   = '4502',
  $aem_id                     = 'aem',
  $aem_base                   = '/opt/aem',
  $tmp_dir                    = '/tmp',
  $retries_base_sleep_seconds = 10,
  $retries_max_sleep_seconds  = 10,
  $retries_max_tries          = 120,
  $source_crx2oak             = undef,
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

  Aem_aem {
    retries_max_tries          => $retries_max_tries,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
  }

  $home = "${aem_base}/${aem_id}"
  $crx_dir = "${home}/crx-quickstart"
  $crx2oak_path = "$crx_dir/opt/extensions/crx2oak.jar"
  $aem_jar_path = "${home}/aem-${aem_id}-${aem_port}.jar"

  service { "aem-${aem_id}":
    ensure => 'stopped'
  } -> exec { "${aem_id}: Ensure AEM resource is stopped":
    command => "/opt/puppetlabs/bin/puppet resource service aem-${aem_id} ensure=stopped",
  }

  if $source_crx2oak {
    file { $crx2oak_path:
      ensure => absent,
      before => Exec["${aem_id}: Executing repository migration"]
    } -> archive { $crx2oak_path:
      ensure  => present,
      source  => $source_crx2oak,
      cleanup => false,
    } -> exec { "${aem_id}: Set permissions for ${$crx2oak_path}":
      command => "chown aem-${aem_id}:aem-${aem_id} ${$crx2oak_path}",
    }
  }

  exec { "${aem_id}: Executing repository migration":
    command => "java -Xmx4096m -jar ${aem_jar_path} -v -x crx2oak -xargs -- --load-profile segment-no-ds",
    cwd     => "$home",
    require => Exec["${aem_id}: Ensure AEM resource is stopped"]
  } -> exec { "${aem_id}: Fix ${$crx_dir}/repository/ permissions":
    command => "chown -R aem-${aem_id}:aem-${aem_id} ${$crx_dir}/repository/",
  }

  exec { "${aem_id}: Delete temp directory ${tmp_dir}/${aem_id}":
    command => "rm -fr ${tmp_dir}/${aem_id}",
    require => Exec["${aem_id}: Fix ${$crx_dir}/repository/ permissions"]
  }
}
