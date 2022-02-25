
class aem_curator::action_download_descriptor (
  $tmp_dir,
  $descriptor_file  = $::descriptor_file,
  $stack_prefix     = $::stack_prefix,
  $data_bucket_name = $::data_bucket_name,
) {

  file { "${tmp_dir}/${descriptor_file}":
    ensure => absent,
  } -> archive { "${tmp_dir}/${descriptor_file}":
    ensure => present,
    source => "s3://${data_bucket_name}/${stack_prefix}/${descriptor_file}",
  }

}
