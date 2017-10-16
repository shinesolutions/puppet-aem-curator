File {
  backup => false,
}

class aem_curator::config_publish_dispatcher (
  $base_dir,
  $tmp_dir,
  $dispatcher_conf_dir,
  $httpd_conf_dir,
  $docroot_dir,
  $ssl_cert,
  $publish_host,
  $publish_port,
  $publish_secure,
  $exec_path,

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
  } -> exec { 'deploy-artifacts.sh deploy-artifacts-descriptor.json':
    path        => $exec_path,
    environment => ["https_proxy=${::cron_https_proxy}"],
    cwd         => $tmp_dir,
    command     => "${base_dir}/aem-tools/deploy-artifacts.sh deploy-artifacts-descriptor.json >>/var/log/deploy-artifacts.log 2>&1",
    onlyif      => "test `aws s3 ls s3://${::data_bucket}/${::stackprefix}/deploy-artifacts-descriptor.json | wc -l` -eq 1",
    require     => [ File["${base_dir}/aem-tools/deploy-artifacts.sh"], File["${base_dir}/aem-tools/generate-artifacts-json.py"] ],
  }

}
