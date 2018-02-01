define aem_curator::install_aem63_sp1_cfp2(
  $aem_artifacts_base,
  $aem_healthcheck_version,
  $aem_port,
  $run_mode,
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
  $post_install_sleep_secs = 120,
) {

  aem_curator::install_aem63 { "${aem_id}: Install AEM":
    tmp_dir                 => $tmp_dir,
    run_mode                => $run_mode,
    aem_port                => $aem_port,
    aem_artifacts_base      => $aem_artifacts_base,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_base                => $aem_base,
    aem_sample_content      => $aem_sample_content,
    aem_jvm_mem_opts        => $aem_jvm_mem_opts,
    aem_jvm_opts            => $aem_jvm_opts,
    post_install_sleep_secs => $post_install_sleep_secs,
    aem_id                  => $aem_id,
  } -> aem_curator::install_aem_package { "${aem_id}: Install service pack 1":
    tmp_dir         => $tmp_dir,
    file_name       => 'AEM-6.3-Service-Pack-1-6.3.SP1.zip',
    package_name    => 'aem-service-pkg',
    package_group   => 'adobe/cq630/servicepack',
    package_version => '6.3.1',
    artifacts_base  => $aem_artifacts_base,
    aem_id          => $aem_id,
  } -> aem_curator::install_aem_package { "${aem_id}: Install cumulative fix pack 2":
    tmp_dir                 => $tmp_dir,
    file_name               => 'AEM-CFP-6.3.1.2-2.0.zip',
    package_name            => 'aem-6.3.1-cfp',
    package_group           => 'adobe/cq630/cumulativefixpack',
    post_install_sleep_secs => 900,
    package_version         => '2.0',
    artifacts_base          => $aem_artifacts_base,
    aem_id                  => $aem_id,
  }

}
