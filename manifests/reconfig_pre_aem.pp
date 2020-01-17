File {
  backup => false,
}

define aem_curator::reconfig_pre_aem (
  $aem_id                            = undef,
  $aem_jvm_mem_opts                  = undef,
  $enable_aem_reconfiguration        = false,
  $aem_base                          = '/opt',
  $aem_port                          = undef,
  $aem_runmodes                      = [],
  $aem_debug_port                    = undef,
  $aws_region                        = $::aws_region,
  $certificate_arn                   = undef,
  $certificate_key_arn               = undef,
  $crx_quickstart_dir                = undef,
  $data_volume_mount_point           = undef,
  $enable_aem_installation_migration = false,
  $aem_jvm_jmxremote_port            = undef,
  $tmp_dir                           = undef,
) {
  # Run Pre-reconfiguration if reconfiguration is enabled
  if $enable_aem_reconfiguration {

    # Create temp directory
    if !defined(File[$tmp_dir]) {
      file { $tmp_dir:
        ensure => directory,
      }
    }

    # Create temp directory for downloading AEM Certificate
    exec { "${aem_id}: Create ${tmp_dir}/certs":
      creates => "${tmp_dir}/certs",
      command => "mkdir -p ${tmp_dir}/certs",
      path    => '/usr/local/bin/:/bin/',
      require => [
                    File[$tmp_dir]
                  ],
    }

    # Update directopry permissions for downloading AEM Certificate
    file { "change mode ${tmp_dir}/certs":
      ensure  => directory,
      path    => "${tmp_dir}/certs",
      mode    => '0700',
      require => [
                    Exec["${aem_id}: Create ${tmp_dir}/certs"]
                  ],
    }

    if $enable_aem_installation_migration {
      # Migrating the AEM installation directories to the mounted data filesystem.
      # Before migrating we are preparing the current repository as prior
      # AEM OpenCloud version 3.11.0 the data filesystem only contains the repository.
      # This is necessary as with AEM 6.4 the AEM installation directory
      # and repository directory needs to be consistent.

      $aem_installation_new_directory = "${data_volume_mount_point}/${aem_id}"
      $aem_installation_old_directory = "${aem_base}/aem/${aem_id}"
      $source_repository_dir = "${aem_installation_old_directory}/crx-quickstart/repository"
      $tmp_repository_dir = "${data_volume_mount_point}/repository"
      $dest_repository_dir = "${aem_installation_new_directory}/crx-quickstart/repository"

      exec { "${aem_id}: Create ${tmp_repository_dir}":
        command => "mkdir -p ${tmp_repository_dir}",
        unless  => "ls -ld ${aem_installation_new_directory}",
        before  => Exec["${aem_id}: Fix data volume permissions"]
      } -> exec { "${aem_id}: Move ${source_repository_dir} to ${tmp_repository_dir}":
        command => "mv ${source_repository_dir}/* ${tmp_repository_dir}/",
        returns => [
          '0',
          '1'
        ],
        onlyif  => "ls -ld ${tmp_repository_dir}",
        timeout => 0,
      } -> exec { "${aem_id}: Remove ${source_repository_dir}":
        command => "rm -f ${source_repository_dir}",
        returns => [
          '0'
        ],
        onlyif  => "ls -ld ${tmp_repository_dir}",
      } -> exec { "${aem_id}: Move ${aem_installation_old_directory} to ${aem_installation_new_directory}":
        command => "mv ${aem_installation_old_directory} ${aem_installation_new_directory}",
        returns => [
          '0'
        ],
        onlyif  => "ls -ld ${tmp_repository_dir}",
        timeout => 0,
      } -> exec { "${aem_id}: Move ${tmp_repository_dir} to ${dest_repository_dir}":
        command => "mv ${tmp_repository_dir} ${dest_repository_dir}",
        returns => [
          '0'
        ],
        onlyif  => "ls -ld ${tmp_repository_dir}",
        timeout => 0,
      } -> exec { "${aem_id}: Remove ${aem_installation_old_directory}":
        command => "rm -fr ${aem_installation_old_directory}",
        returns => [
          '0'
        ],
        onlyif  => "ls -ld ${tmp_repository_dir}",
      } -> exec { "${aem_id}: Set link from ${aem_installation_old_directory} to ${aem_installation_new_directory}":
        command => "ln -s ${aem_installation_new_directory} ${aem_installation_old_directory}",
        returns => [
          '0'
        ],
        unless  => "ls -ld ${aem_installation_old_directory}",
      }

      exec { "${aem_id}: Fix data volume permissions":
        command => "chown -R aem-${aem_id}:aem-${aem_id} ${data_volume_mount_point}",
        before  => [
                    File["${tmp_dir}/start-env"],
                    File["${tmp_dir}/start-env"],
                    File["${tmp_dir}/start.orig"],
                  ],
      }
    }

    #
    # Default JVM opts for start-env init
    # Taken from packer-aem default jvm opts
    #
    $aem_default_jvm_opts = [
                              '-XX:+PrintGCDetails',
                              '-XX:+PrintGCTimeStamps',
                              '-XX:+PrintGCDateStamps',
                              '-XX:+PrintTenuringDistribution',
                              '-XX:+PrintGCApplicationStoppedTime',
                              '-XX:+HeapDumpOnOutOfMemoryError'
                            ]
    #
    # The aem::config from bstopp/aem module
    # unfortunatley always executes the file resource
    # "${aem_base}/aem/${aem_id}/crx-quickstart/install"
    # This is needed by our provisioing steps. Therefor
    # We cna't use the puppet module until the installation
    # of that directory is configurable. So far we have to
    # rely on the manual way to re-init start-env
    #
    #
    # aem::config { "$aem_id: re-init start-env":
    #   context_root   => undef,
    #   debug_port     => undef,
    #   group          => "aem-${aem_id}",
    #   home           => "${aem_base}/aem/${aem_id}",
    #   jvm_mem_opts   => $aem_jvm_mem_opts,
    #   jvm_opts       => $aem_default_jvm_opts.join(' '),
    #   osgi_configs   => undef,
    #   crx_packages   => undef,
    #   port           => $aem_port,
    #   runmodes       => $aem_runmodes,
    #   sample_content => false,
    #   type           => $aem_id,
    #   user           => "aem-${aem_id}",
    #   require => [
    #     Exec["service aem-${aem_id} stop"]
    #   ]
    # }

    $aem_template_type = $aem_id
    $aem_template_port = $aem_port
    $aem_template_runmodes = $aem_runmodes
    $aem_template_sample_content = false
    $aem_template_jvm_mem_opts = $aem_jvm_mem_opts
    $aem_template_jvm_opts = $aem_default_jvm_opts.join(' ')
    $aem_template_debug_port = $aem_debug_port

    # Create the env script
    file { "${tmp_dir}/start-env":
      ensure  => file,
      content => template('aem_curator/aem/start-env.erb'),
      mode    => '0775',
      owner   => "aem-${aem_id}",
      group   => "aem-${aem_id}",
    }

    # Rename the original start script.
    file { "${tmp_dir}/start.orig":
      ensure  => file,
      replace => false,
      source  => "${crx_quickstart_dir}/bin/start",
      mode    => '0775',
      owner   => "aem-${aem_id}",
      group   => "aem-${aem_id}",
    }

    # Create the start script
    file { "${tmp_dir}/start":
      ensure  => file,
      content => template('aem_curator/aem/start.erb'),
      mode    => '0775',
      owner   => "aem-${aem_id}",
      group   => "aem-${aem_id}",
      require => File["${tmp_dir}/start.orig"],
    }

    # Get SSL certificate based on ARN from:
    #  - Certificate Manager (arn:aws:acm)
    #  - IAM Server Certificates (arn:aws:iam)
    #  - S3 (s3:)
    case $certificate_arn {
      /^arn:aws:acm/: {
        exec { "${aem_id}: Download Certificate from AWS Certificate Manager using cli":
          creates => "${tmp_dir}/certs/aem.cert",
          command => "aws acm get-certificate --region ${aws_region} --certificate-arn ${certificate_arn} --output text --query Certificate > ${tmp_dir}/certs/aem.cert",
          path    => '/usr/local/bin/:/bin/',
          require => File["${tmp_dir}/certs"],
          before  => [
            File["${tmp_dir}/certs/aem.cert"]
          ],
        }
      }
      /^arn:aws:iam/: {
        $certificate_name = $certificate_arn.split('/')[1]
        exec { "${aem_id}: Download Certificate from IAM (Server Certificates) using cli":
          creates => "${tmp_dir}/certs/aem.cert",
          command => "aws iam get-server-certificate --server-certificate-name ${certificate_name} --query 'ServerCertificate.CertificateBody' --output text > ${tmp_dir}/certs/aem.cert",
          path    => '/usr/local/bin/:/bin/',
          require => File["${tmp_dir}/certs"],
          before  => [
            File["${tmp_dir}/certs/aem.cert"]
          ],
        }
      }
      /^s3:/, /^http:/, /^https:/, /^file:/ : {
        archive { "${tmp_dir}/certs/aem.cert":
          ensure  => present,
          source  => $certificate_arn,
          require => File["${tmp_dir}/certs"],
          before  => [
            File["${tmp_dir}/certs/aem.cert"]
          ],
        }
      }
      default: {
        fail('Certificate ARN can only be of types: ( arn:aws:acm | arn:aws:iam | s3: )')
      }
    }

    case $certificate_key_arn {
      /^arn:aws:secretsmanager/: {
        exec { "${aem_id}: Download Certificate key from AWS Secrets Manager using cli":
          creates => "${tmp_dir}/certs/aem.key",
          command => "aws secretsmanager get-secret-value --region ${aws_region} --secret-id ${certificate_key_arn} --output text --query SecretString > ${tmp_dir}/certs/aem.key",
          path    => '/usr/local/bin/:/bin/',
          require => File["${tmp_dir}/certs"],
          before  => [
            File["${tmp_dir}/certs/aem.key"]
          ],
        }
      }
      /^s3:/, /^http:/, /^https:/, /^file:/ : {
        archive { "${tmp_dir}/certs/aem.key":
          ensure  => present,
          source  => $certificate_key_arn,
          require => File["${tmp_dir}/certs"],
          before  => [
            File["${tmp_dir}/certs/aem.key"]
          ],
        }
      }
      default: {
        fail('Certificate Key ARN can only be of types: ( arn:aws:secretsmanager | s3: | http: | https: | file: )')
      }
    }

    # chmod the certificate
    file { "${tmp_dir}/certs/aem.cert":
      ensure => file,
      mode   => '0600',
    }

    file { "${tmp_dir}/certs/aem.key":
      ensure => file,
      mode   => '0600',
    }
  }
}
