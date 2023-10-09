
class aem_curator::action_deploy_artifacts (
  $aem_host,
  $author_port,
  $author_secure,
  $log_dir,
  $publish_port,
  $publish_secure,
  $vlt_dir,
  $aem_id                     = undef,
  $action                     = $::action,
  $security_group_ids         = $::security_group_ids,
  $deployment_sleep_seconds   = 10,
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
) {

  exec { "${aem_id}: ${action} security group to allow access to target stack from source stack for content sync"
    command => "aws ec2 modify-instance-attribute --instance-id ${aem_host} --groups ${security_group_ids}",
    path    => '/usr/local/bin/:/bin/',
  }
}

