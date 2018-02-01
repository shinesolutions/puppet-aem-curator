# == Class: config::collectd
#
# Configuration AEM Java AMIs
#
# === Authors
#
# James Sinclair <james.sinclair@shinesolutions.com>
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#
class aem_curator::config_collectd (
  $proxy_protocol,
  $proxy_host,
  $proxy_port,
  $component,
  $aem_instances,
  $collectd_prefix,
) {

  if $proxy_host != '' {
    file_line { 'Set the collectd cloudwatch proxy_server_name':
      path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
      line   => "proxy_server_name = \"${proxy_protocol}://${proxy_host}\"",
      match  => '^#proxy_server_name =.*$',
      notify => Service['collectd'],
    }
    file_line { 'Set the collectd cloudwatch proxy_server_port':
      path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
      line   => "proxy_server_port = \"${proxy_port}\"",
      match  => '^#proxy_server_port =.*$',
      notify => Service['collectd'],
    }
  }

  $collectd_jmx_types_path = '/usr/share/collectd/jmx.db'
  collectd::plugin::genericjmx::mbean {
    'garbage_collector':
      object_name     => 'java.lang:type=GarbageCollector,*',
      instance_prefix => 'gc-',
      instance_from   => 'name',
      values          => [
        {
          mbean_type => 'invocations',
          table      => false,
          attribute  => 'CollectionCount',
        },
        {
          mbean_type      => 'total_time_in_ms',
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
          mbean_type => 'jmx_memory',
          table      => true,
          attribute  => 'HeapMemoryUsage',
        },
      ];
    'memory-nonheap':
      object_name     => 'java.lang:type=Memory',
      instance_prefix => 'memory-nonheap',
      values          => [
        {
          mbean_type => 'jmx_memory',
          table      => true,
          attribute  => 'NonHeapMemoryUsage',
        },
      ];
    'memory-permgen':
      object_name     => 'java.lang:type=MemoryPool,name=*Perm Gen',
      instance_prefix => 'memory-permgen',
      values          => [
        {
          mbean_type => 'jmx_memory',
          table      => true,
          attribute  => 'Usage',
        },
      ];
  }

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    collectd::plugin::genericjmx::connection { "aem-${aem_instance['aem_id']}":
      host        => "aem-${aem_instance['aem_id']}",
      service_url => "service:jmx:rmi:///jndi/rmi://localhost:${aem_instance['jmxremote_port']}/jmxrmi",
      collect     => $aem_instance['instance_prefixes'],
    }
  }

  file_line {
    'seconds_since_last_success standby status':
      ensure => present,
      line   => 'GenericJMX-standby-status-delay-seconds_since_last_success',
      path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/whitelist.conf',
  }

  if $component == 'author-standby' {
    collectd::plugin::genericjmx::mbean {
      'standby-status':
        object_name     => 'org.apache.jackrabbit.oak:*,name=Status,type=*Standby*',
        instance_prefix => 'standby-status',
        values          => [
          {
            instance_prefix => 'seconds_since_last_success',
            mbean_type      => 'delay',
            table           => false,
            attribute       => 'SecondsSinceLastSuccess',
          },
        ];
    }
  }

  file_line { 'Set Hostname for CW':
      ensure => present,
      path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
      line   => "host = \"${$collectd_prefix}\"",
      match  => '^#host',
      notify => Service['collectd'],
  }

  class { 'collectd':
    service_ensure => running,
    service_enable => true,
  }
}
