
class aem_curator::action_attach_detach_content_sync_sg (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $instance_id                = getvar('::instance_id'),
  $action                     = getvar('::action'),
  $security_group_ids         = getvar('::security_group_ids'),
) {

  exec { "${action} security group to allow access to target stack from source stack for content sync":
    command => "aws ec2 modify-instance-attribute --instance-id ${instance_id} --groups ${security_group_ids}",
    path    => '/usr/local/bin/:/bin/',
  }
}

