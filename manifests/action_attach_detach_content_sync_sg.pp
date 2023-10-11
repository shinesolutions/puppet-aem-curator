
class aem_curator::action_attach_detach_content_sync_sg (
  $aem_host,
  $aem_id                     = undef,
  $action                     = $::action,
  $security_group_ids         = $::security_group_ids,
) {

  exec { "${aem_id}: ${action} security group to allow access to target stack from source stack for content sync":
    command => "aws ec2 modify-instance-attribute --instance-id ${aem_host} --groups ${security_group_ids}",
    path    => '/usr/local/bin/:/bin/',
  }
}

