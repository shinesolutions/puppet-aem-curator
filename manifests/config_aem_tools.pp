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
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifact.sh.epp", { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/deploy-artifacts.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/deploy-artifacts.sh.epp", { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/export-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backup.sh.epp", { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/import-backup.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/import-backup.sh.epp", { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/enable-crxde.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/enable-crxde.sh.epp", { 'base_dir' => $base_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file {"${base_dir}/aem-tools/crx-process-quited.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/aem-tools/crx-process-quited.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file {"${base_dir}/aem-tools/oak-run-process-quited.sh":
    ensure => present,
    source => "file://${base_dir}/aem-aws-stack-provisioner/files/aem-tools/oak-run-process-quited.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file {"${base_dir}/aem-tools/wait-until-ready.sh":
    ensure  => present,
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/wait-until-ready.sh.epp", { 'base_dir' => $base_dir }),
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
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-compaction.sh.epp",
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
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/export-backups.sh.epp", { 'base_dir' => $base_dir }),
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
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/offline-snapshot-backup.sh.epp",
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
    content => epp("${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/generate-artifacts-descriptor.py.epp", { 'tmp_dir' => $tmp_dir }),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/enter-standby.sh":
    ensure => present,
    source => "${base_dir}/aem-aws-stack-provisioner/files/aem-tools/enter-standby.sh",
    mode   => '0775',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/exit-standby.sh":
    ensure => present,
    source => "${base_dir}/aem-aws-stack-provisioner/files/aem-tools/exit-standby.sh",
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
      "${base_dir}/aem-aws-stack-provisioner/templates/aem-tools/content-healthcheck.py.epp",
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

}
