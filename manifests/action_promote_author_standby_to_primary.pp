
class aem_curator::action_promote_author_standby_to_primary (
  $author_port,
  $base_dir,
  $tmp_dir,
  $aem_context_root                   = undef,
  $aem_crx_packages                   = undef,
  $aem_debug_port                     = undef,
  $aem_home_dir                       = '/opt/aem/author',
  $aem_id                             = 'author',
  $aem_username                       = $::aem_username,
  $aem_password                       = $::aem_password,
  $aem_runmodes                       = [],
  $aem_version                        = '6.2',
  $ec2_id                             = $::ec2_metadata['instance-id'],
  $jmxremote_port                     = '5982',
  $jmxremote_enable_authentication    = false,
  $jmxremote_enable_ssl               = false,
  $jmxremote_keystore_path            = undef,
  $jmxremote_keystore_password        = 'changeit',
  $jmxremote_monitoring_username      = undef,
  $jmxremote_monitoring_user_password = undef,
  $jvm_mem_opts                       = undef,
  $jvm_opts                           = undef,
  $login_ready_max_tries              = 30,
  $login_ready_base_sleep_seconds     = 15,
  $login_ready_max_sleep_seconds      = 15,
  $osgi_configs                       = undef,
  $stack_prefix                       = $::stack_prefix,
) {


  # Updating provided JVM Options with JMXRemote JVM options if port is provided
  if $jmxremote_port {
    # File path containing the JMX properties
    $jmxremote_configuration_file_path = "/etc/jmx-${aem_id}.properties"

    # Creating JMX property file with JMX configuration
    aem_curator::config_aem_jmx { "${aem_id}: Configure JMX for AEM":
      aem_id                             => $aem_id,
      jmxremote_configuration_file_path  => $jmxremote_configuration_file_path,
      jmxremote_enable_authentication    => $jmxremote_enable_authentication,
      jmxremote_enable_ssl               => $jmxremote_enable_ssl,
      jmxremote_port                     => $jmxremote_port,
      jmxremote_keystore_password        => $jmxremote_keystore_password,
      jmxremote_keystore_path            => $jmxremote_keystore_path,
      jmxremote_monitoring_username      => $jmxremote_monitoring_username,
      jmxremote_monitoring_user_password => $jmxremote_monitoring_user_password,
    }
    # Setting JVM Option with the patah to the JMX property file
    $_jvm_opts_list = concat([$jvm_opts], ["-Dcom.sun.management.config.file=${jmxremote_configuration_file_path}"])
    $_jvm_opts = $_jvm_opts_list.join(' ')
  } else {
    $_jvm_opts = $jvm_opts
  }

  class { 'aem_curator::config_collectd':
    component       => 'author-primary',
    collectd_prefix => "${stack_prefix}-author-primary",
    ec2_id          => $ec2_id},
    jmx_user          => $jmxremote_monitoring_username,
    jmx_user_password => $jmxremote_monitoring_user_password,
  }

  exec { 'systemctl stop aem-author':
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
    start  => 'systemctl start aem-author',
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
