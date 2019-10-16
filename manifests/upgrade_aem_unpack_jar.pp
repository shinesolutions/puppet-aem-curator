# == Class: aem_curator::upgrade_unpack_aem_jar
#
#  Manifest to download and unpack the AEM Jar file for preperate the upgrade
#
# === Parameters
#
# [*aem_artifacts_base*]
#   URLs (s3://, http:// or file://) for the AEM jar, license and package
#   files.
#
# [*aem_base*]
#   Base directory for installing AEM.
#
# [*aem_id*]
#   The AEM role to install. Should be 'publish' or 'author'.
#
# [*aem_port*]
#   TCP port AEM will listen on.
#
# [*enable_backup*]
#   Boolean to enable backup before unpacking AEM Jar file
#
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
# [*upgrade_version*]
#   AEM Version number to upgrade to i.e. 6.2, 6.3, 6.4 etc. ...
# === Authors
#
#
# === Copyright
#
# Copyright © 2018 Shine Solutions Group, unless otherwise noted.
#

define aem_curator::upgrade_aem_unpack_jar (
  $aem_artifacts_base,
  $aem_base                   = '/opt/aem',
  $aem_id                     = 'aem',
  $aem_password               = undef,
  $aem_username               = undef,
  $aem_port                   = '4502',
  $enable_backup              = false,
  $post_stop_sleep_secs       = 120,
  $retries_base_sleep_seconds = 10,
  $retries_max_sleep_seconds  = 10,
  $retries_max_tries          = 120,
  $tmp_dir                    = '/tmp',
  $upgrade_version            = '6.4',
  $puppet_binary              = '/opt/puppetlabs/bin/puppet',
) {

  validate_bool($enable_backup)

  file { $tmp_dir:
    ensure => directory,
    before => Aem_aem["${aem_id}: Remove all agents"]
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
  $aem_jar_path = "${home}/aem-${aem_id}-${aem_port}.jar"
  $aem_jar_source = "${aem_artifacts_base}/AEM_${upgrade_version}_Quickstart.jar"


  if $enable_backup {
    file { "${home}/backup":
      ensure => directory,
      before => Aem_aem["${aem_id}: Remove all agents"]
    } -> exec { "${aem_id}: Create Backup of ${home}/*.jar in ${home}/backup/":
      command => "cp -r ${home}/*.jar ${home}/backup/",
    } -> exec { "${aem_id}: Create Backup of ${crx_dir} in ${home}/backup/":
      command => "cp -r ${crx_dir} ${home}/backup/",
    }
  }

  aem_aem { "${aem_id}: Remove all agents":
    ensure       => all_agents_removed,
    aem_id       => $aem_id,
    run_mode     => $aem_id,
    aem_username => $aem_username,
    aem_password => $aem_password,
  } -> service { "aem-${aem_id}":
    ensure => 'stopped'
  } -> exec { "${aem_id}: Wait post AEM stop":
    command => "sleep ${post_stop_sleep_secs}",
  } -> exec { "${aem_id}: Ensure AEM resource is stopped":
    command => "${puppet_binary} resource service aem-${aem_id} ensure=stopped",
  } -> exec { "${aem_id}: remove old AEM JAR file":
    command => "rm -f ${aem_jar_path}",
  } -> exec { "${aem_id}: remove all old AEM Quickstart Standalone JAR files":
    command => "rm -f ${crx_dir}/app/cq-quickstart-*-standalone-quickstart.jar",
  } -> archive { $aem_jar_path:
    ensure  => present,
    source  => $aem_jar_source,
    cleanup => false,
  } -> file { $aem_jar_path:
    ensure => file,
    mode   => '0775',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  } -> exec { "${aem_id}: Unpack ${aem_jar_path}":
    command => "java -jar ${aem_jar_path} -b ${home} -unpack",
  } -> exec { "${aem_id}: Correct permissions for ${$crx_dir}":
    command => "chown -R aem-${aem_id}:aem-${aem_id} ${$crx_dir}",
  }

  exec { "${aem_id}: Delete temp directory ${tmp_dir}/${aem_id}":
    command => "rm -fr ${tmp_dir}/${aem_id}",
    require => Exec["${aem_id}: Correct permissions for ${$crx_dir}"]
  }
}
