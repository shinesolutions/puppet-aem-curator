File {
  backup => false,
}

class aem_curator::action_promote_author_standby_to_primary (
  $base_dir,
  $tmp_dir,
  $aem_home_dir                   = '/opt/aem/author',
  $aem_id                         = 'author',
  $aem_username                   = $::aem_username,
  $aem_password                   = $::aem_password,
  $aem_version                    = '6.2',
  $login_ready_max_tries          = 30,
  $login_ready_base_sleep_seconds = 15,
  $login_ready_max_sleep_seconds  = 15,
  $osgi_configs                   = undef,
) {

  exec { 'service aem-author stop':
    cwd  => $tmp_dir,
    path => ['/usr/bin', '/usr/sbin', '/sbin'],
  } -> exec { 'crx-process-quited.sh 24 5':
    cwd  => $tmp_dir,
    path => ["${base_dir}/aem-tools", '/usr/bin', '/opt/puppetlabs/bin/', '/bin'],
  } -> aem_resources::author_primary_set_config {'Promote author-primary':
    crx_quickstart_dir => '/opt/aem/author/crx-quickstart',
    aem_id             => $aem_id,
    aem_version        => $aem_version,
    aem_user           => "aem-${aem_id}",
    aem_user_group     => "aem-${aem_id}",
    aem_home_dir       => $aem_home_dir,
    osgi_configs       => $osgi_configs,
  } -> class { 'aem_curator::config_logrotate':
  } -> service { 'aem-author':
    ensure => 'running',
    enable => true,
  } -> aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    aem_username               => $aem_username,
    aem_password               => $aem_password,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
  }
}

include promote_author_standby_to_primary
