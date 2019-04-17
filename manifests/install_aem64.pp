define aem_curator::install_aem64(
  $aem_license_base,
  $aem_artifacts_base,
  $aem_healthcheck_version,
  $aem_port,
  $run_modes,
  $tmp_dir,
  $aem_base                = '/opt',
  $aem_id                  = 'aem',
  $aem_healthcheck_source  = undef,
  $aem_jvm_mem_opts        = '-Xss4m -Xmx8192m',
  $aem_sample_content      = false,
  $aem_jvm_opts            = [
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

  # Retrieve the license file
  archive { "${aem_base}/aem/${aem_id}/license.properties":
    ensure  => present,
    source  => "${aem_license_base}/license-6.4.properties",
    cleanup => false,
    require => File["${aem_base}/aem/${aem_id}"],
  } -> file { "${aem_base}/aem/${aem_id}/license.properties":
    ensure => file,
    mode   => '0440',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  }

  # Retrieve the cq-quickstart jar
  archive { "${aem_base}/aem/${aem_id}/aem-${aem_id}-${aem_port}.jar":
    ensure  => present,
    source  => "${aem_artifacts_base}/AEM_6.4_Quickstart.jar",
    cleanup => false,
    require => File["${aem_base}/aem/${aem_id}"],
  } -> file { "${aem_base}/aem/${aem_id}/aem-${aem_id}-${aem_port}.jar":
    ensure  => file,
    mode    => '0775',
    owner   => "aem-${aem_id}",
    group   => "aem-${aem_id}",
    require => File["${aem_base}/aem/${aem_id}"],
  }

  aem_curator::install_aem_healthcheck {"Install AEM Healthcheck for ${aem_id}":
    aem_base                => $aem_base,
    aem_healthcheck_source  => $aem_healthcheck_source,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_id                  => $aem_id,
    tmp_dir                 => $tmp_dir,
  }

  aem::instance { $aem_id:
    source         => "${aem_base}/aem/${aem_id}/aem-${aem_id}-${aem_port}.jar",
    home           => "${aem_base}/aem/${aem_id}",
    user           => "aem-${aem_id}",
    group          => "aem-${aem_id}",
    type           => $aem_id,
    runmodes       => $run_modes,
    port           => $aem_port,
    sample_content => $aem_sample_content,
    jvm_mem_opts   => $aem_jvm_mem_opts,
    jvm_opts       => $aem_jvm_opts.join(' '),
    start_opts     => $aem_start_opts,
    status         => 'running',
  } -> exec { "${aem_id}: Manual delay to let AEM become ready":
    command => "sleep ${post_install_sleep_secs}",
  } -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure                     => login_page_is_ready,
    aem_id                     => $aem_id,
    retries_max_tries          => 120,
    retries_base_sleep_seconds => 5,
    retries_max_sleep_seconds  => 5,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok":
    ensure => aem_health_check_is_ok,
    tags   => 'deep',
    aem_id => $aem_id,
  }

}
