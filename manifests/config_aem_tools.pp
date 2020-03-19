class aem_curator::config_aem_tools (
  $aem_repo_device,
  $aem_password_retrieval_command,
  $base_dir,
  $oak_run_source,
  $oak_run_version,
  $tmp_dir,
  $aem_instances                                  = undef,
  $aem_tools_env_path                             = '$PATH',
  $confdir                                        = $settings::confdir,
  $enable_compaction_remove_bak_files             = false,
  $compaction_remove_bak_files_older_than_in_days = 30,
  $aem_compaction_jvm_mem_opts                    = '-Xms2048m -Xmx4096m -XX:-UseGCOverheadLimit',
) {

  validate_bool($enable_compaction_remove_bak_files)

  $_aem_instances = pick(
    $aem_instances,
    [{'aem_id' => 'author'}]
  )

  file { "${base_dir}/aem-tools/import-backup.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/import-backup.sh.epp', {
        'base_dir'                       => $base_dir,
        'confdir'                        => $confdir,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command
      }
    ),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/enable-crxde.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/enable-crxde.sh.epp', {
        'base_dir'                       => $base_dir,
        'confdir'                        => $confdir,
        'aem_instances'                  => $_aem_instances,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command
      }
    ),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/disable-crxde.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/disable-crxde.sh.epp', {
        'base_dir'                       => $base_dir,
        'confdir'                        => $confdir,
        'aem_instances'                  => $_aem_instances,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command
      }
    ),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/enable-saml.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/enable-saml.sh.epp', {
        'base_dir'                       => $base_dir,
        'confdir'                        => $confdir,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command
      }
    ),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/disable-saml.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/disable-saml.sh.epp', {
        'base_dir'                       => $base_dir,
        'confdir'                        => $confdir,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command
      }
    ),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/list-packages.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/list-packages.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command
      }
    ),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/promote-author-standby-to-primary.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/promote-author-standby-to-primary.sh.epp', {
        'base_dir'                       => $base_dir,
        'aem_tools_env_path'             => $aem_tools_env_path,
        'aem_password_retrieval_command' => $aem_password_retrieval_command
      }
    ),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file {"${base_dir}/aem-tools/crx-process-quited.sh":
    ensure => present,
    source => 'puppet:///modules/aem_curator/aem-tools/crx-process-quited.sh',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  } -> file {"${base_dir}/aem-tools/oak-run-process-quited.sh":
    ensure => present,
    source => 'puppet:///modules/aem_curator/aem-tools/oak-run-process-quited.sh',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  } -> file {"${base_dir}/aem-tools/wait-until-ready.sh":
    ensure  => present,
    content => epp('aem_curator/aem-tools/wait-until-ready.sh.epp', { 'base_dir' => $base_dir }),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file {"${base_dir}/aem-tools/test":
    ensure  => directory,
    source  => 'puppet:///modules/aem_curator/test',
    recurse => true,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/install-aem-profile.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/install-aem-profile.sh.epp', {
        'base_dir'           => $base_dir,
        'tmp_dir'            => $tmp_dir,
        'aem_tools_env_path' => $aem_tools_env_path
      }
    ),
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  archive { "${base_dir}/aem-tools/oak-run-${oak_run_version}.jar":
    ensure => present,
    source => $oak_run_source,
    user   => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/oak-run-${oak_run_version}.jar":
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  } -> file { "${base_dir}/aem-tools/offline-compaction.sh":
    ensure  => present,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => epp(
      'aem_curator/aem-tools/offline-compaction.sh.epp',
      {
        'base_dir'                                       => $base_dir,
        'oak_run_version'                                => $oak_run_version,
        'aem_instances'                                  => $aem_instances,
        'aem_tools_env_path'                             => $aem_tools_env_path,
        'enable_compaction_remove_bak_files'             => $enable_compaction_remove_bak_files,
        'compaction_remove_bak_files_older_than_in_days' => $compaction_remove_bak_files_older_than_in_days,
        'aem_compaction_jvm_mem_opts'                    => $aem_compaction_jvm_mem_opts,
      }
    ),
  }
}
