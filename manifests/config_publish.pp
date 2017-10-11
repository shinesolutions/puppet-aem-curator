File {
  backup => false,
}

class aem_curator::config_publish (
  $base_dir,
  $tmp_dir,
  $puppet_conf_dir,
  $crx_quickstart_dir,
  $publish_protocol,
  $publish_port,
  $aem_repo_device,
  $vol_type,
  $credentials_file,
  $exec_path,
  $enable_offline_compaction_cron,
  $enable_daily_export_cron,
  $enable_hourly_live_snapshot_cron,

  $login_ready_max_tries,
  $login_ready_base_sleep_seconds,
  $login_ready_max_sleep_seconds,

  $publishdispatcherhost,
  $pairinstanceid,

  $snapshotid = $::snapshotid,
  $delete_repository_index = false,
  $aem_id = 'publish',
) {

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  if $snapshotid != undef and $snapshotid != '' {
    if $delete_repository_index {
      $attach_volume_before = File["${crx_quickstart_dir}/repository/index/"]
    } else {
      $attach_volume_before = Service['aem-publish']
    }
    exec { "Attach volume from snapshot ID ${snapshotid}":
      command => "/opt/shinesolutions/aws-tools/snapshot_attach.py --device /dev/sdb --device-alias /dev/xvdb --volume-type ${vol_type} --snapshot-id ${snapshotid} -vvvv",
      path    => $exec_path,
      before  => $attach_volume_before,
    }
  }

  if $delete_repository_index {
    file { "${crx_quickstart_dir}/repository/index/":
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
      before  => Service['aem-publish'],
    }
  }

  file { "${crx_quickstart_dir}/install/":
    ensure => directory,
    mode   => '0775',
    owner  => 'aem',
    group  => 'aem',
  } -> archive { "${crx_quickstart_dir}/install/aem-password-reset-content-${::aem_password_reset_version}.zip":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/aem-password-reset-content-${::aem_password_reset_version}.zip",
  } -> aem_resources::puppet_aem_resources_set_config { 'Set puppet-aem-resources config file for publish':
    conf_dir => $puppet_conf_dir,
    protocol => $publish_protocol,
    host     => 'localhost',
    port     => $publish_port,
    debug    => false,
    aem_id   => $aem_id,
  } -> service { 'aem-publish':
    ensure => 'running',
    enable => true,
  } -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
    aem_id                     => $aem_id,
  } -> aem_bundle { "${aem_id}: Stop webdav bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.webdav',
    aem_id => $aem_id,
  } -> aem_bundle { "${aem_id}: Stop davex bundle":
    ensure => stopped,
    name   => 'org.apache.sling.jcr.davex',
    aem_id => $aem_id,
  } -> aem_aem { "${aem_id}: Remove all agents":
    ensure   => all_agents_removed,
    run_mode => 'publish',
    aem_id   => $aem_id,
  } -> aem_package { "${aem_id}: Remove password reset package":
    ensure  => absent,
    name    => 'aem-password-reset-content',
    group   => 'shinesolutions',
    version => $::aem_password_reset_version,
    aem_id  => $aem_id,
  } -> aem_flush_agent { "${aem_id}: Create flush agent":
    ensure        => present,
    name          => "flushAgent-${pairinstanceid}",
    run_mode      => 'publish',
    title         => "Flush agent for publish-dispatcher ${pairinstanceid}",
    description   => "Flush agent for publish-dispatcher ${pairinstanceid}",
    dest_base_url => "https://${publishdispatcherhost}:443",
    log_level     => 'info',
    retry_delay   => 60000,
    force         => true,
    aem_id        => $aem_id,
  } -> aem_outbox_replication_agent { "${aem_id}: Create outbox replication agent":
    ensure      => present,
    name        => 'outbox',
    run_mode    => 'publish',
    title       => "Outbox replication agent for publish-dispatcher ${pairinstanceid}",
    description => "Outbox replication agent for publish-dispatcher ${pairinstanceid}",
    user_id     => 'replicator',
    log_level   => 'info',
    force       => true,
    aem_id      => $aem_id,
  } -> aem_resources::change_system_users_password { 'Change system users password for publish':
    orchestrator_new_password => $credentials_hash['orchestrator'],
    replicator_new_password   => $credentials_hash['replicator'],
    deployer_new_password     => $credentials_hash['deployer'],
    exporter_new_password     => $credentials_hash['exporter'],
    importer_new_password     => $credentials_hash['importer'],
    aem_id                    => $aem_id,
  } -> aem_user { "${aem_id}: Set admin password for current stack":
    ensure       => password_changed,
    name         => 'admin',
    path         => '/home/users/d',
    old_password => 'admin',
    new_password => $credentials_hash['admin'],
    aem_id       => $aem_id,
  } -> file { "${crx_quickstart_dir}/install/aem-password-reset-content-${::aem_password_reset_version}.zip":
    ensure => absent,
  }

}
