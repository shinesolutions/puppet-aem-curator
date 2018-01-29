class aem_curator::config_aem_tools (
  $aem_repo_device,
  $aem_password_retrieval_command,
  $base_dir,
  $aem_instances,
  $enable_daily_export_cron,
  $enable_hourly_live_snapshot_cron,
  $enable_offline_compaction_cron,
  $oak_run_source,
  $oak_run_version,
  $tmp_dir,
  $env_path         = $::cron_env_path,
  $https_proxy      = $::cron_https_proxy,
) {

  file { "${base_dir}/aem-tools/":
    ensure => directory,
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/export-backup.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/export-backup.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/import-backup.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/import-backup.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/enable-crxde.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/enable-crxde.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/disable-crxde.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/disable-crxde.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
      }
    ),
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
    source => $oak_run_source,
  } -> file { "${base_dir}/aem-tools/offline-compaction.sh":
    ensure  => present,
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
    content => epp(
      'aem_curator/aem-tools/offline-compaction.sh.epp',
      {
        'base_dir'        => $base_dir,
        'oak_run_version' => $oak_run_version,
        'aem_instances'   => $aem_instances,
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
    content => epp(
      'aem_curator/aem-tools/export-backups.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
      }
    ),
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

}
