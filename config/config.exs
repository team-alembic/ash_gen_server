import Config

config :ash_gen_server, runtime: config_env() != :test

config :git_ops,
  mix_project: Mix.Project.get!(),
  changelog_file: "CHANGELOG.md",
  repository_url: "https://github.com/team-alembic/ash_gen_server",
  manage_mix_version: true,
  manage_readme_version: "README.md",
  version_tag_prefix: "v"
