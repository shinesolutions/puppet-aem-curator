define aem_curator::config_aem (
  $run_mode,
  $tmp_dir,
  $aem_ssl_port,
  $aem_system_users           = undef,
  $aem_base                   = '/opt',
  $aem_id                     = 'aem',
  $aem_keystore_password      = undef,
  $aem_truststore_password    = undef,
  $aem_keystore_path          = undef,
  $cert_base_url              = undef,
  $enable_create_system_users = true,
  $credentials_hash           = undef,
  $aem_ssl_method             = undef,
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
  aem_curator::config_aem_ssl { "${aem_id}: Configure AEM":
    aem_base                => $aem_base,
    aem_id                  => $aem_id,
    aem_keystore_password   => $aem_keystore_password,
    aem_keystore_path       => $aem_keystore_path,
    aem_ssl_port            => $aem_ssl_port,
    aem_truststore_password => $aem_truststore_password,
    cert_base_url           => $cert_base_url,
    run_mode                => $aem_id,
    tmp_dir                 => $tmp_dir,
    aem_ssl_method          => $aem_ssl_method,
  }
}
