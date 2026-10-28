# == Class: aem_curator::config_standby_status_metric
#
# Publishes AEM Author Standby's sync delay to CloudWatch without collectd.
#
# On OSes with collectd, aem_curator::config_collectd's GenericJMX plugin
# reads the SecondsSinceLastSuccess attribute of the Oak standby status MBean
# and publishes it as collectd/GenericJMX.delay.seconds_since_last_success.
# Amazon Linux 2023 AMIs have the unified CloudWatch agent instead, whose JMX
# input can't read a custom MBean. This class publishes the same metric, with
# the same namespace, name and dimensions, so alarms, dashboards and tests
# that use it keep working: a systemd timer runs a script every minute that
# reads the attribute with a single-file Java program and publishes it with
# `aws cloudwatch put-metric-data`.
#
# === Parameters
#
# [*stack_prefix*]
#   Stack prefix, used in the FixedDimension metric dimension.
#
# [*component*]
#   Component name, used in the FixedDimension metric dimension.
#
# [*ec2_id*]
#   EC2 instance ID, used as the Host metric dimension.
#
# [*aws_region*]
#   AWS region to publish the metric to.
#
# [*metrics_prefix*]
#   Value of the FixedDimension metric dimension, the same as collectd's
#   constant dimension.
#   default: "${stack_prefix}-${component}"
#
# [*jmxremote_port*]
#   Port AEM's JMX remote connector listens on.
#   default: 5982
#
# [*jmxremote_keystore_path*]
#   AEM's JMX keystore, used as the trust store when JMX uses SSL. Leave it
#   undef when JMX doesn't use SSL.
#   default: undef
#
# [*jmxremote_keystore_password*]
#   Password of the JMX keystore.
#   default: changeit
#
# [*jmx_user*]
#  JMX Username of the Monitoring user, when JMX authentication is enabled
#  default: undef
#
# [*jmx_user_password*]
#  JMX User password of the monitoring user
#  default: undef
#
# [*proxy_enabled*]
#   Whether to send the CloudWatch requests through a proxy.
#   default: false
#
# [*proxy_protocol*], [*proxy_host*], [*proxy_port*]
#   The proxy's protocol, host and port.
#
# [*proxy_noproxy*]
#   Hosts not to proxy. The EC2 instance metadata address is added if it
#   isn't there.
#   default: []
#
# [*install_dir*]
#   Directory for the Java program and the publish script.
#   default: /opt/shinesolutions/standby-status
#
# [*java_path*]
#   Java 11 or later command, which runs the Java program from its source.
#   default: java
#
# === Copyright
#
# Copyright © 2026 Shine Solutions Group, unless otherwise noted.
#
class aem_curator::config_standby_status_metric (
  $stack_prefix,
  $component,
  $ec2_id,
  $aws_region,
  $metrics_prefix              = "${stack_prefix}-${component}",
  $jmxremote_port              = '5982',
  $jmxremote_keystore_path     = undef,
  $jmxremote_keystore_password = 'changeit',
  $jmx_user                    = undef,
  $jmx_user_password           = undef,
  $proxy_enabled               = false,
  $proxy_protocol              = 'http',
  $proxy_host                  = undef,
  $proxy_port                  = undef,
  $proxy_noproxy               = [],
  $install_dir                 = '/opt/shinesolutions/standby-status',
  $java_path                   = 'java',
) {

  $program_path = "${install_dir}/StandbyStatus.java"
  $script_path = "${install_dir}/publish-standby-status-metric.sh"

  file { $install_dir:
    ensure => directory,
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
  } -> file { $program_path:
    ensure => file,
    mode   => '0600',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/aem_curator/standby-status/StandbyStatus.java',
  } -> file { $script_path:
    ensure  => file,
    # The script holds the keystore and JMX passwords
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    content => epp('aem_curator/aem-tools/publish-standby-status-metric.sh.epp', {
      'java_path'           => $java_path,
      'program_path'        => $program_path,
      'jmx_service_url'     => "service:jmx:rmi:///jndi/rmi://localhost:${jmxremote_port}/jmxrmi",
      'truststore_path'     => $jmxremote_keystore_path,
      'truststore_password' => $jmxremote_keystore_password,
      'jmx_user'            => $jmx_user,
      'jmx_user_password'   => $jmx_user_password,
      'aws_region'          => $aws_region,
      'namespace'           => 'collectd',
      'metric_name'         => 'GenericJMX.delay.seconds_since_last_success',
      'dimensions'          => "FixedDimension=${metrics_prefix},Host=${ec2_id},PluginInstance=standby-status",
      'proxy_enabled'       => $proxy_enabled,
      'proxy_url'           => "${proxy_protocol}://${proxy_host}:${proxy_port}",
      'no_proxy'            => unique($proxy_noproxy + ['169.254.169.254']).join(','),
    }),
  } -> systemd::timer { 'publish-standby-status-metric.timer':
    service_content => @("SERVICE"),
      [Unit]
      Description=Publish AEM Author Standby sync delay to CloudWatch

      [Service]
      Type=oneshot
      ExecStart=${script_path}
      | SERVICE
    timer_content   => @(TIMER),
      [Unit]
      Description=Publish AEM Author Standby sync delay to CloudWatch every minute

      [Timer]
      OnCalendar=minutely
      AccuracySec=1s

      [Install]
      WantedBy=timers.target
      | TIMER
    enable          => true,
    active          => true,
  }
}
