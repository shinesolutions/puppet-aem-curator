define aem_curator::install_aem62(
  $aem_artifacts_base,
  $aem_healthcheck_version,
  $aem_port,
  $run_mode,
  $tmp_dir,
  $aem_base           = '/opt',
  $aem_id = 'aem',
  $aem_jvm_mem_opts   = '-Xss4m -Xmx8192m',
  $aem_sample_content = false,
  $jvm_opts = [
    '-XX:+PrintGCDetails',
    '-XX:+PrintGCTimeStamps',
    '-XX:+PrintGCDateStamps',
    '-XX:+PrintTenuringDistribution',
    '-XX:+PrintGCApplicationStoppedTime',
    '-XX:+HeapDumpOnOutOfMemoryError',
  ],
  $post_install_sleep_secs = 120,
) {

  # Retrieve the license file
  archive { "${aem_base}/aem/${aem_id}/license.properties":
    ensure  => present,
    source  => "${aem_artifacts_base}/license-6.2.properties",
    cleanup => false,
    require => File["${aem_base}/aem/${aem_id}"],
  } -> file { "${aem_base}/aem/${aem_id}/license.properties":
    ensure => file,
    mode   => '0440',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  }

  # Retrieve the cq-quickstart jar
  archive { "${aem_base}/aem/${aem_id}/aem-${run_mode}-${aem_port}.jar":
    ensure  => present,
    source  => "${aem_artifacts_base}/AEM_6.2_Quickstart.jar",
    cleanup => false,
    require => File["${aem_base}/aem/${aem_id}"],
  } -> file { "${aem_base}/aem/${aem_id}/aem-${run_mode}-${aem_port}.jar":
    ensure  => file,
    mode    => '0775',
    owner   => "aem-${aem_id}",
    group   => "aem-${aem_id}",
    require => File["${aem_base}/aem/${aem_id}"],
  }

  # Install AEM Health Check using aem::crx::package file type which will place
  # the artifact in AEM install directory and it will be installed when AEM
  # starts up.
  archive { "${tmp_dir}/${aem_id}/aem-healthcheck-content-${aem_healthcheck_version}.zip":
    ensure => present,
    source => "http://central.maven.org/maven2/com/shinesolutions/aem-healthcheck-content/${aem_healthcheck_version}/aem-healthcheck-content-${aem_healthcheck_version}.zip",
  } -> aem::crx::package { "${aem_id}: aem-healthcheck" :
    ensure => present,
    type   => 'file',
    home   => "${aem_base}/aem/${aem_id}",
    source => "${tmp_dir}/${aem_id}/aem-healthcheck-content-${aem_healthcheck_version}.zip",
    user   => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  }

  aem::instance { $aem_id:
    source         => "${aem_base}/aem/${aem_id}/aem-${run_mode}-${aem_port}.jar",
    home           => "${aem_base}/aem/${aem_id}",
    user           => "aem-${aem_id}",
    group          => "aem-${aem_id}",
    type           => $run_mode,
    port           => $aem_port,
    sample_content => $aem_sample_content,
    jvm_mem_opts   => $aem_jvm_mem_opts,
    jvm_opts       => $jvm_opts.join(' '),
    status         => 'running',
  } -> exec { "${aem_id}: Manual delay to let AEM become ready":
    command => "sleep ${post_install_sleep_secs}",
  } -> aem_aem { "${aem_id}: Wait until login page is ready":
    ensure => login_page_is_ready,
    aem_id => $aem_id,
  } -> aem_aem { "${aem_id}: Wait until aem health check is ok":
    ensure => aem_health_check_is_ok,
    tags   => 'deep',
    aem_id => $aem_id,
  }

}
