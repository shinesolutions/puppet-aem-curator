define aem_curator::config_aem_ssl (
  $tmp_dir,
  $run_mode,
  $aem_ssl_port,
  $aem_keystore_password = undef,
  $aem_keystore_path     = undef,
  $cert_base_url         = undef,
  $aem_base              = '/opt',
  $aem_id                = 'aem',
  $aem_ssl_method        = 'jetty',
  $https_hostname        = 'localhost',
) {
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

  $x509_parts = [ 'key', 'cert' ]
  $x509_parts.each |$idx, $part| {
    ensure_resource(
      'archive',
      "${tmp_dir}/${aem_id}/aem.${part}",
      {
        'ensure' => 'present',
        'source' => "${cert_base_url}/aem.${part}",
      },
    )
  }
  $java_ks_require = $x509_parts.map |$part| {
    Archive["${tmp_dir}/${aem_id}/aem.${part}"]
  }
  case $aem_ssl_method {
  /granite/: {
    aem_resources::author_publish_enable_ssl { "${aem_id}: Enable SSL":
      https_hostname      => $https_hostname,
      port                => $aem_ssl_port,
      keystore_password   => $aem_keystore_password,
      truststore_password => 'changeit',
      keystore            => "${tmp_dir}/${aem_id}/aem.key",
      truststore          => "${tmp_dir}/${aem_id}/aem.cert",
      aem_id              => $aem_id,
      require             => $java_ks_require,
      ssl_method          => $aem_ssl_method,
    }
  }
  /jetty/: {
    $keystore_path = pick(
      $aem_keystore_path,
      "${aem_base}/aem/${aem_id}/crx-quickstart/ssl/aem.ks",
    ) file { dirname($keystore_path):
      ensure => directory,
      mode   => '0770',
      owner  => "aem-${aem_id}",
      group  => "aem-${aem_id}",
    } java_ks { "cqse:${keystore_path}":
      ensure       => latest,
      certificate  => "${tmp_dir}/${aem_id}/aem.cert",
      private_key  => "${tmp_dir}/${aem_id}/aem.key",
      password     => $aem_keystore_password,
      trustcacerts => true,
      require      => $java_ks_require,
    } file { $keystore_path:
      ensure => file,
      mode   => '0640',
      owner  => "aem-${aem_id}",
      group  => "aem-${aem_id}",
    } aem_resources::author_publish_enable_ssl { "${aem_id}: Enable SSL":
      run_mode            => $run_mode,
      port                => $aem_ssl_port,
      keystore            => $keystore_path,
      keystore_password   => $aem_keystore_password,
      keystore_key_alias  => 'cqse',
      truststore          => '/usr/java/default/jre/lib/security/cacerts',
      truststore_password => 'changeit',
      aem_id              => $aem_id,
      ssl_method          => $aem_ssl_method,
    }
  }
  default: {
    fail('SSL methods can only be of types: ( granite | jettu )')
  }
  }
}
