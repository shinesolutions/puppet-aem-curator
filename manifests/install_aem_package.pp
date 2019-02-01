# == Class: aem_curator::aem_install_package
#
#  Download and install an AEM package.
#
# === Parameters
#
#   The AEM package group.
#
# [*aem_role*]
#   The AEM role to install. Should be 'publish' or 'author'.
#
# [*artifacts_base*]
#   The base URL for downloading the artifact.
#
# [*file_name*]
#   The file name of the artifact zip. Default is ${package_name}-${version}.zip
#
# [*version*]
#   The AEM package version. Used to generate *file_name* and passed to
#   aem_package resource.
#
# [*group*]
# [*replicate*]
# [*activate*]
# [*force*]
#   Passed directly to the aem_package resource.
#
# [*restart*]
#   Boolean which controls whether to restart AEM after installing the package.
#
# [*tmp_dir*]
#   Temporary directory for storing files. Default is '/tmp/aem_install_tmp'.
#
# [*post_install_sleep_secs*]
#   Number of seconds to sleep for after installing the package. Default 120.
#
# [*post_restart_sleep_secs*]
#   Number of seconds to sleep for after restarting AEM. Default 120.
#
# [*post_login_page_ready_sleep*]
#   Number of seconds to sleep for after login page becomes ready. Default 0.
#
# [*retries_max_tries*]
# [*retries_base_sleep_seconds*]
# [*retries_max_sleep_seconds*]
#   Passed directly to the aem_aem resource when waiting for login page to
#   become ready.
#
# === Authors
#
# James Sinclair <james.sinclair@shinesolutions.com>
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#
define aem_curator::install_aem_package (
  $artifacts_base,
  $package_group,
  $package_name,
  $package_version,
  $activate                    = false,
  $aem_id                      = 'aem',
  $file_name                   = '',
  $force                       = true,
  $post_install_sleep_secs     = 120,
  $post_login_page_ready_sleep = 0,
  $post_restart_sleep_secs     = 120,
  $replicate                   = false,
  $restart                     = false,
  $retries_base_sleep_seconds  = 10,
  $retries_max_sleep_seconds   = 10,
  $retries_max_tries           = 120,
  $tmp_dir                     = '/tmp/shinesolutions/puppet-aem-curator',
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

  $local_file_name = "${package_name}-${package_version}.zip"
  $url_file_name = pick($file_name, $local_file_name)

  $local_file_path = "${tmp_dir}/${aem_id}/${local_file_name}"

  archive { $local_file_path:
    ensure  => present,
    source  => "${artifacts_base}/${url_file_name}",
    cleanup => false,
    require => File["${tmp_dir}/${aem_id}"],
  } -> aem_aem { "${aem_id}: Wait until CRX Package Manager is ready before install ${package_name}":
    ensure => aem_package_manager_is_ready,
    aem_id => $aem_id,
  } -> aem_package { "${aem_id}: Install ${package_name}":
    ensure    => present,
    name      => $package_name,
    group     => $package_group,
    version   => $package_version,
    path      => "${tmp_dir}/${aem_id}",
    replicate => $replicate,
    activate  => $activate,
    force     => $force,
    aem_id    => $aem_id,
  } -> exec { "${aem_id}: Wait post install of ${package_name}":
    command => "sleep ${post_install_sleep_secs}",
  }

  if $restart {
    exec { "${aem_id}: Wait pre stop with ${package_name}":
      command => 'sleep 120',
    } -> aem_aem { "${aem_id}: Wait for login page before restart ${package_name}":
      ensure  => login_page_is_ready,
      require => Exec["${aem_id}: Wait post install of ${package_name}"],
      aem_id  => $aem_id,
    } -> exec { "${aem_id}: Wait post login page before restart for ${package_name}":
      command => "sleep ${post_login_page_ready_sleep}",
    } -> aem_aem { "${aem_id}: Wait until aem health check is ok before restart ${package_name}":
      ensure => aem_health_check_is_ok,
      tags   => 'deep',
      aem_id => $aem_id,
    } -> exec { "${aem_id}: Stop post install of ${package_name}":
      command => "service aem-${aem_id} stop",
    } -> exec { "${aem_id}: Wait post stop with ${package_name}":
      command => 'sleep 120',
    } -> exec { "${aem_id}: Start post install of ${package_name}":
      command => "service aem-${aem_id} start",
    } -> exec { "${aem_id}: Wait post start with ${package_name}":
      command => "sleep ${post_restart_sleep_secs}",
    }
    $restart_exec = [Exec["${aem_id}: Wait post start with ${package_name}"]]
  } else {
    $restart_exec = []
  }

  aem_aem { "${aem_id}: Wait for login page post ${package_name}":
    ensure  => login_page_is_ready,
    require => [Exec["${aem_id}: Wait post install of ${package_name}"]] + $restart_exec,
    aem_id  => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok post ${package_name}":
    ensure => aem_health_check_is_ok,
    tags   => 'deep',
    aem_id => $aem_id,
  } -> exec { "${aem_id}: Wait post login page for ${package_name}":
    command => "sleep ${post_login_page_ready_sleep}",
  }
}
