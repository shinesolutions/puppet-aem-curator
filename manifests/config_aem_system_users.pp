define aem_curator::config_aem_system_users (
  $aem_id,
  $credentials_hash,
  $enable_default_passwords = false,
) {

  if $enable_default_passwords == false {
    aem_resources::change_system_users_password { 'Change system users password for author-primary':
      orchestrator_new_password => $credentials_hash['orchestrator'],
      replicator_new_password   => $credentials_hash['replicator'],
      deployer_new_password     => $credentials_hash['deployer'],
      exporter_new_password     => $credentials_hash['exporter'],
      importer_new_password     => $credentials_hash['importer'],
      aem_id                    => $aem_id,
    } -> aem_user { "${aem_id}: Set admin password for current stack":
      ensure       => password_changed,
      name         => 'admin',
      path         => '/home/users/d',
      old_password => 'admin',
      new_password => $credentials_hash['admin'],
      aem_id       => $aem_id,
    }
  }

}
