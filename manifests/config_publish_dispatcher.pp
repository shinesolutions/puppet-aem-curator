File {
  backup => false,
}

class aem_curator::config_publish_dispatcher (
  $dispatcher_conf_dir,
  $docroot_dir,
  $exec_path,
  $httpd_conf_dir,
  $publish_host,
  $publish_port,
  $publish_secure,
  $ssl_cert,
  $tmp_dir,
  $allowed_client    = undef,
  $apache_http_port  = '80',
  $apache_https_port = '443',
  $aem_id            = 'publish-dispatcher',
) {

  aem_resources::publish_dispatcher_set_config { 'Set puppet-aem-resources config file for publish-dispatcher':
    dispatcher_conf_dir => $dispatcher_conf_dir,
    httpd_conf_dir      => $httpd_conf_dir,
    docroot_dir         => $docroot_dir,
    ssl_cert            => $ssl_cert,
    allowed_client      => $allowed_client,
    publish_host        => $publish_host,
    publish_port        => $publish_port,
  } -> exec { 'httpd -k graceful':
    cwd  => $tmp_dir,
    path => $exec_path,
  } -> tcp_conn_validator { "Ensure publish-dispatcher is listening on http port ${apache_http_port}" :
    host      => 'localhost',
    port      => $apache_http_port,
    try_sleep => 5,
    timeout   => 60,
  } -> tcp_conn_validator { "Ensure publish-dispatcher is listening on https port ${apache_https_port}" :
    host      => 'localhost',
    port      => $apache_https_port,
    try_sleep => 5,
    timeout   => 60,
  }

}
