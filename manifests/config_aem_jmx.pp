#== Define: aem_curator::config_aem_jmx
# Configure JMX for AEM
#
# === Parameters
# [*aem_id*]
#   AEM ID for configuring AEM
#   default: aem
#
# [*jmxremote_configuration_file_path*]
#   JMX Configuration file path
#   default: /etc/jmx.properties
#
# [*jmxremote_port*]
#   User defined Port on which JMXRemote is listening
#   default: 5982
#
# [*jmxremote_enable_authentication*]
#  Enable authentication for JMX
#  default: false
#
# [*jmxremote_enable_ssl*]
#  Enable SSL for JMX
#  default: false
#
# [*jmxremote_keystore_path*]
#  JMX Java Keystore path
#  default: undef
#
# [*jmxremote_keystore_password*]
#  JMX Java Keystore password
#  default: changeit
#
# [*jmxremote_monitoring_username*]
#  JMX Username of the Monitoring user
#  default: undef
#
# [*jmxremote_monitoring_user_password*]
#  JMX User password of the monitoring user
#  default: undef
#
# === Copyright
#
# Copyright © 2021 Shine Solutions Group Group, unless otherwise noted.
#

define aem_curator::config_aem_jmx (
  $aem_id                                                = 'aem',
  $jmxremote_configuration_file_path                     = '/etc/jmx.properties',
  $jmxremote_port                                        = '5982',
  $jmxremote_enable_authentication                       = false,
  $jmxremote_enable_ssl                                  = false,
  $jmxremote_keystore_path                               = undef,
  $jmxremote_keystore_password                           = 'changeit',
  $jmxremote_monitoring_username                         = undef,
  $jmxremote_monitoring_user_password                    = undef,
) {
  # Setting up JMX Remote default properties
  $jmxremote_options = [
    'com.sun.management.jmxremote=true',
    "com.sun.management.jmxremote.port=${jmxremote_port}",
    'com.sun.management.jmxremote.local.only=true',
    'java.rmi.server.hostname=localhost'
  ]
  # Configure SSL for JMX
  if $jmxremote_enable_ssl {
    # Settting up JMX Remote enabled SSL properties
    $jmxremote_ssl_options = [
      'com.sun.management.jmxremote.ssl=true',
      "com.sun.management.jmxremote.ssl.config.file=${jmxremote_configuration_file_path}", #  Filepath containing the SSL Keystore properties
      "javax.net.ssl.keyStore=${jmxremote_keystore_path}",
      "javax.net.ssl.keyStorePassword=${jmxremote_keystore_password}"
    ]
  } else {
    # Settting up JMX Remote disabled SSL properties
    $jmxremote_ssl_options = [
      'com.sun.management.jmxremote.ssl=false',
    ]
  }

  # Configure Authentication for JMX
  if $jmxremote_enable_authentication {
    # Set Variables for configuring JMX on AEM
    $jmxremote_password_file_path = "/etc/jmx-${aem_id}.password"
    $jmxremote_access_file_path = "/etc/jmx-${aem_id}.access"

    # Creating JMX Password file
    file { $jmxremote_password_file_path:
      content => template('aem_curator/config/jmx.password'),
      mode    => '0400',
      owner   => "aem-${aem_id}",
      group   => "aem-${aem_id}",
    }

    # Creating JMX Access file
    file { $jmxremote_access_file_path:
      content => template('aem_curator/config/jmx.access'),
      mode    => '0400',
      owner   => "aem-${aem_id}",
      group   => "aem-${aem_id}",
    }

    $jmxremote_authentication_options = [
      'com.sun.management.jmxremote.authenticate=true',
      "com.sun.management.jmxremote.password.file=${jmxremote_password_file_path}",
      "com.sun.management.jmxremote.access.file=${jmxremote_access_file_path}"
    ]
  } else {
    $jmxremote_authentication_options = [
      'com.sun.management.jmxremote.authenticate=false'
    ]
  }

  # Creating JMX property file
  file { $jmxremote_configuration_file_path:
    content => template('aem_curator/config/jmx.properties.erb'),
    mode    => '0400',
    owner   => "aem-${aem_id}",
    group   => "aem-${aem_id}",
  }
}
