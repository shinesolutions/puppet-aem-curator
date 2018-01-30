#== Class: aem_curator::config_author_standby
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

class aem_curator::config_author_standby (
  $author_port,
  $author_protocol,
  $author_primary_host,
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

  aem_resources::puppet_aem_resources_set_config { 'Set puppet-aem-resources config file for author-primary':
    conf_dir => $puppet_conf_dir,
    protocol => $author_protocol,
    host     => 'localhost',
    port     => $author_port,
    debug    => false,
    aem_id   => $aem_id,
  } -> aem_resources::author_standby_set_config { 'Set author-standby config':
    crx_quickstart_dir => $crx_quickstart_dir,
    primary_host       => $author_primary_host,
    aem_version        => $aem_version,
  } -> service { 'aem-author':
    ensure => 'running',
    enable => true,
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
    'standby-status':
      object_name     => 'org.apache.jackrabbit.oak:*,name=Status,type=*Standby*',
      instance_prefix => "${::stack_prefix}-standby-status",
      values          => [
        {
          instance_prefix => 'seconds_since_last_success',
          mbean_type      => 'delay',
          table           => false,
          attribute       => 'SecondsSinceLastSuccess',
        },
      ];
  }

  file_line { 'seconds_since_last_success standby status':
    ensure => present,
    line   => "GenericJMX-${::stack_prefix}-standby-status-delay-seconds_since_last_success",
    path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/whitelist.conf',
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
