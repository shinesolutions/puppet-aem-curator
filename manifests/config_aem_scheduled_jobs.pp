class aem_curator::config_aem_scheduled_jobs (
  $base_dir,
  $offline_compaction_enable  = false,
  $offline_compaction_weekday = '2',
  $offline_compaction_hour    = '3',
  $offline_compaction_minute  = '0'
) {
  if $offline_compaction_enable {
    cron { 'offline-compaction':
      ensure  => present,
      command => "${base_dir}/aem-tools/offline-compaction.sh >>/var/log/offline-compaction.log 2>&1",
      user    => 'root',
      weekday => $offline_compaction_weekday,
      hour    => $offline_compaction_hour,
      minute  => $offline_compaction_minute,
    }
  } else {
    cron { 'offline-compaction':
      ensure  => absent,
      command => "${base_dir}/aem-tools/offline-compaction.sh >>/var/log/offline-compaction.log 2>&1",
      user    => 'root',
    }
  }
}
