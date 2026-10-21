
class aem_curator::action_download_descriptor (
  $tmp_dir,
  $descriptor_file  = $facts['descriptor_file'],
  $stack_prefix     = $facts['stack_prefix'],
  $data_bucket_name = $facts['data_bucket_name'],
) {

  file { "${tmp_dir}/${descriptor_file}":
    ensure => absent,
  } -> archive { "${tmp_dir}/${descriptor_file}":
    ensure => present,
    source => "s3://${data_bucket_name}/${stack_prefix}/${descriptor_file}",
  }

}
