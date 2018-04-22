class aem_curator::config_aem_deployer (
  $aem_password_retrieval_command,
  $base_dir,
  $tmp_dir,
  $confdir            = $settings::confdir,
  $aem_tools_env_path = '$PATH',
) {

  file { "${base_dir}/aem-tools/deploy-artifact.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/deploy-artifact.sh.epp',
      {
        'base_dir'                       => $base_dir,
        'confdir'                        => $confdir,
        'tmp_dir'                        => $tmp_dir,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
        'aem_tools_env_path'             => $aem_tools_env_path
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  } -> file { "${base_dir}/aem-tools/deploy-artifacts.sh":
    ensure  => present,
    content => epp(
      'aem_curator/aem-tools/deploy-artifacts.sh.epp',
      {
        'base_dir'                       => $base_dir,
        'tmp_dir'                        => $tmp_dir,
        'aem_password_retrieval_command' => $aem_password_retrieval_command,
        'aem_tools_env_path'             => $aem_tools_env_path
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  # generate-artifacts-descriptor is needed by components that have
  # AEM Dispatcher deployment feature
  } -> file { "${base_dir}/aem-tools/generate-artifacts-descriptor.py":
    ensure  => present,
    content => epp('aem_curator/aem-tools/generate-artifacts-descriptor.py.epp',
      {
        'tmp_dir' => $tmp_dir
      }
    ),
    mode    => '0775',
    owner   => 'root',
    group   => 'root',
  }

}
