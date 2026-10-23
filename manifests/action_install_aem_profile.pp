class aem_curator::action_install_aem_profile (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $aem_artifacts_base         = getvar('::aem_artifacts_base'),
  $aem_license_base           = getvar('::aem_license_base'),
  $aem_base                   = getvar('::aem_base'),
  $aem_healthcheck_version    = getvar('::aem_healthcheck_version'),
  $aem_id                     = getvar('::aem_id'),
  $aem_port                   = getvar('::aem_port'),
  $aem_debug_port             = getvar('::aem_debug_port'),
  $aem_profile                = getvar('::aem_profile'),
  $aem_ssl_port               = getvar('::aem_ssl_port'),
  $tmp_dir                    = getvar('::tmp_dir'),
) {

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  if !defined(File[$tmp_dir]) {
    file { $tmp_dir:
      ensure => directory,
    }
  }
  if !defined(File["${tmp_dir}/${aem_id}"]) {
    file { "${tmp_dir}/${aem_id}":
      ensure => directory,
      mode   => '0700',
    }
  }

  aem_curator::install_aem_profile { "${aem_id}: Install AEM profile ${aem_profile}":
    aem_artifacts_base      => $aem_artifacts_base,
    aem_license_base        => $aem_license_base,
    aem_base                => $aem_base,
    aem_healthcheck_version => $aem_healthcheck_version,
    aem_id                  => $aem_id,
    aem_port                => $aem_port,
    aem_debug_port          => $aem_debug_port,
    aem_profile             => $aem_profile,
    aem_ssl_port            => $aem_ssl_port,
    run_mode                => $aem_id,
    tmp_dir                 => $tmp_dir,
  }
}
