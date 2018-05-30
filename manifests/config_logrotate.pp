class aem_curator::config_logrotate (
  $config = {},
  $rules = {},
  $config_default_params = {},
  $rules_default_params = {},
) {

  create_resources(
    logrotate::conf,
    $config,
    $config_default_params
  )

  create_resources(
    logrotate::rule,
    $rules,
    $rules_default_params
  )
}
