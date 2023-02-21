import Config

config :financial_system, ecto_repos: [FinancialSystem.Repo]

config :financial_system, FinancialSystem.Repo,
  database: "financial_system_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
