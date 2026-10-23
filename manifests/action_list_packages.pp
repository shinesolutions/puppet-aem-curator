class aem_curator::action_list_packages (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $aem_instances,
  $package_groups             = [],
  $aem_username               = getvar('::aem_username'),
  $aem_password               = getvar('::aem_password'),
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
) {

  $aem_instances.each | Integer $index, Hash $aem_instance | {
    aem_aem { "${aem_instance['aem_id']}: Wait until CRX Package Manager is ready before listing packages by groups":
      ensure                     => aem_package_manager_is_ready,
      retries_max_tries          => $retries_max_tries,
      retries_base_sleep_seconds => $retries_base_sleep_seconds,
      retries_max_sleep_seconds  => $retries_max_sleep_seconds,
      aem_id                     => $aem_instance['aem_id'],
      aem_username               => $aem_username,
      aem_password               => $aem_password,
    } -> aem_aem { "${aem_instance['aem_id']}: List packages by groups":
      ensure         => packages_listed,
      package_groups => $package_groups,
      run_mode       => $aem_instance['run_mode'],
      aem_id         => $aem_instance['aem_id'],
      aem_username   => $aem_username,
      aem_password   => $aem_password,
    }

  }

}
