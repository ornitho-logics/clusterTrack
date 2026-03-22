#region: one-time repo setup
usethis::use_build_ignore("dev")
usethis::use_pkgdown_github_pages()
usethis::use_article("pesa.qmd")

#endregion

#region: local preview & cleanup
pkgdown::build_site(new_process = TRUE, quiet = FALSE)

pkgdown::clean_site()

unlink(
  list.files("vignettes/articles", pattern = "_files$", full.names = TRUE),
  recursive = TRUE,
  force = TRUE
)

#endregion

#region: deploy
pkgdown::deploy_to_branch()

#endregion
