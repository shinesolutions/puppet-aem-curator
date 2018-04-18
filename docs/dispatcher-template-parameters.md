Dispatcher Template Parameters
------------------------------

The following parameters are available to be used from Dispatcher EPP template files.

Check out some example templates at [aem-helloworld-publish-dispatcher](https://github.com/shinesolutions/aem-helloworld-publish-dispatcher) and [aem-helloworld-author-dispatcher](https://github.com/shinesolutions/aem-helloworld-author-dispatcher).

| Name | Description | Example |
|------|-------------|---------|
| docroot_dir | Apache httpd [DocumentRoot](https://httpd.apache.org/docs/2.4/urlmapping.html#documentroot), directory where AEM cached pages and static assets will be copied to | `/var/www/html/` |
| apache_conf_dir | Directory where [Apache httpd configuration files](https://httpd.apache.org/docs/2.4/configuring.html) will be copied to | `/etc/httpd/conf/` |
| dispatcher_conf_dir | Directory where [AEM Dispatcher configuration files](https://docs.adobe.com/docs/en/dispatcher/disp-config.html) will be copied to | `/etc/httpd/conf.modules.d/` |
| log_dir | Directory where Apache httpd writes the log files | `/var/log/httpd/` |
| static_assets_dir | An alias for `docroot_dir` | `/var/www/html/` |
| virtual_hosts_dir | Directory where [Virtual Host configuration files](https://httpd.apache.org/docs/2.4/vhosts/) and [Apache RewriteMap configuration files](https://httpd.apache.org/docs/current/rewrite/rewritemap.html) will be copied to | `/etc/httpd/conf.d/` |
| ssl_cert | Location of the [Dispatcher Unified Certificate](https://helpx.adobe.com/experience-manager/dispatcher/using/dispatcher-ssl.html) | `/etc/ssl/aem.unified-dispatcher.cert` |
| author_host | AEM Author host name, only applicable in AEM Author-Dispatcher templates | `localhost`, value will differ depending on environment |
| author_port | AEM Author port number | `4502`, `5432` |
| author_secure | True if AEM Author instance is listening on https | `true`, `false` |
| publish_host | AEM Publish host name, only applicable in AEM Publish-Dispatcher template | `localhost`, value will differ depending on environment |
| publish_port | AEM Publish port number | `4503`, `5433` |
| publish_secure | True if AEM Publish instance is listening on https | `true`, `false` |

There are also a number of global facts which are supplied by the server and can be retrieved via `$facts[some-name]` parameter, e.g. `$facts[fqdn]`.

| Name | Description |
|------|-------------|
| `fqdn` | Fully qualified domain name for the instance, used as a unique instance identifier |
| `component` | AEM component name, used to identify the component type which the instance is part of. There could be multiple instances with the same component |
