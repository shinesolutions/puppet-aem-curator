# TODO: Figure out a way to replace these nasty if-else blocks with dynamic definition call.
#       It has to be definition instead of class due to the need to support multiple AEM instances
#       on the same machine.
define aem_curator::install_aem_profile (
  $aem_artifacts_base,
  $aem_healthcheck_version,
  $aem_host,
  $aem_port,
  $aem_profile,
  $aem_ssl_port,
  $run_mode,
  $tmp_dir,
  $aem_base                = '/opt',
  $aem_id                  = 'aem',
  $aem_jvm_mem_opts        = '-Xss4m -Xmx8192m',
  $aem_sample_content      = false,
  $jvm_opts                = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],
  $post_install_sleep_secs = 120,
) {

  if $aem_profile == 'aem62' {

    aem_curator::install_aem62 { "${aem_id}: Install AEM profile ${aem_profile}":
      aem_artifacts_base      => $aem_artifacts_base,
      aem_base                => $aem_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_id                  => $aem_id,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      aem_port                => $aem_port,
      aem_sample_content      => $aem_sample_content,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      run_mode                => $run_mode,
      tmp_dir                 => $tmp_dir,
    }

  } elsif $aem_profile == 'aem62_sp1_cfp3' {

    aem_curator::install_aem62_sp1_cfp3 { "${aem_id}: Install AEM profile ${aem_profile}":
      aem_artifacts_base      => $aem_artifacts_base,
      aem_base                => $aem_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_id                  => $aem_id,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      aem_port                => $aem_port,
      aem_sample_content      => $aem_sample_content,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      run_mode                => $run_mode,
      tmp_dir                 => $tmp_dir,
    }

  } elsif $aem_profile == 'aem62_sp1_cfp5' {

    aem_curator::install_aem62_sp1_cfp5 { "${aem_id}: Install AEM profile ${aem_profile}":
      aem_artifacts_base      => $aem_artifacts_base,
      aem_base                => $aem_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_id                  => $aem_id,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      aem_port                => $aem_port,
      aem_sample_content      => $aem_sample_content,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      run_mode                => $run_mode,
      tmp_dir                 => $tmp_dir,
    }

  } elsif $aem_profile == 'aem62_sp1_cfp9' {

    aem_curator::install_aem62_sp1_cfp9 { "${aem_id}: Install AEM profile ${aem_profile}":
      aem_artifacts_base      => $aem_artifacts_base,
      aem_base                => $aem_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_id                  => $aem_id,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      aem_port                => $aem_port,
      aem_sample_content      => $aem_sample_content,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      run_mode                => $run_mode,
      tmp_dir                 => $tmp_dir,
    }

  } elsif $aem_profile == 'aem63' {

    aem_curator::install_aem63 { "${aem_id}: Install AEM profile ${aem_profile}":
      aem_artifacts_base      => $aem_artifacts_base,
      aem_base                => $aem_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_id                  => $aem_id,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      aem_port                => $aem_port,
      aem_sample_content      => $aem_sample_content,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      run_mode                => $run_mode,
      tmp_dir                 => $tmp_dir,
    }

  } elsif $aem_profile == 'aem63_sp1' {

    aem_curator::install_aem63_sp1 { "${aem_id}: Install AEM profile ${aem_profile}":
      aem_artifacts_base      => $aem_artifacts_base,
      aem_base                => $aem_base,
      aem_healthcheck_version => $aem_healthcheck_version,
      aem_id                  => $aem_id,
      aem_jvm_mem_opts        => $aem_jvm_mem_opts,
      aem_port                => $aem_port,
      aem_sample_content      => $aem_sample_content,
      jvm_opts                => $jvm_opts,
      post_install_sleep_secs => $post_install_sleep_secs,
      run_mode                => $run_mode,
      tmp_dir                 => $tmp_dir,
    }

  }

}
