File {
  backup => false,
}

class aem_curator::config_publish_dispatcher (
  $base_dir,
  $dispatcher_conf_dir,
  $docroot_dir,
  $exec_path,
  $httpd_conf_dir,
  $publish_host,
  $publish_port,
  $publish_secure,
  $ssl_cert,
  $tmp_dir,
  $aem_id = 'publish-dispatcher',
) {

  aem_resources::publish_dispatcher_set_config { 'Set puppet-aem-resources config file for publish-dispatcher':
    dispatcher_conf_dir => $dispatcher_conf_dir,
    httpd_conf_dir      => $httpd_conf_dir,
    docroot_dir         => $docroot_dir,
    ssl_cert            => $ssl_cert,
    allowed_client      => $::publish_dispatcher_allowed_client,
    publish_host        => $publish_host,
    publish_port        => $publish_port,
  } -> exec { 'httpd -k graceful':
    cwd  => $tmp_dir,
    path => $exec_path,
  }

}
