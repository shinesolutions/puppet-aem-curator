class aem_curator::config_aem_tools (
  $aem_repo_device,
  $base_dir,
  $crx_quickstart_dir,
  $enable_daily_export_cron,
  $enable_hourly_live_snapshot_cron,
  $enable_offline_compaction_cron,
  $tmp_dir,
  $oak_run_version = '1.4.15',
) {

  # Set up AEM tools
  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/deploy-artifact.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/deploy-artifact.sh.epp', { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/deploy-artifacts.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/deploy-artifacts.sh.epp', { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/export-backup.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/export-backup.sh.epp', { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/import-backup.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/import-backup.sh.epp', { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/enable-crxde.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/enable-crxde.sh.epp', { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file {"${base_dir}/aem-tools/crx-process-quited.sh":
    ensure => present,
    source => 'puppet:///modules/aem_curator/aem-tools/crx-process-quited.sh',
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file {"${base_dir}/aem-tools/oak-run-process-quited.sh":
    ensure => present,
    source => 'puppet:///modules/aem_curator/aem-tools/oak-run-process-quited.sh',
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file {"${base_dir}/aem-tools/wait-until-ready.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/wait-until-ready.sh.epp', { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  archive { "${base_dir}/aem-tools/oak-run-${oak_run_version}.jar":
    ensure => present,
    source => "s3://${::data_bucket}/${::stackprefix}/oak-run-${oak_run_version}.jar",
  } -> file { "${base_dir}/aem-tools/offline-compaction.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      'aem_curator/aem-tools/offline-compaction.sh.epp',
      {
        'base_dir'           => $base_dir,
        'oak_run_version'    => $oak_run_version,
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
    content => epp('aem_curator/aem-tools/export-backups.sh.epp', { 'base_dir' => $base_dir }),
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
      'aem_curator/aem-tools/live-snapshot-backup.sh.epp',
      {
        'base_dir'        => $base_dir,
        'aem_repo_device' => $aem_repo_device,
        'component'       => $::component,
        'stack_prefix'    => $::stackprefix,
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
      'aem_curator/aem-tools/offline-snapshot-backup.sh.epp',
      {
        'base_dir'        => $base_dir,
        'aem_repo_device' => $aem_repo_device,
        'component'       => $::component,
        'stack_prefix'    => $::stackprefix,
      }
    ),
  }

  # publish-dispatcher related AEM Tools
  file { "${base_dir}/aem-tools/generate-artifacts-descriptor.py":
    ensure  => present,
    content => epp('aem_curator/aem-tools/generate-artifacts-descriptor.py.epp', { 'tmp_dir' => $tmp_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/enter-standby.sh":
    ensure => present,
    source => 'puppet:///modules/aem_curator/aem-tools/enter-standby.sh',
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/exit-standby.sh":
    ensure => present,
    source => 'puppet:///modules/aem_curator/aem-tools/exit-standby.sh',
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  }

  file { "${base_dir}/aem-tools/content-healthcheck.py":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      'aem_curator/aem-tools/content-healthcheck.py.epp',
      {
        'tmp_dir'      => $tmp_dir,
        'stack_prefix' => $::stackprefix,
        'data_bucket'  => $::data_bucket,
      }
    ),
  } -> cron { 'every-minute-content-healthcheck':
    command     => "${base_dir}/aem-tools/content-healthcheck.py",
    user        => 'root',
    minute      => '*',
    environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
  }


  # orchestrator-related AEM Tools
  file { "${base_dir}/aem-tools/stack-offline-snapshot-message.json":
    ensure  => present,
    content => epp('aem_curator/aem-tools/stack-offline-snapshot-message.json.epp', { 'stack_prefix' => "${::stackprefix}"}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aem-tools/"],
  } -> file { "${base_dir}/aem-tools/stack-offline-snapshot.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/stack-offline-snapshot.sh.epp', { 'sns_topic_arn' => "${::stack_manager_sns_topic_arn}",}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  if $enable_weekly_offline_compaction_snapshot {

    # Tuesday to Sunday
    cron { 'nightly-stack-offline-snapshot':
      command     => "cd ${base_dir}/aem-tools && ./stack-offline-snapshot.sh >/var/log/stack-offline-snapshot.log 2>&1",
      user        => 'root',
      hour        => $offline_snapshot_hour,
      minute      => $offline_snapshot_minute,
      weekday     => '2-7',
      environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
      require     => File["${base_dir}/aem-tools/stack-offline-snapshot.sh"],
    }

  }
  else {

    # Monday to Sunday
    cron { 'nightly-stack-offline-snapshot':
      command     => "cd ${base_dir}/aem-tools && ./stack-offline-snapshot.sh >/var/log/stack-offline-snapshot.log 2>&1",
      user        => 'root',
      hour        => $offline_snapshot_hour,
      minute      => $offline_snapshot_minute,
      weekday     => '1-7',
      environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
      require     => File["${base_dir}/aem-tools/stack-offline-snapshot.sh"],
    }

  }

  # stack offline-compaction-snapshot
  file { "${base_dir}/aem-tools/stack-offline-compaction-snapshot-message.json":
    ensure  => present,
    content => epp('aem_curator/aem-tools/stack-offline-compaction-snapshot-message.json.epp', { 'stack_prefix' => "${::stackprefix}"}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    require => File["${base_dir}/aem-tools/"],
  } -> file { "${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/stack-offline-compaction-snapshot.sh.epp', { 'sns_topic_arn' => "${::stack_manager_sns_topic_arn}",}),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

  if $enable_weekly_offline_compaction_snapshot {

    # Monday only

    cron { 'weekly-stack-offline-compaction-snapshot':
      command     => "cd ${base_dir}/aem-tools && ./stack-offline-compaction-snapshot.sh >/var/log/stack-offline-compaction-snapshot.log 2>&1",
      user        => 'root',
      hour        => $offline_snapshot_hour,
      minute      => $offline_snapshot_minute,
      weekday     => 1,
      environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
      require     => File["${base_dir}/aem-tools/stack-offline-compaction-snapshot.sh"],
    }

  }
}
