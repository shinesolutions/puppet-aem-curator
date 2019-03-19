File {
  backup => false,
}

class aem_curator::action_promote_author_standby_to_primary (
  $base_dir,
  $tmp_dir,
  $crx_quickstart_dir,
  $aem_version                  = '6.2',
  $enable_launchpad_dir_cleanup = false,
) {

  if $enable_launchpad_dir_cleanup {
    file { "${crx_quickstart_dir}/launchpad/":
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
      before  => Service['aem-author'],
    }
  }

  exec { 'service aem-author stop':
    cwd  => $tmp_dir,
    path => ['/usr/bin', '/usr/sbin', '/sbin'],
  } -> exec { 'crx-process-quited.sh 24 5':
    cwd  => $tmp_dir,
    path => ["${base_dir}/aem-tools", '/usr/bin', '/opt/puppetlabs/bin/', '/bin'],
  } -> aem_resources::author_primary_set_config {'Promote author-primary':
    crx_quickstart_dir => "${crx_quickstart_dir}",
    aem_version        => $aem_version,
  } -> class { 'aem_curator::config_logrotate':
  } -> service { 'aem-author':
    ensure => 'running',
    enable => true,
  } -> aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => 30,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  }
}

include promote_author_standby_to_primary
