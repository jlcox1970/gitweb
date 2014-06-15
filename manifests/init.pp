# == Class: gitweb
#
# Full description of class gitweb here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { gitweb:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class gitweb (
  $git_home = '/home/git',
  $git_key  = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwh7mlPNf1YTGMyLDL17ZGHbpnW5NMNUSNT8rDYWsLjPd53AAEcFYWkHf8fTSWHL7nABgusZ0CU/EXCeqEV4Je+xT0U8WDOKz3BoTLPwT0uF8eDvvnpUg0WEpnMFyAAfXT2QoEMPO8YTqrYqGNxZTfl9bclcFu+3pK9mxTx1Fg7QMl9qRkAQjDRy17yB0eN7CV//waOaezDUT18heyW9C6ZLxTO4XHQ+ditIjozuRYsnX3LARBIhI1PUF9ap4g3u44bftspWA01CrFQgIis+e/t7vKyR72P3RzG5HgYBPiSDbixSKosjBCERx5/XHxxa0/4R4xsRZF099z2dECinpEw== root@pmslap71-linux',

){
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
