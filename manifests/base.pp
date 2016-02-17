package {'sudo':
  ensure => present
}

package {'wget':
  ensure => present
} ->
exec {'download splunk':
  command => "/usr/bin/wget -O /tmp/splunk.rpm 'http://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=${splunk_version}&product=splunk&filename=${splunk_filename}&wget=true'",
} ->

exec {'install splunk':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'rpm -ivh /tmp/splunk.rpm'
} ->

file {'/var/opt/splunk':
  ensure => directory,
  owner  => $splunk_user
} ->

exec {'copy etc':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => "cp -R ${splunk_home}/etc ${splunk_backup_default_etc} ; rm -fR ${splunk_home}/etc"
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
exec {'erase logs':
  path  => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'rm -rf /var/log/*'
}

if $splunk_optimistic_about_file_locking == "1" {
  exec {'Optimistic':
    path  => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => "echo OPTIMISTIC_ABOUT_FILE_LOCKING = 1 >> ${splunk_backup_default_etc}/splunk-launch.conf"
  }
}


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
