class aem_curator::config_aem_tools (
  $aem_repo_device,
  $aem_password_retrieval_command,
  $base_dir,
  $aem_instances,
  $enable_offline_compaction_cron,
  $oak_run_source,
  $oak_run_version,
  $tmp_dir,
  $aem_tools_env_path = '$PATH',
  $env_path           = $::cron_env_path,
  $https_proxy        = $::cron_https_proxy,
) {

  file { "${base_dir}/aem-tools/import-backup.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/import-backup.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_tools_env_path'             => $aem_tools_env_path,
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
        'aem_tools_env_path'             => $aem_tools_env_path,
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
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/promote-author-standby-to-primary.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/promote-author-standby-to-primary.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_tools_env_path'             => $aem_tools_env_path,
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
  } -> file {"${base_dir}/aem-tools/test":
    ensure  => directory,
    source  => 'puppet:///modules/aem_curator/test',
    recurse => true,
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
}
