File {
  backup => false,
}

class aem_curator::config_author_dispatcher (
  $base_dir,
  $dispatcher_conf_dir,
  $docroot_dir,
  $exec_path,
  $virtual_hosts_dir,
  $author_host,
  $author_port,
  $author_secure,
  $ssl_cert,
  $tmp_dir,
  $apache_http_port  = '80',
  $apache_https_port = '443',
  $aem_id            = 'author-dispatcher',
) {

  aem_resources::author_dispatcher_set_config { 'Set puppet-aem-resources config file for author-dispatcher':
    dispatcher_conf_dir => $dispatcher_conf_dir,
    virtual_hosts_dir   => $virtual_hosts_dir,
    docroot_dir         => $docroot_dir,
    ssl_cert            => $ssl_cert,
    author_host         => $author_host,
    author_port         => $author_port,
  } -> exec { 'httpd -k graceful':
    cwd  => $tmp_dir,
    path => $exec_path,
  } -> tcp_conn_validator { "Ensure author-dispatcher is listening on http port ${apache_http_port}" :
    host      => 'localhost',
    port      => $apache_http_port,
    try_sleep => 5,
    timeout   => 60,
  } -> tcp_conn_validator { "Ensure author-dispatcher is listening on https port ${apache_https_port}" :
    host      => 'localhost',
    port      => $apache_https_port,
    try_sleep => 5,
    timeout   => 60,
  }

}
