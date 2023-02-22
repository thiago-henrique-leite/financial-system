defmodule FinancialSystem.Services.AccountOperations do
  alias FinancialSystem.{Account, Currency, Transaction}

  def deposit(%Account{id: id, currency: currency}, amount) do
    {:ok, transaction} =
      Transaction.create(%{
        from_account_id: id,
        kind: "deposit",
        amount: amount,
        from_currency: currency
      })

    with true <- amount > 0,
         {:ok, %Account{balance: balance}} <- Account.update_balance(id, amount) do
      Transaction.successfully(transaction)

      {:ok, %{account_id: id, balance: balance, status: :success}}
    else
      _ ->
        Transaction.failed(transaction)

        {:error, %{account_id: id, operation: "deposit", status: :failed}}
    end
  end

  def exchange_currency(%Account{id: id} = account, to_currency, exchange_rate) do
    {:ok, transaction} =
      Transaction.create(%{
        from_account_id: id,
        kind: "exchange_currency",
        amount: account.balance,
        from_currency: account.currency,
        to_currency: to_currency
      })

    with true <- exchange_rate > 0,
         true <- Currency.valid_by_code?(to_currency),
         {:ok, %Account{balance: balance}} <-
           Account.update_currency(account, to_currency, exchange_rate) do
      Transaction.successfully(transaction)

      {:ok, %{account_id: id, balance: balance, currency: to_currency, status: :success}}
    else
      _ ->
        Transaction.failed(transaction)

        {:error, %{account_id: id, operation: "exchange_currency", status: :failed}}
    end
  end

  def transfer(%Account{} = from_account, %Account{} = to_account, amount) do
    {:ok, transaction} =
      Transaction.create(%{
        from_account_id: from_account.id,
        to_account_id: to_account.id,
        kind: "transfer",
        amount: amount,
        from_currency: from_account.currency
      })

    with true <- from_account != to_account,
         true <- from_account.currency == to_account.currency,
         true <- amount > 0,
         true <- from_account.balance >= amount,
         {:ok, %Account{balance: balance}} <- Account.update_balance(from_account.id, -amount),
         {:ok, %Account{}} <- Account.update_balance(to_account.id, amount) do
      Transaction.successfully(transaction)

      {:ok, %{account_id: from_account.id, balance: balance, status: :success}}
    else
      _ ->
        Transaction.failed(transaction)

        {:error, %{account_id: from_account.id, operation: "transfer", status: :failed}}
    end
  end

  def withdraw(%Account{id: id, currency: currency} = account, amount) do
    {:ok, transaction} =
      Transaction.create(%{
        from_account_id: id,
        kind: "withdraw",
        amount: amount,
        from_currency: currency
      })

    with true <- account.balance >= amount,
         {:ok, %Account{balance: balance}} <- Account.update_balance(id, -amount) do
      Transaction.successfully(transaction)

      {:ok, %{account_id: id, balance: balance, status: :success}}
    else
      _ ->
        Transaction.failed(transaction)

        {:error, %{account_id: id, operation: "withdraw", status: :failed}}
    end
  end
end
