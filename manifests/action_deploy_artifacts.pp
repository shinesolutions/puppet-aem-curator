
class aem_curator::action_deploy_artifacts (
  $tmp_dir,
  $apache_conf_dir,
  $author_port,
  $author_secure,
  $dispatcher_conf_dir,
  $docroot_dir,
  $log_dir,
  $publish_port,
  $publish_secure,
  $static_assets_dir,
  $ssl_cert,
  $virtual_hosts_dir,
  $aem_id                     = undef,
  $aem_username               = $::aem_username,
  $aem_password               = $::aem_password,
  $author_host                = $::authorhost,
  $descriptor_file            = $::descriptor_file,
  $deployment_sleep_seconds   = 10,
  $component                  = $::component,
  $publish_host               = $::publishhost,
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
  $httpd_graceful_restart     = true,
) {

  Aem_aem {
    retries_max_tries          => $retries_max_tries,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
  }

  Aem_package {
    retries_max_tries          => $retries_max_tries,
    retries_base_sleep_seconds => $retries_base_sleep_seconds,
    retries_max_sleep_seconds  => $retries_max_sleep_seconds,
  }

  # Load descriptor file
  $descriptor_hash = loadjson("${tmp_dir}/${descriptor_file}")

  # Retrieve component hash, if empty then there's no artifact to deploy
  $component_hash = $descriptor_hash[$component]
  notify { "Component descriptor: ${component_hash}": }

  if $component_hash {

    # Deploy AEM Dispatcher artifacts
    $artifacts = $component_hash['artifacts']
    if $artifacts {
      notify { "AEM Dispatcher artifacts to deploy: ${artifacts}": }
      class { 'aem_curator::action_deploy_dispatcher_artifacts':
        artifacts              => $artifacts,
        path                   => "${tmp_dir}/artifacts",
        apache_conf_dir        => $apache_conf_dir,
        author_port            => $author_port,
        author_secure          => $author_secure,
        author_host            => $author_host,
        dispatcher_conf_dir    => $dispatcher_conf_dir,
        docroot_dir            => $docroot_dir,
        log_dir                => $log_dir,
        publish_host           => $publish_host,
        publish_port           => $publish_port,
        publish_secure         => $publish_secure,
        static_assets_dir      => $static_assets_dir,
        ssl_cert               => $ssl_cert,
        virtual_hosts_dir      => $virtual_hosts_dir,
        httpd_graceful_restart => $httpd_graceful_restart,
      }
    } else {
      notify { "No artifacts defined for component: ${component} in descriptor file: ${descriptor_file}. No Dispatcher artifacts to deploy": }
    }

    # Deploy Author/Publish AEM packages
    $packages = $component_hash['packages']
    if $packages {
      notify { "AEM packages to deploy: ${packages}": }
      aem_resources::deploy_packages { 'Deploy packages':
        packages                   => $packages,
        path                       => "${tmp_dir}/packages",
        aem_id                     => $aem_id,
        aem_username               => $aem_username,
        aem_password               => $aem_password,
        sleep_seconds              => $deployment_sleep_seconds,
        retries_max_tries          => $retries_max_tries,
        retries_base_sleep_seconds => $retries_base_sleep_seconds,
        retries_max_sleep_seconds  => $retries_max_sleep_seconds,
      }
    } else {
      notify { "No packages defined for component: ${component} in descriptor file: ${descriptor_file}. No AEM package to deploy": }
    }

  } else {
    notify { "Component: ${component} not found in descriptor file: ${descriptor_file}. Nothing to deploy.": }
  }
}

