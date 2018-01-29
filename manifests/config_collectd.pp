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
) {

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
}
