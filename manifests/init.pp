# == Class: gitweb
#
# Installs a gitolite and gitweb server that uses ssh to connect
# for read write and a website for browsing the repos
#
# === Parameters
# 
# [git_key]
#   administrators public ssh key for setting up the system
#
# [admin_user]
#   name for the above key
#
# [git_key_type]
#   The type of key for the administrator (defaults to ssh-rsa)
#
# [git_home]
#   root directory for the repository.
#     Defaults to the git users home direcotry (/home/git)
#
# [auto_tag_serial]
#   Adds an auto incrimental serial tag to each commit
#
# [repo_mask]
#   The default gitweb umask is 0077, making it unreadable to the
#   gitweb CGI script, if the apache user and the git user are in
#   different groups. If in different groups, then change the umask
#   here to 0027
#
# [cgi_bin_dir]
#   The fully qualified path to the directory that the root gitweb.cgi
#   script is installed in. You'll need to make sure apache is configured
#   to allow ExecCGI of this script.
#
# === Examples
#
#  class { gitweb:
#     git_key => 'some key val',
#  }
#
# === Authors
#
# Jason Cox <j_cox@bigpond.com>
#
# === Copyright
#
# Copyright 2014 Jason Cox, unless otherwise noted.
#
class gitweb (
  $git_key           = undef,
  $admin_user        = 'admin',
  $git_key_type      = 'ssh-rsa',
  $git_home          = '/home/git',
  $auto_tag_serial   = false,
  $cgi_bin_dir       = '/var/www/git',
  $repo_umask        = '0077',
){

  $git_root = "${git_home}/repositories"
  $hook     = "${git_home}/.gitolite/hooks/common"

  if ( $git_key == undef){
    fail('missing administrators key for gitolite')
  }
  if ( $auto_tag_serial == true ){
    @file {'hook post-receive-commitnumbers':
      name    => "${hook}/post-receive-commitnumbers",
      content => template("${module_name}/post-receive-commitnumbers.erb"),
      tag     => 'auto_tag_serial'
    }
  } else {
    @file {'remove hook post-receive-commitnumbers':
      ensure => absent,
      name   => "${hook}/post-receive-commitnumbers",
      tag    => 'auto_tag_serial'
    }
  }

  include epel

  Package{
    ensure => installed,
  }
  File{
    mode    => '0700',
    owner   => 'git',
    group   => 'git',
  }

  case $::osfamily {
    'Redhat': {
      if versioncmp("${::operatingsystemmajrelease}.0", '7.0') >= 0 {
        $install_package = 'gitolite3'
      } else {
        $install_package = 'gitolite3'
      }
    }
    default: {
      $install_package = 'gitolite'
    }
  }

  package {'gitweb': } ->
  package { $install_package : } ->
  user { 'git' :
    ensure     => present,
    comment    => 'git user',
    managehome => true,
    home       => $git_home,
  } ->
  file {"${git_home}/install.pub" :
    content => "${git_key_type} ${git_key} ${admin_user}",
    owner   => 'git',
    group   => 'git',
  } ->
  file {'gitweb config':
    name    => "$cgi_bin_dir/gitweb.cgi",
    content => template("${module_name}/gitweb.cgi.erb"),
    notify  => Service['httpd'],
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  } ->
  file {'git installer':
    name    => "${git_home}/setup.sh",
    content => template("${module_name}/setup.sh.erb"),
  } ->
  exec {'install gitolite':
    cwd     => $git_home,
    path    => '/usr/bin:/bin',
    command => "${git_home}/setup.sh",
    user    => 'git',
    creates => "${git_home}/.gitolite"
  } ->
  file { '/etc/gitweb.conf':
    ensure => present,
    content => template("${module_name}/gitweb.conf.erb"),
    notify  => Service['httpd'],  # Restart apache if it is around
  } ->
  file {'hook functions':
    name    => "${hook}/functions",
    content => template("${module_name}/functions.erb"),
  } ->
  file {'hook post-receive':
    name    => "${hook}/post-receive",
    content => template("${module_name}/post-receive.erb"),
  } ->
  file_line { 'Gitolite config':
    ensure => present,
    path   => "$git_home/.gitolite.rc",
    line   => "UMASK => $repo_umask,",
    match  => '^UMASK',
  } ->
  File <| tag == 'auto_tag_serial' |> 
 }
