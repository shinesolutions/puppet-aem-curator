
class aem_curator::action_download_descriptor (
  # getvar('::name') reads the caller's top-scope variable (e.g. FACTER_name) and gives undef
  # when it is unset, like $::name on Puppet 7; OpenVox 9's strict_variables fails on it
  $tmp_dir,
  $descriptor_file  = getvar('::descriptor_file'),
  $stack_prefix     = getvar('::stack_prefix'),
  $data_bucket_name = getvar('::data_bucket_name'),
) {

  file { "${tmp_dir}/${descriptor_file}":
    ensure => absent,
  } -> archive { "${tmp_dir}/${descriptor_file}":
    ensure => present,
    source => "s3://${data_bucket_name}/${stack_prefix}/${descriptor_file}",
  }

}
