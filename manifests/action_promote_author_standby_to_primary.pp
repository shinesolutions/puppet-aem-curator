File {
  backup => false,
}

class aem_curator::action_promote_author_standby_to_primary (
  $author_port,
  $base_dir,
  $tmp_dir,
  $aem_context_root               = undef,
  $aem_crx_packages               = undef,
  $aem_debug_port                 = undef,
  $aem_home_dir                   = '/opt/aem/author',
  $aem_id                         = 'author',
  $aem_username                   = $::aem_username,
  $aem_password                   = $::aem_password,
  $aem_runmodes                    = [],
  $aem_version                    = '6.2',
  $jmxremote_port                 = '5982',
  $jvm_mem_opts                   = undef,
  $jvm_opts                       = undef,
  $login_ready_max_tries          = 30,
  $login_ready_base_sleep_seconds = 15,
  $login_ready_max_sleep_seconds  = 15,
  $osgi_configs                   = undef,
) {


  # Updating provided JVM Options with JMXRemote JVM options if port is provided
  if $jmxremote_port {
    $jmxremote_options = [
      '-Dcom.sun.management.jmxremote',
      "-Dcom.sun.management.jmxremote.port=${jmxremote_port}",
      '-Dcom.sun.management.jmxremote.authenticate=false',
      '-Dcom.sun.management.jmxremote.ssl=false',
      '-Dcom.sun.management.jmxremote.local.only=true',
      '-Djava.rmi.server.hostname=localhost'
    ]
    $_jvm_opts_list = concat([$jvm_opts], $jmxremote_options)
    $_jvm_opts = $_jvm_opts_list.join(' ')
  } else {
    $_jvm_opts = $jvm_opts
  }

  exec { 'service aem-author stop':
    cwd  => $tmp_dir,
    path => ['/usr/bin', '/usr/sbin', '/sbin'],
  } -> exec { 'crx-process-quited.sh 24 5':
    cwd  => $tmp_dir,
    path => ["${base_dir}/aem-tools", '/usr/bin', '/opt/puppetlabs/bin/', '/bin'],
  } -> aem_resources::author_primary_set_config {'Promote author-primary':
    aem_context_root => $aem_context_root,
    aem_crx_packages => $aem_crx_packages,
    aem_debug_port   => $aem_debug_port,
    aem_home_dir     => $aem_home_dir,
    aem_id           => $aem_id,
    aem_port         => $author_port,
    aem_runmodes     => $aem_runmodes,
    aem_user         => "aem-${aem_id}",
    aem_user_group   => "aem-${aem_id}",
    aem_version      => $aem_version,
    jvm_mem_opts     => $jvm_mem_opts,
    jvm_opts         => $_jvm_opts,
    osgi_configs     => $osgi_configs
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
