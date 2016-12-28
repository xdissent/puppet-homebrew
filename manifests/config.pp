# Public: Variables for working with Homebrew
#
# Examples
#
#   require homebrew::config

class homebrew::config {
  include boxen::config

  $cachedir   = "${boxen::config::cachedir}/homebrew"
  $installdir = $::homebrew_root
  $libdir     = "${installdir}/lib"
  $repodir    = "${installdir}/Homebrew"

  $cmddir     = "${repodir}/Library/Homebrew/cmd"
  $tapsdir    = "${repodir}/Library/Taps"

  $brewsdir   = "${tapsdir}/boxen/homebrew-brews"

  $min_revision = 'd5b6ecfc5078041ddf5f61b259c57f81d5c50fcc'
}
