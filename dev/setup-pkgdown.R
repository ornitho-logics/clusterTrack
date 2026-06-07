# one-time repo setup
usethis::use_build_ignore("dev")
usethis::use_pkgdown_github_pages()


# local preview & cleanup
pkgdown::build_site(new_process = TRUE, quiet = FALSE)

pkgdown::clean_site()


# deploy
pkgdown::deploy_to_branch()

pkgdown::clean_site()
