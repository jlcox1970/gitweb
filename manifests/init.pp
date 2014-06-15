# == Class: gitweb
#
# Installs a gitolite and gitweb server that uses ssh to connect for read write and a website for browsing the repos
#
# === Parameters
# 
# [git_root]
#   root directory for the repository.
#     Defaults to the git users home direcotry (/home/git)
#
# [git_key]
#   administrators public ssh key for setting up the system
#
# === Examples
#
#  class { gitweb:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
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
  $git_home = '/home/git',
  $git_key  = undef,

){
  if ( $git_key == undef){
    fail("missing administrators key for gitolite")
  }
  $git_root = "${git_home}/repositories"
  $hook     = "${git_home}/.gitolite/hooks/common"

  include epel

  Package{
    ensure => installed,
  }
  File{
    mode    => '0700',
    owner   => 'git',
    group   => 'git',
  } 
  package {'gitweb': } ->
  package {'httpd': } ->
  package {'gitolite' : } ->
  package {'gitolite3' : } ->
  account { 'git' :
    comment  => 'git user',
    home_dir => $git_home,
  } ->
  file {"${git_home}/install.pub" :
    content => $git_key,
    owner   => 'git',
    group   => 'git',
  } ->
  file {'gitweb config':
    name    => '/var/www/git/gitweb.cgi',
    content => template("${module_name}/gitweb.cgi.erb"),
    notify  => Service['httpd'],
    owner   => 'root',
    group   => 'root',
    mode    => '755',
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
  } -> 
  file {'hook functions':
    name    => "${hook}/functions",
    content => template("${module_name}/functions.erb"),
  } ->
  file {'hook post-receive':
    name    => "${hook}/post-receive",
    content => template("${module_name}/post-receive.erb"),
  } ->
  file {'hook post-receive-commitnumbers':
    name    => "${hook}/post-receive-commitnumbers",
    content => template("${module_name}/post-receive-commitnumbers.erb"),
  } ->
  service {'httpd':
    ensure => true,
    enable => true,
  }
}
