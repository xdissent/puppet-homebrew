# Public: Install and configure homebrew for use with Boxen.
#
# Examples
#
#   include homebrew

class homebrew(
  $cachedir     = $homebrew::config::cachedir,
  $installdir   = $homebrew::config::installdir,
  $libdir       = $homebrew::config::libdir,
  $repodir      = $homebrew::config::repodir,
  $cmddir       = $homebrew::config::cmddir,
  $tapsdir      = $homebrew::config::tapsdir,
  $brewsdir     = $homebrew::config::brewsdir,
  $min_revision = $homebrew::config::min_revision,
  $repo         = 'Homebrew/brew',
  $set_cflags   = undef,
  $set_ldflags  = undef,
  $add_man_path = undef,
  $add_bin_path = undef,
) inherits homebrew::config {
  include boxen::config
  include homebrew::repo

  $non_default = $installdir ? {
    /^\/usr\/local\/?$/ => false,
    default => true
  }

  $set_cflags_ = $set_cflags ? {
    undef => $non_default,
    default => true
  }

  $set_ldflags_ = $set_ldflags ? {
    undef => $non_default,
    default => true
  }

  $add_man_path_ = $add_man_path ? {
    undef => $non_default,
    default => true
  }

  $add_bin_path_ = $add_bin_path ? {
    undef => $non_default,
    default => true
  }

  if $non_default {
    file { $installdir:
      ensure  => 'directory',
      owner   => $::boxen_user,
      group   => 'staff',
      mode    => '0755',
      require => undef,
      before  => Exec["install homebrew to ${installdir}"],
    }
  }

  file { [$repodir,
          "${installdir}/bin",
          "${installdir}/etc",
          "${installdir}/etc/bash_completion.d",
          "${installdir}/include",
          "${installdir}/lib",
          "${installdir}/lib/pkgconfig",
          "${installdir}/Cellar",
          "${installdir}/Frameworks",
          "${installdir}/sbin",
          "${installdir}/share",
          "${installdir}/share/locale",
          "${installdir}/share/man",
          "${installdir}/share/man/man1",
          "${installdir}/share/man/man2",
          "${installdir}/share/man/man3",
          "${installdir}/share/man/man4",
          "${installdir}/share/man/man5",
          "${installdir}/share/man/man6",
          "${installdir}/share/man/man7",
          "${installdir}/share/man/man8",
          "${installdir}/share/info",
          "${installdir}/share/doc",
          "${installdir}/share/aclocal",
          "${installdir}/share/zsh",
          "${installdir}/share/zsh/site-functions",
          "${installdir}/var",
          "${installdir}/var/log",
          "${installdir}/opt",
          ]:
    ensure  => 'directory',
    owner   => $::boxen_user,
    group   => 'staff',
    mode    => '0755',
    require => undef,
    before  => Exec["install homebrew to ${installdir}"],
  }

  exec { "install homebrew to ${installdir}":
    command => "git init -q &&
                git config remote.origin.url https://github.com/${repo} &&
                git config remote.origin.fetch master:refs/remotes/origin/master &&
                git fetch origin master:refs/remotes/origin/master -n &&
                git reset --hard origin/master",
    cwd     => $repodir,
    user    => $::boxen_user,
    creates => "${repodir}/.git",
    require => File[$repodir],
  } ~>
  exec { 'post-install force brew update':
    refreshonly => true,
    command => 'brew update --force',
    cwd => $repodir,
    user => $::boxen_user,
    environment => [
      "USER=$::boxen_user",
      "HOME=/Users/${::boxen_user}",
    ],
    path => [
      "${repodir}/bin",
      '/usr/bin',
      '/usr/sbin',
      '/bin',
      '/sbin',
    ],
  }

  File {
    require => Exec["install homebrew to ${installdir}"],
  }

  file { "${installdir}/bin/brew":
    ensure => link,
    target => "${repodir}/bin/brew",
    owner   => $::boxen_user,
    group   => 'staff',
  }

  # Remove the old monkey patches, from pre #39
  file {
    "${installdir}/Library/Homebrew/boxen-monkeypatches.rb":
      ensure => 'absent',
  }

  # Remove the old shim for bottle hooks, from pre #75
  file {
    [
      "${installdir}/Library/Homebrew/boxen-bottle-hooks.rb",
      "${cmddir}/boxen-latest.rb",
      "${cmddir}/boxen-install.rb",
      "${cmddir}/boxen-upgrade.rb",
    ]:
      ensure => 'absent',
  }

  file {
    [
      $cachedir,
      $tapsdir,
      $cmddir,
      "${tapsdir}/boxen",
      $brewsdir,
      "${brewsdir}/cmd"
    ]:
      ensure => 'directory' ;

    # shim for bottle hooks
    "${brewsdir}/cmd/boxen-bottle-hooks.rb":
      source  => 'puppet:///modules/homebrew/boxen-bottle-hooks.rb' ;
    "${brewsdir}/cmd/brew-boxen-latest.rb":
      source  => 'puppet:///modules/homebrew/brew-boxen-latest.rb' ;
    "${brewsdir}/cmd/brew-boxen-install.rb":
      source  => 'puppet:///modules/homebrew/brew-boxen-install.rb' ;
  }

  ->
  file {
    [
      "${boxen::config::envdir}/homebrew.sh",
      "${boxen::config::envdir}/30_homebrew.sh",
      "${boxen::config::envdir}/cflags.sh",
      "${boxen::config::envdir}/ldflags.sh",
      "${brewsdir}/cmd/brew-boxen-upgrade.rb",
    ]:
      ensure => absent,
  }

  ->
  boxen::env_script { 'homebrew':
    content  => template('homebrew/env.sh.erb'),
    priority => highest,
  }
}
