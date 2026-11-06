# == Class: config::collectd
#
# Configuration AEM Java AMIs
#
# [*jmx_user*]
#  JMX Username of the Monitoring user
#  default: undef
#
# [*jmx_user_password*]
#  JMX User password of the monitoring user
#  default: undef
#
# [*jmx_truststore_path*]
#  Trust store the GenericJMX plugin's JVM verifies AEM's JMX SSL certificate
#  with, usually AEM's JMX keystore. Leave it undef to use the JVM's default
#  cacerts, which only works when the JMX certificate was imported into the
#  cacerts of the JVM collectd's java plugin loads.
#  default: undef
#
# [*jmx_truststore_password*]
#  Password of the trust store.
#  default: changeit
#
# [*collectd_cloudwatch*]
#  Whether the AMI publishes collectd's metrics with the awslabs
#  collectd-cloudwatch plugin, whose plugin.conf and whitelist.conf this class
#  then sets up. AMIs where collectd sends its metrics to the unified
#  CloudWatch agent instead (e.g. Amazon Linux 2023) don't have the plugin;
#  there only the standby sync delay is sent to the agent, which adds the
#  stack's dimensions (see config_cloudwatch_agent).
#  default: true when /opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf exists
#
# === Authors
#
# James Sinclair <james.sinclair@shinesolutions.com>
#
# === Copyright
#
# Copyright © 2021 Shine Solutions Group Group, unless otherwise noted.
#
class aem_curator::config_collectd (
  $proxy_protocol,
  $proxy_enabled,
  $proxy_host,
  $proxy_port,
  $component,
  $aem_instances,
  $collectd_prefix,
  $ec2_id,
  $jmx_user                    = undef,
  $jmx_user_password           = undef,
  $jmx_truststore_path         = undef,
  $jmx_truststore_password     = 'changeit',
  Boolean $collectd_cloudwatch = find_file('/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf') =~ NotUndef,
) {

  if $collectd_cloudwatch and $proxy_enabled == true {
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
      instance_from   => ['name'],
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
      user        => $jmx_user,
      password    => $jmx_user_password,
    }
  }

  if $collectd_cloudwatch {
    file_line {
      'seconds_since_last_success standby status':
        ensure => present,
        line   => 'GenericJMX-standby-status-delay-seconds_since_last_success',
        path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/whitelist.conf',
    }
  }

  # collectd-cloudwatch publishes only the metrics in its whitelist.conf, but
  # the unified CloudWatch agent publishes every metric collectd sends it. So
  # without collectd-cloudwatch, write only the standby sync delay (the
  # GenericJMX metric whitelisted above) to the network plugin, which sends it
  # to the agent, and drop everything else.
  unless $collectd_cloudwatch {
    collectd::plugin::filter::chain { 'PostChain':
      target => 'stop',
    }
    collectd::plugin::filter::rule { 'standby-status':
      chain => 'PostChain',
    }
    collectd::plugin::filter::match { 'standby-status':
      chain   => 'PostChain',
      rule    => 'standby-status',
      plugin  => 'regex',
      options => {
        'Plugin'         => '^GenericJMX$',
        'PluginInstance' => '^standby-status$',
      },
    }
    collectd::plugin::filter::target { 'standby-status-network':
      chain   => 'PostChain',
      rule    => 'standby-status',
      plugin  => 'write',
      options => {
        'Plugin' => 'network',
      },
    }
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

  if $collectd_cloudwatch {
    file_line { 'Set Hostname for CW':
        ensure => present,
        path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
        line   => "host = \"${$ec2_id}\"",
        match  => '^#host',
        notify => Service['collectd'],
    }

    file_line { 'Push constant value to CW as a metric':
        ensure => present,
        path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
        line   => 'push_constant = True',
        match  => '^push_constant',
        notify => Service['collectd'],
    }

    file_line { 'Push constant dimension value':
        ensure => present,
        path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
        line   => "constant_dimension_value = \"${$collectd_prefix}\"",
        match  => '^constant_dimension_value',
        notify => Service['collectd'],
    }
  }

  # collectd class is used here to process the genericjmx plugin
  # the package and repo managements are disabled in order to avoid provisioning
  # steps that require outbound connection
  # collectd package itself is expected to have been installed at this stage
  class { 'collectd':
    manage_package => false,
    manage_repo    => false,
    service_ensure => running,
    service_enable => true,
  }

  $truststore_jvmargs = $jmx_truststore_path ? {
    undef   => [],
    default => [
      "-Djavax.net.ssl.trustStore=${jmx_truststore_path}",
      "-Djavax.net.ssl.trustStorePassword=${jmx_truststore_password}",
    ],
  }

  class { 'collectd::plugin::genericjmx':
    jvmarg         => [
      '-Djdk.rmi.ssl.client.enableEndpointIdentification=false',
    ] + $truststore_jvmargs,
    manage_package => false,
  }

}
