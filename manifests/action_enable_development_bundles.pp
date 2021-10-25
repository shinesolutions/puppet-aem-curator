class aem_curator::action_enable_development_bundles (
  $aem_instances,
  $aem_username     = $::aem_username,
  $aem_password     = $::aem_password,
) {

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    aem_resources::enable_development_bundles { "${aem_instance['aem_id']}: Enable Development bundles":
      run_mode     => $aem_instance['run_mode'],
      aem_id       => $aem_instance['aem_id'],
      aem_username => $::aem_username,
      aem_password => $::aem_password,
    }
  }

}
