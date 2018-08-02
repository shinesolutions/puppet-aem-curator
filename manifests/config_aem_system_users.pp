define aem_curator::config_aem_system_users (
  $aem_id,
  $aem_system_users,
  $credentials_hash,
  $aem_username = undef,
  $aem_password = undef,
  $enable_default_passwords = false,
) {

  if $enable_default_passwords == false {

    aem_resources::change_system_users_password { "${aem_id}: Change system users password":
      aem_id           => $aem_id,
      aem_password     => $aem_password,
      aem_system_users => $aem_system_users,
      aem_username     => $aem_username,
      credentials_hash => $credentials_hash,
    } -> aem_user { "${aem_id}: Set admin password for current stack":
      ensure       => password_changed,
      name         => $aem_system_users[admin][name],
      path         => $aem_system_users[admin][path],
      old_password => 'admin',
      new_password => $credentials_hash['admin'],
      aem_username => $aem_username,
      aem_password => $aem_password,
      aem_id       => $aem_id,
    }
  }

}
