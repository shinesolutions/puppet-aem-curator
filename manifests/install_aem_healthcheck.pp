define aem_curator::install_aem_healthcheck(
  $aem_healthcheck_version,
  $tmp_dir,
  $aem_base               = '/opt',
  $aem_id                 = 'aem',
  $aem_healthcheck_source = undef,
) {

  $_aem_healthcheck_source = pick(
    $aem_healthcheck_source,
    "https://repo.maven.apache.org/maven2/com/shinesolutions/aem-healthcheck-content/${aem_healthcheck_version}/aem-healthcheck-content-${aem_healthcheck_version}.zip",
  )

  # Install AEM Health Check using aem::crx::package file type which will place
  # the artifact in AEM install directory and it will be installed when AEM
  # starts up.
  archive { "${tmp_dir}/${aem_id}/aem-healthcheck-content-${aem_healthcheck_version}.zip":
    ensure => present,
    source => $_aem_healthcheck_source,
  } -> aem::crx::package { "${aem_id}: aem-healthcheck" :
    ensure => present,
    type   => 'file',
    home   => "${aem_base}/aem/${aem_id}",
    source => "${tmp_dir}/${aem_id}/aem-healthcheck-content-${aem_healthcheck_version}.zip",
    user   => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  }
}
