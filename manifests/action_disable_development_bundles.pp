class aem_curator::action_disable_development_bundles (
  $aem_instances,
  $aem_username     = $facts['aem_username'],
  $aem_password     = $facts['aem_password'],
) {

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    aem_resources::disable_development_bundles { "${aem_instance['aem_id']}: Disable Development bundles":
      run_mode     => $aem_instance['run_mode'],
      aem_id       => $aem_instance['aem_id'],
      aem_username => $facts['aem_username'],
      aem_password => $facts['aem_password'],
    }
  }

}
