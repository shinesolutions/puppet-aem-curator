#== Class: aem_curator::config_author_standby
# Configuration AEM Author
#
# === Parameters
# [*jvm_mem_opts*]
#   User defined JVM Memory options to be passed to the AEM Author
#
# [*jmxremote_port*]
#   User defined Port on which JMXRemote is listening
#
# [*jvm_opts*]
#   User defined additional JVM options
#
# === Copyright
#
# Copyright © 2017 Shine Solutions Group, unless otherwise noted.
#

File {
  backup => false,
}

class aem_curator::config_author_standby (
  $author_port,
  $author_protocol,
  $author_primary_host,
  $credentials_file,
  $crx_quickstart_dir,
  $enable_crxde,
  $enable_default_passwords,
  $puppet_conf_dir,
  $tmp_dir,
  $aem_id                       = 'author',
  $aem_version                  = '6.2',
  $enable_aem_clean_directories = false,
  $data_volume_mount_point      = undef,
  $delete_repository_index      = false,
  $jmxremote_port               = '5982',
  $jvm_mem_opts                 = undef,
  $jvm_opts                     = undef,
  $run_mode                     = 'author',
) {

  if !defined(File[$tmp_dir]) {
    file { $tmp_dir:
      ensure => directory,
    }
  }

  $credentials_hash = loadjson("${tmp_dir}/${credentials_file}")

  Exec {
    cwd     => $tmp_dir,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    timeout => 0,
  }

  exec { "${aem_id}: Set repository ownership":
    command => "chown -R aem-${aem_id}:aem-${aem_id} ${data_volume_mount_point}",
    before  => Service['aem-author'],
  }

  if $delete_repository_index {

    file { "${crx_quickstart_dir}/repository/index/":
      ensure  => absent,
      recurse => true,
      purge   => true,
      force   => true,
      before  => Service['aem-author'],
    }

  }

  if $jvm_mem_opts {
    file_line { "${aem_id}: Set JVM memory opts":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_MEM_OPTS='${jvm_mem_opts}'",
      match  => '^JVM_MEM_OPTS',
      notify => Service['aem-author'],
    }
  }

  if $jmxremote_port {
    file_line { "${aem_id}: enable JMXRemote":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_OPTS=\"\$JVM_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=${jmxremote_port} -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=true -Djava.rmi.server.hostname=localhost\"",
      after  => '^JVM_OPTS',
      notify => Service['aem-author'],
    }
  }

  if $jvm_opts {
    file_line { "${aem_id}: Add custom JVM OPTS settings":
      ensure => present,
      path   => "${crx_quickstart_dir}/bin/start-env",
      line   => "JVM_OPTS=\"\$JVM_OPTS ${jvm_opts} \"",
      after  => '^JVM_OPTS=\"\$JVM_OPTS',
      notify => Service['aem-author'],
    }
  }

  if $enable_aem_clean_directories {
    $list_clean_directories = [
      'logs',
      'threaddumps'
    ]

    $list_clean_directories.each | Integer $index, String $clean_directory| {
      exec { "${aem_id}: Cleaning directory ${crx_quickstart_dir}/${clean_directory}/":
        command => "rm -fr ${crx_quickstart_dir}/${clean_directory}/*",
        before  => Service['aem-author'],
      }
    }
  }

  aem_resources::puppet_aem_resources_set_config { 'Set puppet-aem-resources config file for author-primary':
    conf_dir => $puppet_conf_dir,
    protocol => $author_protocol,
    host     => 'localhost',
    port     => $author_port,
    debug    => false,
    aem_id   => $aem_id,
  } -> aem_resources::author_standby_set_config { 'Set author-standby config':
    crx_quickstart_dir => $crx_quickstart_dir,
    primary_host       => $author_primary_host,
    aem_version        => $aem_version,
  } -> service { 'aem-author':
    ensure => 'running',
    enable => true,
  } -> tcp_conn_validator { "${aem_id}: Wait until AEM Author Standby is listening on port ${author_port}":
    host      => '127.0.0.1',
    port      => $author_port,
    try_sleep => 5,
    timeout   => 300,
  }
}
