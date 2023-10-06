
class aem_curator::action_deploy_artifacts (
  $tmp_dir,
  $author_port,
  $author_secure,
  $log_dir,
  $publish_port,
  $publish_secure,
  $aem_id                     = undef,
  $aem_username               = $::aem_username,
  $aem_password               = $::aem_password,
  $aws_region                 = $::aws_region,
  $source_ip                  = $::source_ip,
  $aem_port                   = $::aem_port,
  $deployment_sleep_seconds   = 10,
  $component                  = $::component,
  $source_stack_prefix        = $::source_stack_prefix
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
) {

  exec { "${aem_id}: Execute VLT content sync command"
    command => @("CMD"/L), 
      /opt/aws-stack-provisioner/aem-tools/${vlt_dir}/vlt rcp -b 100 -r -n -u \
      http://${aem_username}:${aem_password}@${source_ip}:${aem_port}/crx/-/jcr:root/content/ \
      http://${aem_username}:${aem_password}@localhost:${aem_port}/crx/-/jcr:root/content/, 
    | CMD
    path    => '/usr/local/bin/:/bin/',
  }
}

