class aem_curator::config_aem_tools (
  $aem_repo_device,
  $base_dir,
  $crx_quickstart_dir,
  $enable_daily_export_cron,
  $enable_hourly_live_snapshot_cron,
  $enable_offline_compaction_cron,
  $tmp_dir,
  $data_bucket_name = $::data_bucket_name,
  $stack_prefix     = $::stack_prefix,
  $env_path         = $::cron_env_path,
  $https_proxy      = $::cron_https_proxy,
  $oak_run_version  = '1.4.15',
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
    source => "s3://${data_bucket_name}/${stack_prefix}/oak-run-${oak_run_version}.jar",
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
      environment => ["PATH=${env_path}", "https_proxy=\"${https_proxy}\""],
      require     => File["${base_dir}/aem-tools/export-backups.sh"],
    }
  }

  # generate-artifacts-descriptor is needed by components that have
  # AEM Dispatcher deployment feature
  file { "${base_dir}/aem-tools/generate-artifacts-descriptor.py":
    ensure  => present,
    content => epp('aem_curator/aem-tools/generate-artifacts-descriptor.py.epp', { 'tmp_dir' => $tmp_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

}
