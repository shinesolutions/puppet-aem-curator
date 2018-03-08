class aem_curator::action_flush_dispatcher_cache (
  $docroot_dir,
) {
  file { "${docroot_dir}/*":
  ensure  => directory,
  purge   => true,
  force   => true,
  path    => $docroot_dir,
  recurse => true,
  }
}
