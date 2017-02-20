# Gitweb

## Module Description

Installs both gitolite and gitweb server that uses ssh to connect for read
write and a website for browsing the repos. It assumes apache is separately
installed and a vhost setup for CGI execution.

# Setup

This class assumes that apache is separately installed, and includes its own vhost
definition, for which this class needs to be installed.

## Gitweb configuration

A simple setup needs to declare just an SSH key

``` puppet
class { 'gitweb':
  git_key => 'some key value'
}
```

This results in:
  - A gitolite respository installed in `/home/git`
  - A new user `git:git` created
  - An admin user in the gitolite repository named `install` that allows access
    through the provided SSH key
  - A umask of 0077 on the `/home/git/repositories` directory
  - A cgi script installed in `/var/wwww/git/gitweb.cgi`
  - The default `/etc/gitweb.conf` file configured to point to the gitolite repositories directory

If youre [`apache`] install is using defaults, it will have a user and group
of apache:apache or httpd:httpd, depending on distro used. You will need to
make sure that your apache user has a secondary group of git or that apache's group is set to git

 ``` puppet
 class { 'apache':
    ...

    group => 'git'
 }
 ```

in order to access the repositories directory

## Apache configuration

On the apache side, you need to point it at the installed gitweb location, and
enable the CGI handler. Various options are available, depending on whether you
are using `apache::mod::perl` or `apache::mod::fastcgi`. The following setup
illustrates basic CGI usage as a vhost

``` puppet
$git_cgi_dir = '/var/www/git'

include apache::mod::cgi

apache::vhost { "git":
  docroot => '/var/www/git/static',
  options => [ 'Indexes', 'FollowSymlinks', 'ExecCGI' ],
  custom_fragment =>  'AddHandler cgi-script .cgi',
  rewrite_rule => "^/$ $git_cgi_dir/gitweb.cgi",

  directories => [
    {
      'path' => '/var/www/git',
      'options' => 'ExecCGI',
      'allow' => 'from all',
    }
  ]
}

class { 'gitweb':
    git_key => hiera('git.admin.key'),
    admin_user => hiera('git.admin.name'),
    repo_umask => '0027',
    cgi_bin_dir => $git_cgi_dir,
  }
```

# Classes

## gitweb

### Parameters

#### git_key
   administrators public ssh key for setting up the system.

#### admin_user
   Gitolite internal user name for the administrator key.

#### git_key_type
   The type of key for the administrator (defaults to ssh-rsa)

#### git_home
   root directory for the repository.
     Defaults to the git users home direcotry (/home/git)

#### auto_tag_serial
   Adds an auto incrimental serial tag to each commit


# Authors

Jason Cox <j_cox@bigpond.com>

# Copyright

Copyright 2014-2017 Jason Cox, unless otherwise noted.

