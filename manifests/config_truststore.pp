define aem_curator::config_truststore (
  $aem_id                                     = 'aem',
  $aem_username                               = undef,
  $aem_password                               = undef,
  $enable_truststore_creation                 = false,
  $enable_truststore_deletion_before_creation = false,
  $enable_truststore_migration                = false,
  $file                                       = undef,
  $tmp_dir                                    = '/tmp',
  $truststore_password                        = undef,
) {
  if $enable_truststore_creation {

    if $enable_truststore_deletion_before_creation {
      aem_resources::remove_truststore { "${aem_id}: Remove AEM Global Truststore":
        aem_id       => $aem_id,
        aem_username => $aem_username,
        aem_password => $aem_password,
        force        => true,
      }
    }

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
        ensure  => absent,
        require => Aem_truststore[aem_truststore]
      }
    }
  } elsif $enable_truststore_migration {

    aem_resources::archive_truststore { "${aem_id}: Download AEM Global Truststore":
      file         => '/tmp/truststore.p12',
      aem_id       => $aem_id,
      aem_username => $aem_username,
      aem_password => $aem_password,
      force        => true,
    } -> aem_resources::remove_truststore { "${aem_id}: Remove AEM Global Truststore":
      aem_id       => $aem_id,
      aem_username => $aem_username,
      aem_password => $aem_password,
      force        => true,
    } -> aem_resources::create_truststore { "${aem_id}: Create new AEM Global Truststore":
      aem_id              => $aem_id,
      aem_username        => $aem_username,
      aem_password        => $aem_password,
      truststore_password => $truststore_password,
    } -> aem_truststore { "${aem_id}: Prepare AEM Global Truststore upload":
      ensure       => absent,
      aem_id       => $aem_id,
      aem_username => $aem_username,
      aem_password => $aem_password,
    } -> aem_truststore { "${aem_id}: Upload downloaded AEM Global Truststore":
      ensure       => present,
      aem_id       => $aem_id,
      aem_username => $aem_username,
      aem_password => $aem_password,
      password     => $truststore_password,
      file         => '/tmp/truststore.p12',
    } -> file { '/tmp/truststore.p12':
      ensure  => absent,
    }
  }
}
