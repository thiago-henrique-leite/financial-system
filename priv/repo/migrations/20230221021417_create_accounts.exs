defmodule FinancialSystem.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :owner, :string, null: false
      add :balance, :integer, null: false
      add :currency, :string, null: false

      timestamps()
    end

    create unique_index(:accounts, [:owner])
  end
end
