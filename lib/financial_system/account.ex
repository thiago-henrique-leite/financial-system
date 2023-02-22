defmodule FinancialSystem.Account do
  use Ecto.Schema

  import Ecto.Changeset

  alias FinancialSystem.{Account, Currency, Repo}

  @required_fields [:owner, :balance, :currency]

  schema "accounts" do
    field(:balance, :integer)
    field(:currency, :string)
    field(:owner, :string)

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, %{} = params) do
    struct
    |> cast(params, @required_fields)
    |> validate_number(:balance, greater_than_or_equal_to: 0)
    |> validate_inclusion(:currency, Currency.currencies_string())
    |> unique_constraint(:owner)
  end

  def create(%{} = params) do
    try do
      params
      |> Account.changeset()
      |> Repo.insert()
      |> handle_insert()
    rescue
      _ -> {:error, {:internal_server_error, "um erro inesperado aconteceu"}}
    end
  end

  def find(account_id) do
    Repo.get!(Account, account_id)
  end

  def find_by_owner(owner) do
    Repo.get_by!(Account, owner: owner)
  end

  defp handle_insert({:ok, %Account{}} = changeset), do: changeset

  defp handle_insert({:error, changeset}) do
    {:error, %{status: :bad_request, result: changeset}}
  end

  def update(%__MODULE__{} = account, params) do
    account
    |> Account.changeset(params)
    |> Repo.update()
  end

  def update_balance(account_id, value) do
    account = find(account_id)

    update(account, %{balance: account.balance + value})
  end

  def update_currency(account_id, to_currency, exchange_rate) do
    account = find(account_id)

    update(account, %{currency: to_currency, balance: trunc(account.balance * exchange_rate)})
  end
end
