defmodule FinancialSystem.Transaction do
  use Ecto.Schema

  import Ecto.Changeset

  alias FinancialSystem.{Account, Currency, Repo, Transaction}

  @kinds ["deposit", "withdraw", "transfer", "exchange_currency"]
  @required_fields [:kind, :from_account_id, :to_account_id, :status, :amount, :from_currency]
  @statuses ["pending", "failed", "success"]

  schema "transactions" do
    field(:amount, :integer)
    field(:from_currency, :string)
    field(:kind, :string)
    field(:status, :string)
    field(:to_currency, :string)

    belongs_to(:from_account, Account, foreign_key: :from_account_id)
    belongs_to(:to_account, Account, foreign_key: :to_account_id)

    timestamps()
  end

  def create(%{} = params) do
    try do
      params
      |> Transaction.changeset()
      |> Repo.insert()
      |> handle_insert()
    rescue
      _ -> {:error, {:internal_server_error, "um erro inesperado aconteceu"}}
    end
  end

  def changeset(struct \\ %__MODULE__{}, %{} = params) do
    struct
    |> cast(params, @required_fields)
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:kind, @kinds)
    |> validate_inclusion(:from_currency, Currency.currencies_string())
    |> foreign_key_constraint(:from, name: :transactions_from_account_id_fkey)
  end

  def failed(%__MODULE__{} = transaction), do: update(transaction, %{status: "failed"})

  def successfully(%__MODULE__{} = transaction), do: update(transaction, %{status: "success"})

  def update(%__MODULE__{} = transaction, %{} = params) do
    transaction
    |> Transaction.changeset(params)
    |> Repo.update()
  end

  defp handle_insert({:ok, %Transaction{}} = changeset), do: changeset

  defp handle_insert({:error, changeset}) do
    {:error, %{status: :bad_request, result: changeset}}
  end
end