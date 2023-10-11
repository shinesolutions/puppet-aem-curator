
class aem_curator::action_content_sync_vlt (
  $vlt_dir,
  $aem_id                     = undef,
  $aem_username               = $::aem_username,
  $aem_password               = $::aem_password,
  $aws_region                 = $::aws_region,
  $source_ip                  = $::source_ip,
  $deployment_sleep_seconds   = 10,
  $component                  = $::component,
  $aem_source_stack_password  = $::aem_source_stack_password,
  $recursive                  = $::recursive,
  $batch_size                 = $::batch_size,
  $update                     = $::update,
  $newer_only                 = $::newer_only,
  $exclude_path               = $::exclude_path,
  $content_sync_path          = $::content_sync_path,
  $retries_max_tries          = 60,
  $retries_base_sleep_seconds = 5,
  $retries_max_sleep_seconds  = 5,
  $author_port                = '4502',
  $publish_port               = '4503',
  $preview_publish_port       = '4503',
) {

  if $recursive {
    $recursive_param = '-r '
  } else {
    $recursive_param = ''
  }

  if $batch_size {
    $batch_size_param = "-b ${batch_size}"
  } else {
    $batch_size_param = ''
  }

  if $update {
    $update_param = '-u'
  } else {
    $update_param = ''
  }

  if $newer_only {
    $newer_only_param = '-n'
  } else {
    $newer_only_param = ''
  }


  if ($recursive or $batch_size or $update or $newer_only) {
    if ($exclude_path and $exclude_path !='') {
      $vlt_rcp_cmd_options = "-e ${exclude_path} ${recursive_param} ${batch_size_param} ${update_param} ${newer_only_param}"
    }
    else {
      $vlt_rcp_cmd_options = "${recursive_param} ${batch_size_param} ${update_param} ${newer_only_param}"
    }
  }

  if $component == 'author-publish-dispatcher' {
    exec { "${component}: Execute VLT content sync command on author":
      command =>  "${vlt_dir}/vlt rcp ${vlt_rcp_cmd_options} \
        http://${aem_username}:${aem_source_stack_password}@${source_ip}:${author_port}/crx/-/jcr:root${content_sync_path} \
        http://${aem_username}:${aem_password}@localhost:${author_port}/crx/-/jcr:root${content_sync_path}",
      path    => '/usr/local/bin/:/bin/',
    }
    exec { "${component}: Execute VLT content sync command on publish":
      command => "${vlt_dir}/vlt rcp ${vlt_rcp_cmd_options} \
        http://${aem_username}:${aem_source_stack_password}@${source_ip}:${publish_port}/crx/-/jcr:root${content_sync_path} \
        http://${aem_username}:${aem_password}@localhost:${publish_port}/crx/-/jcr:root${content_sync_path}",
      path    => '/usr/local/bin/:/bin/',
    }
  }

  if $component == 'author-primary' {
    exec { "${component}: Execute VLT content sync command on author-primary":
      command => "${vlt_dir}/vlt rcp ${vlt_rcp_cmd_options} \
        http://${aem_username}:${aem_source_stack_password}@${source_ip}:${author_port}/crx/-/jcr:root${content_sync_path} \
        http://${aem_username}:${aem_password}@localhost:${author_port}/crx/-/jcr:root${content_sync_path}",
      path    => '/usr/local/bin/:/bin/',
    }
  }
  if $component == 'publish' {
    exec { "${component}: Execute VLT content sync command on publish":
      command => "${vlt_dir}/vlt rcp ${vlt_rcp_cmd_options} \
        http://${aem_username}:${aem_source_stack_password}@${source_ip}:${publish_port}/crx/-/jcr:root${content_sync_path} \
        http://${aem_username}:${aem_password}@localhost:${publish_port}/crx/-/jcr:root${content_sync_path}",
      path    => '/usr/local/bin/:/bin/',
    }
  }
  if $component == 'preview-publish' {
    exec { "${component}: Execute VLT content sync command on preview-publish":
      command => "${vlt_dir}/vlt rcp ${vlt_rcp_cmd_options} \
        http://${aem_username}:${aem_source_stack_password}@${source_ip}:${preview_publish_port}/crx/-/jcr:root${content_sync_path} \
        http://${aem_username}:${aem_password}@localhost:${preview_publish_port}/crx/-/jcr:root${content_sync_path}",
      path    => '/usr/local/bin/:/bin/',
    }
  }

}

