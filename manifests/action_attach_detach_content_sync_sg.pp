
class aem_curator::action_attach_detach_content_sync_sg (
  $instance_id                = $::instance_id,
  $action                     = $::action,
  $security_group_ids         = $::security_group_ids,
) {

  exec { "${action} security group to allow access to target stack from source stack for content sync":
    command => "aws ec2 modify-instance-attribute --instance-id ${instance_id} --groups ${security_group_ids}",
    path    => '/usr/local/bin/:/bin/',
  }
}

