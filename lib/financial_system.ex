defmodule FinancialSystem do
  alias FinancialSystem.{Account, Services.AccountOperations}

  def create_account(params) do
    Account.create(params)
  end

  def deposit(%Account{} = account, amount) do
    AccountOperations.deposit(account, amount)
  end

  def exchange_currency(%Account{} = account, to_currency, exchange_rate) do
    AccountOperations.exchange_currency(account, to_currency, exchange_rate)
  end

  def transfer(%Account{} = from_account, %Account{} = to_account, amount) do
    AccountOperations.transfer(from_account, to_account, amount)
  end

  def transfer(%Account{} = from_account, split_rules, amount) do
    # split_rules: [
    #   %{to_account: %Account{}, percentage: 0.2},
    #   %{to_account: %Account{}, percentage: 0.8}
    # ]

    to_accounts = Enum.map(split_rules, & &1.to_account)
    percentages = Enum.map(split_rules, & &1.percentage)

    with true <- length(to_accounts) == length(percentages),
         true <- Enum.sum(percentages) == 1,
         true <- Enum.all?(percentages, &(&1 > 0)) do
      Enum.map(split_rules, &transfer(from_account, &1.to_account, trunc(amount * &1.percentage)))
    else
      _ -> {:error, "parâmetros inválidos"}
    end
  end

  def withdraw(account, amount) do
    AccountOperations.withdraw(account, amount)
  end
end
