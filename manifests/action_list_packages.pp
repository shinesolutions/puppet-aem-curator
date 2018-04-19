class aem_curator::action_list_packages (
  $aem_instances,
  $package_groups = [],
  $aem_username   = $::aem_username,
  $aem_password   = $::aem_password,
) {

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    aem_aem { "${aem_instance['aem_id']}: List packages by groups":
      ensure         => packages_listed,
      package_groups => $package_groups,
      run_mode       => $aem_instance['run_mode'],
      aem_id         => $aem_instance['aem_id'],
      aem_username   => $aem_username,
      aem_password   => $aem_password,
    }

  }

}
