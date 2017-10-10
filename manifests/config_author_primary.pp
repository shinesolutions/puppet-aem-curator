File {
  backup => false,
}

class aem_curator::config_author_primary (
  $base_dir,
  $tmp_dir,
  $puppet_conf_dir,
  $crx_quickstart_dir,
  $author_protocol,
  $author_port,
  $aem_repo_device,
  $credentials_file,

  $enable_offline_compaction_cron,
  $enable_daily_export_cron,
  $enable_hourly_live_snapshot_cron,

  $delete_repository_index = false,
  $aem_id = 'author-primary',
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

  file { "${crx_quickstart_dir}/install/":
    ensure => directory,
    mode   => '0775',
    owner  => 'aem',
    group  => 'aem',
  }
  -> archive { "${crx_quickstart_dir}/install/aem-password-reset-content-${::aem_password_reset_version}.zip":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/aem-password-reset-content-${::aem_password_reset_version}.zip",
  }
  -> class { 'aem_resources::puppet_aem_resources_set_config':
    conf_dir => $puppet_conf_dir,
    protocol => $author_protocol,
    host     => 'localhost',
    port     => $author_port,
    debug    => false,
    aem_id   => $aem_id,
  }
  -> class { 'aem_resources::author_primary_set_config':
    crx_quickstart_dir => $crx_quickstart_dir,
  }
  -> service { 'aem-author':
    ensure => 'running',
    enable => true,
  }
  -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure                     => login_page_is_ready,
    retries_max_tries          => 120,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
    aem_id                     => $aem_id,
  }
  -> aem_bundle { "${aem_id}: Stop webdav bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.webdav',
    aem_id => $aem_id,
  }
  -> aem_bundle { "${aem_id}: Stop davex bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.davex',
    aem_id => $aem_id,
  }
  -> aem_aem { "${aem_id}: Remove all agents":
    ensure   => all_agents_removed,
    run_mode => 'author',
    aem_id   => $aem_id,
  }
  -> aem_package { "${aem_id}: Remove password reset package":
    ensure  => absent,
    name    => 'aem-password-reset-content',
    group   => 'shinesolutions',
    version => $::aem_password_reset_version,
    aem_id  => $aem_id,
  }
  -> class { 'aem_resources::change_system_users_password':
    orchestrator_new_password => $credentials_hash['orchestrator'],
    replicator_new_password   => $credentials_hash['replicator'],
    deployer_new_password     => $credentials_hash['deployer'],
    exporter_new_password     => $credentials_hash['exporter'],
    importer_new_password     => $credentials_hash['importer'],
    aem_id                    => $aem_id,
  }
  -> aem_user { "${aem_id}: Set admin password for current stack":
    ensure       => password_changed,
    name         => 'admin',
    path         => '/home/users/d',
    old_password => 'admin',
    new_password => $credentials_hash['admin'],
    aem_id       => $aem_id,
  }
  -> file { "${crx_quickstart_dir}/install/aem-password-reset-content-${::aem_password_reset_version}.zip":
    ensure => absent,
  }

  file_line { 'Set the collectd cloudwatch proxy_server_name':
    path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
    line   => "proxy_server_name = \"${::proxy_protocol}://${::proxy_host}\"",
    match  => '^#proxy_server_name =.*$',
    notify => Service['collectd'],
  }

  file_line { 'Set the collectd cloudwatch proxy_server_port':
    path   => '/opt/collectd-cloudwatch/src/cloudwatch/config/plugin.conf',
    line   => "proxy_server_port = \"${::proxy_port}\"",
    match  => '^#proxy_server_port =.*$',
    notify => Service['collectd'],
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
    service_url => 'service:jmx:rmi:///jndi/rmi://localhost:8463/jmxrmi',
    collect     => [ 'standby-status' ],
  }

  class { '::collectd':
    service_ensure => running,
    service_enable => true,
  }

}
