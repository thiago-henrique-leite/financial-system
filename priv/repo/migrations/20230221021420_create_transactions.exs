defmodule FinancialSystem.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :amount, :integer, null: false
      add :kind, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :from_account_id, :integer, null: false
      add :to_account_id, :integer
      add :from_currency, :string, null: false
      add :to_currency, :string

      timestamps()
    end
  end
end
