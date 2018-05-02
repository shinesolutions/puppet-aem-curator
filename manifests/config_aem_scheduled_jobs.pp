class aem_curator::config_aem_scheduled_jobs (
  $base_dir,
  $cron_offline_compaction_weekday     = '2',
  $cron_offline_compaction_hour        = '3',
  $cron_offline_compaction_minute      = '0',
  $cron_offline_compaction_enable      = undef
) {
  if $cron_offline_compaction_enable {
    cron { 'offline-compaction':
      ensure  => present,
      command => "${base_dir}/aem-tools/offline-compaction.sh >>/var/log/offline-compaction.log 2>&1",
      user    => 'root',
      weekday => $cron_offline_compaction_weekday,
      hour    => $cron_offline_compaction_hour,
      minute  => $cron_offline_compaction_minute,
    }
  } else {
    cron { 'offline-compaction':
      ensure  => absent,
      command => "${base_dir}/aem-tools/offline-compaction.sh >>/var/log/offline-compaction.log 2>&1",
      user    => 'root',
    }
  }
}
