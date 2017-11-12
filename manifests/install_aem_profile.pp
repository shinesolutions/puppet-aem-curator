# TODO: Figure out a way to replace these nasty if-else blocks with dynamic definition call.
#       It has to be definition instead of class due to the need to support multiple AEM instances
#       on the same machine.
define aem_curator::install_aem_profile (
  $tmp_dir,

  $run_mode,
  $aem_host,
  $aem_port,
  $aem_ssl_port,
  $aem_quickstart_source,
  $aem_license_source,
  $aem_artifacts_base,
  $aem_healthcheck_version,
  $aem_profile,

  $aem_base           = '/opt',
  $aem_sample_content = false,
  $aem_jvm_mem_opts   = '-Xss4m -Xmx8192m',

  $post_install_sleep_secs = 120,

  $jvm_opts = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],

  $aem_id             = 'aem',
) {

  if $aem_profile == 'aem62' {

    aem_curator::install_aem62 { "${aem_id}: Install AEM profile ${aem_profile}":
      tmp_dir                 => $tmp_dir,
      run_mode                => $run_mode,
      aem_port                => $aem_port,
      aem_quickstart_source   => $aem_quickstart_source,
      aem_license_source      => $aem_license_source,
      aem_artifacts_base      => $aem_artifacts_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_base                => $aem_base,
      aem_sample_content      => $aem_sample_content,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      aem_id                  => $aem_id,
    }

  } elsif $aem_profile == 'aem62_sp1_cfp3' {

    aem_curator::install_aem62_sp1_cfp3 { "${aem_id}: Install AEM profile ${aem_profile}":
      tmp_dir                 => $tmp_dir,
      run_mode                => $run_mode,
      aem_port                => $aem_port,
      aem_quickstart_source   => $aem_quickstart_source,
      aem_license_source      => $aem_license_source,
      aem_artifacts_base      => $aem_artifacts_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_base                => $aem_base,
      aem_sample_content      => $aem_sample_content,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      aem_id                  => $aem_id,
    }

  } elsif $aem_profile == 'aem62_sp1_cfp5' {

    aem_curator::install_aem62_sp1_cfp5 { "${aem_id}: Install AEM profile ${aem_profile}":
      tmp_dir                 => $tmp_dir,
      run_mode                => $run_mode,
      aem_port                => $aem_port,
      aem_quickstart_source   => $aem_quickstart_source,
      aem_license_source      => $aem_license_source,
      aem_artifacts_base      => $aem_artifacts_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_base                => $aem_base,
      aem_sample_content      => $aem_sample_content,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      aem_id                  => $aem_id,
    }

  }

}
