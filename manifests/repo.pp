# Internal: Convert homebrew snapshot into a git repo.
#
# Examples
#
#   include homebrew::repo
class homebrew::repo (
  $repodir      = $homebrew::config::repodir,
  $min_revision = $homebrew::config::min_revision,
) {
  require homebrew

  if $::osfamily == 'Darwin' {
    homebrew_repo { $repodir:
      min_revision => $min_revision,
    } -> Package <| |>
  }
}
