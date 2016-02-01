package {'wget':
  ensure => present
} ->

exec {'download splunk':
  command => '/usr/bin/wget -O /tmp/splunk-6.3.2.rpm \'http://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=6.3.2&product=splunk&filename=splunk-6.3.2-aaff59bb082c-linux-2.6-x86_64.rpm&wget=true\'',
} ->

exec {'install splunk':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'rpm -ivh /tmp/splunk-6.3.2.rpm'
} ->
# Cleaning unused packages to decrease image size
exec {'erase splunk installer':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'rm -rf /tmp/*'
} ->
exec {'erase cache':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'rm -rf /var/cache/*'
} ->

package {'openssh': ensure => absent }
package {'openssh-clients': ensure => absent }
package {'openssh-server': ensure => absent }
package {'rhn-check': ensure => absent }
package {'rhn-client-tools': ensure => absent }
package {'rhn-setup': ensure => absent }
package {'rhnlib': ensure => absent }

package {'/usr/share/kde4':
  ensure => absent
}
