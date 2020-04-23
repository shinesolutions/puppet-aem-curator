define aem_curator::config_aem (
  $run_mode,
  $tmp_dir,
  $aem_ssl_port,
  $aem_system_users           = undef,
  $aem_base                   = '/opt',
  $aem_id                     = 'aem',
  $aem_keystore_password      = undef,
  $aem_keystore_path          = undef,
  $cert_base_url              = undef,
  $enable_create_system_users = true,
  $credentials_hash           = undef
) {

  validate_bool($enable_create_system_users)

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  if $enable_create_system_users {
    # Create system users and configure their usernames for password reset during provisioning
    aem_resources::create_system_users { "${aem_id}: Create system users":
      aem_system_users => $aem_system_users,
      aem_id           => $aem_id,
      before           => Aem_node["${aem_id}: Create AEM Password Reset Activator config node"],
    }
  } else {
    aem_curator::config_aem_system_users {"${aem_id}: Change System Users Passwords":
      aem_id           => $aem_id,
      aem_system_users => $aem_system_users,
      credentials_hash => $credentials_hash,
      before           => Aem_node["${aem_id}: Create AEM Password Reset Activator config node"],
    }
  }

  aem_node { "${aem_id}: Create AEM Password Reset Activator config node":
    ensure => present,
    name   => 'com.shinesolutions.aem.passwordreset.Activator',
    path   => '/apps/system/config',
    type   => 'sling:OsgiConfig',
    aem_id => $aem_id,
  } -> aem_config_property { "${aem_id}: Configure system usernames for AEM Password Reset Activator to process":
    ensure           => present,
    name             => 'pwdreset.authorizables',
    type             => 'String[]',
    value            => ['admin', 'orchestrator', 'replicator', 'deployer', 'exporter', 'importer'],
    run_mode         => $run_mode,
    config_node_name => 'com.shinesolutions.aem.passwordreset.Activator',
    aem_id           => $aem_id,
  } -> aem_user { "${aem_id}: Update replication-service user permission":
    # Deny replicate permission for replication-service user to prevent agents from being published
    ensure     => has_permission,
    name       => 'replication-service',
    path       => '/home/users/system/',
    permission => {
      '/etc/replication/agents.author'  => ['replicate:false'],
      '/etc/replication/agents.publish' => ['replicate:false'],
    },
    aem_id     => $aem_id,
  } -> aem_node { "${aem_id}: Create AEM Health Check Servlet config node":
    ensure => present,
    name   => 'com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck',
    path   => '/apps/system/config',
    type   => 'sling:OsgiConfig',
    aem_id => $aem_id,
  } -> aem_config_property { "${aem_id}: Configure AEM Health Check Servlet ignored bundles":
    ensure           => present,
    name             => 'bundles.ignored',
    type             => 'String[]',
    run_mode         => $run_mode,
    config_node_name => 'com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck',
    value            => [
      'org.apache.sling.jcr.webdav',
      'org.apache.sling.jcr.davex',
      'com.adobe.granite.crx-explorer',
      'com.adobe.granite.crxde-lite',
      'com.adobe.acs.acs-aem-commons-bundle-twitter',
    ],
    aem_id           => $aem_id,
  }

  $provisioning_steps = [
    Aem_config_property["${aem_id}: Configure AEM Health Check Servlet ignored bundles"],
    Aem_user["${aem_id}: Update replication-service user permission"],
  ]

  if $run_mode == 'author' {
    aem_resources::author_remove_default_agents { "${aem_id}: Remove default author agents":
      aem_id  => $aem_id,
      require => Aem_aem["${aem_id}: Wait until aem health check is ok"]
    }
    $all_provisioning_steps = concat(
      $provisioning_steps,
      Aem_resources::Author_remove_default_agents["${aem_id}: Remove default author agents"],
    )
  } else {
    aem_resources::publish_remove_default_agents { "${aem_id}: Remove default publish agents":
      aem_id  => $aem_id,
      require => Aem_aem["${aem_id}: Wait until aem health check is ok"]
    }
    $all_provisioning_steps = concat(
      $provisioning_steps,
      Aem_resources::Publish_remove_default_agents["${aem_id}: Remove default publish agents"],
    )
  }

  # Ensure login page is still ready after all provisioning steps and before stopping AEM.
  aem_aem { "${aem_id}: Ensure login page is ready":
    ensure  => login_page_is_ready,
    require => $all_provisioning_steps,
    aem_id  => $aem_id,
  }

  $keystore_path = pick(
    $aem_keystore_path,
    "${aem_base}/aem/${aem_id}/crx-quickstart/ssl/aem.ks",
  )

  file { dirname($keystore_path):
    ensure  => directory,
    mode    => '0770',
    owner   => "aem-${aem_id}",
    group   => "aem-${aem_id}",
    require => [
      Aem_aem["${aem_id}: Ensure login page is ready"],
    ],
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

  java_ks { "cqse:${keystore_path}":
    ensure       => latest,
    certificate  => "${tmp_dir}/${aem_id}/aem.cert",
    private_key  => "${tmp_dir}/${aem_id}/aem.key",
    password     => $aem_keystore_password,
    trustcacerts => true,
    require      => $java_ks_require,
  } -> file { $keystore_path:
    ensure => file,
    mode   => '0640',
    owner  => "aem-${aem_id}",
    group  => "aem-${aem_id}",
  } -> aem_resources::author_publish_enable_ssl { "${aem_id}: Enable SSL":
    run_mode            => $run_mode,
    port                => $aem_ssl_port,
    keystore            => $keystore_path,
    keystore_password   => $aem_keystore_password,
    keystore_key_alias  => 'cqse',
    truststore          => '/usr/java/default/jre/lib/security/cacerts',
    truststore_password => 'changeit',
    aem_id              => $aem_id,
  }
}
