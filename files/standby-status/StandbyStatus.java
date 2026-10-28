// Prints the SecondsSinceLastSuccess attribute of AEM's Oak standby status
// MBean, read over JMX, the value collectd's GenericJMX plugin used to read on
// author-standby. JDK 11 and later run it straight from this source file:
//
//   java [-Djavax.net.ssl.trustStore=...] StandbyStatus.java <JMX service URL>
//
// Set JMX_USER and JMX_PASSWORD in the environment when JMX authentication is
// enabled. It exits non-zero when no standby status MBean is registered.
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import javax.management.MBeanServerConnection;
import javax.management.ObjectName;
import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXServiceURL;

public class StandbyStatus {

  static final String OBJECT_NAME = "org.apache.jackrabbit.oak:*,name=Status,type=*Standby*";
  static final String ATTRIBUTE = "SecondsSinceLastSuccess";

  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.err.println("Usage: java StandbyStatus.java <JMX service URL>");
      System.exit(2);
    }

    Map<String, Object> env = new HashMap<>();
    String user = System.getenv("JMX_USER");
    if (user != null && !user.isEmpty()) {
      env.put(JMXConnector.CREDENTIALS, new String[] {user, System.getenv("JMX_PASSWORD")});
    }

    try (JMXConnector connector = JMXConnectorFactory.connect(new JMXServiceURL(args[0]), env)) {
      MBeanServerConnection connection = connector.getMBeanServerConnection();
      Set<ObjectName> names = connection.queryNames(new ObjectName(OBJECT_NAME), null);
      if (names.isEmpty()) {
        System.err.println("No MBean matches " + OBJECT_NAME);
        System.exit(1);
      }
      System.out.println(connection.getAttribute(names.iterator().next(), ATTRIBUTE));
    }
  }
}
