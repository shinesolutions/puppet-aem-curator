define aem_curator::install_aem64_sp4(
  $aem_license_base,
  $aem_artifacts_base,
  $aem_healthcheck_version,
  $aem_port,
  $run_modes,
  $tmp_dir,
  $aem_base                = '/opt',
  $aem_id                  = 'aem',
  $aem_jvm_mem_opts        = '-Xss4m -Xmx8192m',
  $aem_sample_content      = false,
  $aem_jvm_opts                = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],
  $aem_start_opts          = '',
  $post_install_sleep_secs = 120,
) {

  aem_curator::install_aem64 { "${aem_id}: Install AEM":
    tmp_dir                 => $tmp_dir,
    run_modes               => $run_modes,
    aem_port                => $aem_port,
    aem_artifacts_base      => $aem_artifacts_base,
    aem_license_base        => $aem_license_base,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_base                => $aem_base,
    aem_sample_content      => $aem_sample_content,
    aem_jvm_mem_opts        => $aem_jvm_mem_opts,
    aem_jvm_opts            => $aem_jvm_opts,
    aem_start_opts          => $aem_start_opts,
    post_install_sleep_secs => $post_install_sleep_secs,
    aem_id                  => $aem_id,
  } -> aem_curator::install_aem_package { "${aem_id}: Install service pack 4":
    tmp_dir         => $tmp_dir,
    file_name       => 'AEM-6.4.4.0-6.4.4.zip',
    package_name    => 'aem-service-pkg',
    package_group   => 'adobe/cq640/servicepack',
    package_version => '6.4.4',
    artifacts_base  => $aem_artifacts_base,
    aem_id          => $aem_id,
  }

}
