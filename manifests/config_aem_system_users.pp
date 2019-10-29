define aem_curator::config_aem_system_users (
  $aem_id,
  $aem_system_users,
  $credentials_hash,
  $aem_username             = undef,
  $aem_password             = undef,
  $enable_default_passwords = false,
  $force                    = true,
) {

  if $enable_default_passwords == false {

    # Add the non-default password from credentials_hash to aem_system_users as
    # new password. The old password is simply the default value which is the
    # same as the username.
    # Need to rely on deep_merge because Puppet doesn't allow assigning value
    # to the original aem_system_users hash.
    $aem_system_users_with_password = {
      deployer => {
        old_password => 'deployer',
        new_password => $credentials_hash['deployer'],
      },
      exporter => {
        old_password => 'exporter',
        new_password => $credentials_hash['exporter'],
      },
      importer => {
        old_password => 'importer',
        new_password => $credentials_hash['importer'],
      },
      orchestrator => {
        old_password => 'orchestrator',
        new_password => $credentials_hash['orchestrator'],
      },
      replicator => {
        old_password => 'replicator',
        new_password => $credentials_hash['replicator'],
      }
    }
    $merged_aem_system_users = deep_merge($aem_system_users, $aem_system_users_with_password)

    aem_resources::change_system_users_password { "${aem_id}: Change system users password":
      aem_id           => $aem_id,
      aem_password     => $aem_password,
      aem_system_users => $merged_aem_system_users,
      aem_username     => $aem_username,
    } -> aem_user { "${aem_id}: Set admin password for current stack":
      ensure       => password_changed,
      force        => $force,
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
