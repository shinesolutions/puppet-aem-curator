define aem_curator::config_truststore (
  $aem_id                     = 'aem',
  $aem_username               = undef,
  $aem_password               = undef,
  $enable_truststore_creation = false,
  $file                       = undef,
  $tmp_dir                    = '/tmp',
  $truststore_password        = undef,
) {
  if $enable_truststore_creation {
    if $file {
      archive { "${tmp_dir}/truststore.p12":
        ensure => present,
        source => $file,
        before => Aem_truststore[aem_truststore]
      }

      $params_create_truststore = {
        'aem_resources::create_truststore' => {
          file => "${tmp_dir}/truststore.p12"
        }
      }
    } else {
      $params_create_truststore = {
        'aem_resources::create_truststore' => {
          file => undef
        }
      }
    }

    $default_params_create_truststore = {
      aem_id              => $aem_id,
      aem_username        => $aem_username,
      aem_password        => $aem_password,
      truststore_password => $truststore_password,
    }

    create_resources(
      'aem_resources::create_truststore',
      $params_create_truststore,
      $default_params_create_truststore
    )

    if $file {
      file { "${tmp_dir}/truststore.p12":
        ensure => absent,
        require => Aem_truststore[aem_truststore]
      }
    }
  }
}
