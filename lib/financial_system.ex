defmodule FinancialSystem do
  alias FinancialSystem.{Account, Currency, Transaction}

  # public methods
  def create_account(params) do
    Account.create(params)
  end

  def deposit(account, amount) do
    execute_deposit(account, amount)
  end

  def exchange_currency(account, to_currency, exchange_rate) do
    execute_exchange_currency(account, to_currency, exchange_rate)
  end

  def transfer(%Account{} = from_account, %Account{} = to_account, amount) do
    execute_transfer(from_account, to_account, amount)
  end

  def transfer(%Account{} = from_account, split_rules, amount) do
    split_rules = Enum.map(split_rules, &Map.put(&1, :account, Account.find(&1.account_id)))

    accounts = Enum.map(split_rules, & &1.account)
    percentages = Enum.map(split_rules, & &1.percentage)

    with true <- length(accounts) == length(percentages),
         true <- Enum.sum(percentages) == 1,
         true <- Enum.all?(percentages, &greather_than_zero?(&1)) do
      Enum.map(split_rules, &transfer(from_account, &1.account, trunc(&1.percentage * amount)))
    else
      _ -> {:error, "parâmetros inválidos"}
    end
  end

  def withdraw(account, amount) do
    execute_withdraw(account, amount)
  end

  # private methods
  defp execute_deposit(%Account{id: id, currency: currency}, amount) do
    {:ok, transaction} =
      Transaction.create(%{
        from_account_id: id,
        kind: "deposit",
        amount: amount,
        from_currency: currency
      })

    with true <- greather_than_zero?(amount),
         {:ok, %Account{balance: balance}} <- Account.update_balance(id, amount),
         {:ok, %Transaction{}} <- Transaction.successfully(transaction) do
      {:ok, %{account_id: id, balance: balance, operation: "deposit", status: :success}}
    else
      _ ->
        Transaction.failed(transaction)

        {:error, %{account_id: id, operation: "deposit", status: :failed}}
    end
  end

  defp execute_exchange_currency(%Account{id: id} = account, to_currency, exchange_rate) do
    {:ok, transaction} =
      Transaction.create(%{
        from_account_id: id,
        kind: "exchange_currency",
        amount: account.balance,
        from_currency: account.currency,
        to_currency: to_currency
      })

    with true <- greather_than_zero?(exchange_rate),
         true <- Currency.valid_by_code?(to_currency),
         {:ok, %Account{balance: balance, currency: currency}} <-
           Account.update_currency(account, to_currency, exchange_rate),
         {:ok, %Transaction{}} <- Transaction.successfully(transaction) do
      {:ok,
       %{
         account_id: id,
         balance: balance,
         currency: currency,
         operation: "exchange_currency",
         status: :success
       }}
    else
      _ ->
        Transaction.failed(transaction)

        {:error, %{account_id: id, operation: "exchange_currency", status: :failed}}
    end
  end

  defp execute_transfer(%Account{} = from_account, %Account{} = to_account, amount) do
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
         true <- greather_than_zero?(amount),
         true <- from_account.balance >= amount,
         {:ok, %Account{balance: balance}} <- Account.update_balance(from_account.id, -amount),
         {:ok, %Account{}} <- Account.update_balance(to_account.id, amount),
         {:ok, %Transaction{}} <- Transaction.successfully(transaction) do
      {:ok,
       %{account_id: from_account.id, balance: balance, operation: "transfer", status: :success}}
    else
      _ ->
        Transaction.failed(transaction)

        {:error, %{account_id: from_account.id, operation: "transfer", status: :failed}}
    end
  end

  defp execute_withdraw(%Account{id: id, currency: currency} = account, amount) do
    {:ok, transaction} =
      Transaction.create(%{
        from_account_id: id,
        kind: "withdraw",
        amount: amount,
        from_currency: currency
      })

    with true <- account.balance >= amount,
         {:ok, %Account{balance: balance}} <- Account.update_balance(id, -amount),
         {:ok, %Transaction{}} <- Transaction.successfully(transaction) do
      {:ok, %{account_id: id, operation: "withdraw", balance: balance, status: :success}}
    else
      _ ->
        Transaction.failed(transaction)

        {:error, %{account_id: id, operation: "withdraw", status: :failed}}
    end
  end

  defp greather_than_zero?(amount) do
    amount > 0
  end
end
