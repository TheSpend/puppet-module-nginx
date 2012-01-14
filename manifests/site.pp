define nginx::site($domain,
                   $root,
                   $ensure=present,
                   $owner=undef,
                   $group=undef,
                   $mediaroot="",
                   $mediaprefix="",
                   $default_vhost=false,
                   $rewrite_missing_html_extension=false,
                   $upstreams=[],
                   $auth_basic=false,
                   $auth_basic_content="",
                   $root_parent_check=true,
                   $aliases=[]) {
  $absolute_mediaroot = inline_template("<%= File.expand_path(mediaroot, root) %>")

  if $ensure == 'present' {
    # Parent directory of root directory. /var/www for /var/www/blog
    $root_parent = inline_template("<%= root.match(%r!(.+)/.+!)[1] %>")

    if $root_parent_check == true {
      if !defined(File[$root_parent]) {
        file { $root_parent:
          ensure => directory,
          owner => $owner,
          group => $group,
        }
      }
    }

    file { $root:
      ensure => directory,
      owner => $owner,
      group => $group,
      require => File[$root_parent],
    }

  } elsif $ensure == 'absent' {

    file { $root:
      ensure => $ensure,
      owner => $owner,
      group => $group,
      recurse => true,
      purge => true,
      force => true,
    }
  }

  if $auth_basic == true {
    $auth_basic_user_file = "/etc/nginx/passwords/${title}"

    file { $auth_basic_user_file:
      content => $auth_basic_content,
      ensure  => $ensure,
      owner   => $owner,
      group   => $group,
      require => File["/etc/nginx/passwords"],
    }
  }

  file {
    "/etc/nginx/sites-available/${name}.conf":
      ensure => $ensure,
      content => template("nginx/site.conf.erb"),
      require => [File[$root],
                  Package[nginx]],
      notify => Service[nginx];

    "/etc/nginx/sites-enabled/${name}.conf":
      ensure => $ensure ? {
        'present' => link,
        'absent' => $ensure,
      },
      target => $ensure ? {
        'present' => "/etc/nginx/sites-available/${name}.conf",
        'absent' => notlink,
      },
      require => File["/etc/nginx/sites-available/${name}.conf"],
      notify => Service[nginx];
  }

}
