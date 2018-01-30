#== Class: aem_curator::config_author_primary
# Configuration AEM Author
#
# === Parameters
# [*jvm_mem_opts*]
#   User defined JVM Memory options to be passed to the AEM Author
#
# [*jmxremote_port*]
#   User defined Port on which JMXRemote is listening
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#

File {
  backup => false,
}

class aem_curator::config_author_primary (
  $aem_password_reset_source,
  $aem_password_reset_version,
  $author_port,
  $author_protocol,
  $credentials_file,
  $crx_quickstart_dir,
  $enable_crxde,
  $enable_daily_export_cron,
  $enable_default_passwords,
  $enable_hourly_live_snapshot_cron,
  $enable_offline_compaction_cron,
  $puppet_conf_dir,
  $tmp_dir,
  $aem_id                  = 'author',
  $aem_version             = '6.2',
  $delete_repository_index = false,
  $jmxremote_port          = '59182',
  $jvm_mem_opts            = undef,
  $run_mode                = 'author',
) {

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  if $delete_repository_index {

    file { "${crx_quickstart_dir}/repository/index/":
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
      before  => Service['aem-author'],
    }

  }

  if $jvm_mem_opts {
    file_line { "${aem_id}: Set JVM memory opts":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_MEM_OPTS='${jvm_mem_opts}'",
      match  => '^JVM_MEM_OPTS',
    }
  }

  if $jmxremote_port {
    file_line { "${aem_id}: enable JMXRemote":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${jmxremote_port} -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=true -Djava.rmi.server.hostname=localhost\"",
      after  => '^JVM_OPTS',
      notify => Service['aem-author'],
    }
  }

  file { "${crx_quickstart_dir}/install/":
    ensure => directory,
    mode   => '0775',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  } -> archive { "${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip":
    ensure => present,
    source => $aem_password_reset_source,
  } -> aem_resources::puppet_aem_resources_set_config { 'Set puppet-aem-resources config file for author-primary':
    conf_dir => $puppet_conf_dir,
    protocol => $author_protocol,
    host     => 'localhost',
    port     => $author_port,
    debug    => false,
    aem_id   => $aem_id,
  } -> aem_resources::author_primary_set_config { 'Set author-primary config':
    crx_quickstart_dir => $crx_quickstart_dir,
    aem_version        => $aem_version,
  } -> service { 'aem-author':
    ensure => 'running',
    enable => true,
  } -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure                     => login_page_is_ready,
    retries_max_tries          => 120,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
    aem_id                     => $aem_id,
  } -> aem_bundle { "${aem_id}: Stop webdav bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.webdav',
    aem_id => $aem_id,
  } -> aem_bundle { "${aem_id}: Stop davex bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.davex',
    aem_id => $aem_id,
  } -> aem_curator::config_aem_crxde { "${aem_id}: Configure CRXDE":
    aem_id       => $aem_id,
    enable_crxde => $enable_crxde,
    run_mode     => $run_mode,
  } -> aem_aem { "${aem_id}: Remove all agents":
    ensure   => all_agents_removed,
    run_mode => 'author',
    aem_id   => $aem_id,
  } -> aem_package { "${aem_id}: Remove password reset package":
    ensure  => absent,
    name    => 'aem-password-reset-content',
    group   => 'shinesolutions',
    version => $aem_password_reset_version,
    aem_id  => $aem_id,
  } -> aem_curator::config_aem_system_users { "${aem_id}: Configure system users":
    aem_id                   => $aem_id,
    credentials_hash         => $credentials_hash,
    enable_default_passwords => $enable_default_passwords,
  } -> file { "${crx_quickstart_dir}/install/aem-password-reset-content-${aem_password_reset_version}.zip":
    ensure => absent,
  }

  if $::proxy_host != '' {
    file_line { 'Set the collectd cloudwatch proxy_server_name':
      path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
      line   => "proxy_server_name = \"${::proxy_protocol}://${::proxy_host}\"",
      match  => '^#proxy_server_name =.*$',
      notify => Service['collectd'],
    }
  }

  if $::proxy_host != '' {
    file_line { 'Set the collectd cloudwatch proxy_server_port':
      path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
      line   => "proxy_server_port = \"${::proxy_port}\"",
      match  => '^#proxy_server_port =.*$',
      notify => Service['collectd'],
    }
  }

  collectd::plugin::genericjmx::mbean {
    'garbage_collector':
      object_name     => 'java.lang:type=GarbageCollector,*',
      instance_prefix => 'gc-',
      instance_from   => 'name',
      values          => [
        {
          'type'    => 'invocations',
          table     => false,
          attribute => 'CollectionCount',
        },
        {
          'type'          => 'total_time_in_ms',
          instance_prefix => 'collection_time',
          table           => false,
          attribute       => 'CollectionTime',
        },
      ];
    'memory-heap':
      object_name     => 'java.lang:type=Memory',
      instance_prefix => 'memory-heap',
      values          => [
        {
          'type'    => 'jmx_memory',
          table     => true,
          attribute => 'HeapMemoryUsage',
        },
      ];
    'memory-nonheap':
      object_name     => 'java.lang:type=Memory',
      instance_prefix => 'memory-nonheap',
      values          => [
        {
          'type'    => 'jmx_memory',
          table     => true,
          attribute => 'NonHeapMemoryUsage',
        },
      ];
    'memory-permgen':
      object_name     => 'java.lang:type=MemoryPool,name=*Perm Gen',
      instance_prefix => 'memory-permgen',
      values          => [
        {
          'type'    => 'jmx_memory',
          table     => true,
          attribute => 'Usage',
        },
      ];
  }

  collectd::plugin::genericjmx::connection { 'aem':
    host        => $::fqdn,
    service_url => "service:jmx:rmi:///jndi/rmi://localhost:${jmxremote_port}/jmxrmi",
    collect     => [ 'standby-status' ],
  }

  class { '::collectd':
    service_ensure => running,
    service_enable => true,
  }

}
