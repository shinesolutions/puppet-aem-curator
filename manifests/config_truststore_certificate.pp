define config_truststore_certificate (
  $add_certificate = false,
  $aem_id          = 'aem',
  $force           = true,
  $aem_username    = undef,
  $aem_password    = undef,
  $file            = undef,
  $tmp_dir         = '/tmp',
) {
  if $add_certificate {
    archive { "${tmp_dir}/certificate.crt":
      ensure => present,
      source => $file,
    }

    $params_add_certificate = {
      'aem_resources::add_truststore_certificate' => {
        file => "${tmp_dir}/certificate.crt"
      }
    }

    $default_params_add_certificate = {
      ensure       => present,
      aem_id       => $aem_id,
      aem_username => $aem_username,
      aem_password => $aem_password,
      force        => $force,
    }

    create_resources(
      'aem_resources::add_truststore_certificate',
      $params_add_certificate,
      $default_params_add_certificate
    )

    file { "${tmp_dir}/certificate.crt":
      ensure => absent
    }
  }
}
