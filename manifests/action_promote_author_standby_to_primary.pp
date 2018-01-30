File {
  backup => false,
}

class aem_curator::action_promote_author_standby_to_primary (
  $base_dir,
  $tmp_dir,
  $aem_version = '6.2',
) {
  $enable_offline_compaction_cron = lookup('::author_primary::enable_offline_compaction_cron')
  $enable_daily_export_cron = lookup('::author_primary::enable_daily_export_cron')
  $enable_hourly_live_snapshot_cron = lookup('::author_primary::enable_hourly_live_snapshot_cron')

  exec { 'service aem-aem stop':
    cwd  => $tmp_dir,
    path => ['/usr/bin', '/usr/sbin', '/sbin'],
  } -> exec { 'crx-process-quited.sh 24 5':
    cwd  => $tmp_dir,
    path => ["${base_dir}/aem-tools", '/usr/bin', '/opt/puppetlabs/bin/', '/bin'],
  } -> exec { 'set-component.sh author-primary':
    cwd  => $tmp_dir,
    path => ["${base_dir}/aws-tools", '/usr/bin', '/opt/puppetlabs/bin/', '/bin'],
  } -> class { 'aem_resources::author_primary_set_config':
    crx_quickstart_dir => '/opt/aem/author/crx-quickstart',
    aem_version        => $aem_version,
  } -> service { 'aem-aem':
    ensure => 'running',
    enable => true,
  } -> aem_aem { 'Wait until login page is ready':
    ensure                     => login_page_is_ready,
    retries_max_tries          => 30,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
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

  if $enable_daily_export_cron {
    cron { 'daily-export-backups':
      command     => "${base_dir}/aem-tools/export-backups.sh export-backups-descriptor.json >>/var/log/export-backups.log 2>&1",
      user        => 'root',
      hour        => 2,
      minute      => 0,
      environment => ["PATH=${::cron_env_path}", "https_proxy=\"${::cron_https_proxy}\""],
    }
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

}

include promote_author_standby_to_primary
