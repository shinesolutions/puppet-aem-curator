class aem_curator::action_flush_dispatcher_cache (
  $docroot     = $::docroot,
) {
  file { "${docroot}/*":
  ensure  => directory,
  purge   => true,
  force   => true,
  path    => $docroot,
  recurse => true,
  }
}
