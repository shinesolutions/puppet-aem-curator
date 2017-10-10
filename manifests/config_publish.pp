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

  $snapshotid = $::snapshotid,
  $delete_repository_index = false,
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
  }
  -> archive { "${crx_quickstart_dir}/install/aem-password-reset-content-${::aem_password_reset_version}.zip":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/aem-password-reset-content-${::aem_password_reset_version}.zip",
  }
  -> class { 'aem_resources::puppet_aem_resources_set_config':
    conf_dir => "${puppet_conf_dir}",
    protocol => "${publish_protocol}",
    host     => 'localhost',
    port     => "${publish_port}",
    debug    => false,
  }
  -> service { 'aem-publish':
    ensure => 'running',
    enable => true,
  }
  -> aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => $login_ready_max_tries,
    retries_base_sleep_seconds => $login_ready_base_sleep_seconds,
    retries_max_sleep_seconds  => $login_ready_max_sleep_seconds,
  }
  -> aem_bundle { 'Stop webdav bundle':
    ensure => stopped,
    name   => 'org.apache.sling.jcr.webdav',
  }
  -> aem_bundle { 'Stop davex bundle':
    ensure => stopped,
    name   => 'org.apache.sling.jcr.davex',
  }
  -> aem_aem { 'Remove all agents':
    ensure   => all_agents_removed,
    run_mode => 'publish',
  }
  -> aem_package { 'Remove password reset package':
    ensure  => absent,
    name    => 'aem-password-reset-content',
    group   => 'shinesolutions',
    version => $::aem_password_reset_version,
  }
  -> aem_flush_agent { 'Create flush agent':
    ensure        => present,
    name          => "flushAgent-${::pairinstanceid}",
    run_mode      => 'publish',
    title         => "Flush agent for publish-dispatcher ${::pairinstanceid}",
    description   => "Flush agent for publish-dispatcher ${::pairinstanceid}",
    dest_base_url => "https://${::publishdispatcherhost}:443",
    log_level     => 'info',
    retry_delay   => 60000,
    force         => true,
  }
  -> aem_outbox_replication_agent { 'Create outbox replication agent':
    ensure      => present,
    name        => 'outbox',
    run_mode    => 'publish',
    title       => "Outbox replication agent for publish-dispatcher ${::pairinstanceid}",
    description => "Outbox replication agent for publish-dispatcher ${::pairinstanceid}",
    user_id     => 'replicator',
    log_level   => 'info',
    force       => true,
  }
  -> class { 'aem_resources::change_system_users_password':
    orchestrator_new_password => $credentials_hash['orchestrator'],
    replicator_new_password   => $credentials_hash['replicator'],
    deployer_new_password     => $credentials_hash['deployer'],
    exporter_new_password     => $credentials_hash['exporter'],
    importer_new_password     => $credentials_hash['importer'],
  }
  -> aem_user { 'Set admin password for current stack':
    ensure       => password_changed,
    name         => 'admin',
    path         => '/home/users/d',
    old_password => 'admin',
    new_password => $credentials_hash['admin'],
  }
  -> file { "${crx_quickstart_dir}/install/aem-password-reset-content-${::aem_password_reset_version}.zip":
    ensure => absent,
  }

  # Set up AEM tools
  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }
  -> file { "${base_dir}/aem-tools/deploy-artifact.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifact.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }
  -> file { "${base_dir}/aem-tools/deploy-artifacts.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifacts.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }
  -> file { "${base_dir}/aem-tools/export-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backup.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }
  -> file { "${base_dir}/aem-tools/import-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/import-backup.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }
  -> file { "${base_dir}/aem-tools/enable-crxde.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/enable-crxde.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }
  -> file {"${base_dir}/aem-tools/crx-process-quited.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/aem-tools/crx-process-quited.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }
  -> file {"${base_dir}/aem-tools/oak-run-process-quited.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/aem-tools/oak-run-process-quited.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }
  -> file {"${base_dir}/aem-tools/wait-until-ready.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/wait-until-ready.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  archive { "${base_dir}/aem-tools/oak-run-${::oak_run_version}.jar":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/oak-run-${::oak_run_version}.jar",
  }
  -> file { "${base_dir}/aem-tools/offline-compaction.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-compaction.sh.epp",
      {
        'base_dir'           => "${base_dir}",
        'oak_run_version'    => "${::oak_run_version}",
        'crx_quickstart_dir' => $crx_quickstart_dir,
      }
    ),
  }

  if $enable_offline_compaction_cron {
    cron { 'weekly-offline-compaction':
      command => "${base_dir}/aem-tools/offline-compaction.sh >>/var/log/offline-compaction.log 2>&1",
      user    => 'root',
      weekday => 2,
      hour    => 3,
      minute  => 0,
    }
  }

  file { "${base_dir}/aem-tools/export-backups.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backups.sh.epp", { 'base_dir' => "${base_dir}" }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  if $enable_daily_export_cron {
    cron { 'daily-export-backups':
      command     => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>/var/log/export-backups.log 2>&1",
      user        => 'root',
      hour        => 2,
      minute      => 0,
      environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
      require     => File["${base_dir}/aem-tools/export-backups.sh"],
    }
  }

  file { "${base_dir}/aem-tools/live-snapshot-backup.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/live-snapshot-backup.sh.epp",
      {
        'base_dir'        => "${base_dir}",
        'aem_repo_device' => "${aem_repo_device}",
        'component'       => "${::component}",
        'stack_prefix'    => "${::stackprefix}",
      }
    ),
  }

  if $enable_hourly_live_snapshot_cron {
    cron { 'hourly-live-snapshot-backup':
      command     => "${base_dir}/aem-tools/live-snapshot-backup.sh >>/var/log/live-snapshot-backup.log 2>&1",
      user        => 'root',
      hour        => '*',
      minute      => 0,
      environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
    }
  }

  file { "${base_dir}/aem-tools/offline-snapshot-backup.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-snapshot-backup.sh.epp",
      {
        'base_dir'        => "${base_dir}",
        'aem_repo_device' => "${aem_repo_device}",
        'component'       => "${::component}",
        'stack_prefix'    => "${::stackprefix}",
      }
    ),
  }

}
