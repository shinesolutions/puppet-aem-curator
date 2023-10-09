
class aem_curator::action_content_sync_vlt (
  $aem_host,
  $author_port,
  $author_secure,
  $log_dir,
  $publish_port,
  $publish_secure,
  $vlt_dir,
  $aem_id                     = undef,
  $aem_username               = $::aem_username,
  $aem_password               = $::aem_password,
  $aws_region                 = $::aws_region,
  $source_ip                  = $::source_ip,
  $aem_port                   = $::aem_port,
  $content_sync_sg            = $::content_sync_sg,
  $deployment_sleep_seconds   = 10,
  $component                  = $::component,
  $source_stack_prefix        = $::source_stack_prefix,
  $recursive                  = $::recursive,
  $batch_size                 = $::batch_size,
  $update                     = $::update,
  $newer_only                 = $::newer_only,
  $exclude_path               = $::exclude_path,
  $content_sync_path          = $::content_sync_path,
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
) {

  $vlt_rcp_cmd_options = ""
  if $recursive {
    if $exclude_path {
      $vlt_rcp_cmd_options = "${vlt_rcp_cmd_options} -e ${exclude_path} "
    }
    $vlt_rcp_cmd_options = "-r "
  }

  if $batch_size {
    if $exclude_path {
      $vlt_rcp_cmd_options = "${vlt_rcp_cmd_options} -e ${exclude_path} "
    }
    $vlt_rcp_cmd_options = "${vlt_rcp_cmd_options} -b ${batch_size} "
  }

  if $update {
    if $exclude_path {
      $vlt_rcp_cmd_options = "${vlt_rcp_cmd_options} -e ${exclude_path} "
    }
    $vlt_rcp_cmd_options = "${vlt_rcp_cmd_options} -u "
  }

  if $newer_only {
    if $exclude_path {
      $vlt_rcp_cmd_options = "${vlt_rcp_cmd_options} -e ${exclude_path} "
    }
    $vlt_rcp_cmd_options = "${vlt_rcp_cmd_options} -n "
  }

  exec { "${aem_id}: Execute VLT content sync command":
    command => @("CMD"/L),
      /opt/aws-stack-provisioner/aem-tools/${vlt_dir}/vlt rcp ${vlt_rcp_cmd_options} \
      http://${aem_username}:${aem_password}@${source_ip}:${aem_port}/crx/-/jcr:root${content_sync_path} \
      http://${aem_username}:${aem_password}@localhost:${aem_port}/crx/-/jcr:root${content_sync_path},
    | CMD
    path    => '/usr/local/bin/:/bin/',
  }
}

