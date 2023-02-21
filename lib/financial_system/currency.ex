defmodule FinancialSystem.Currency do
  alias Money.Currency

  def currencies, do: Map.keys(Currency.all())
  def currencies_string, do: Enum.map(currencies(), &to_string(&1))
  def valid_by_code?(code), do: Enum.member?(currencies(), String.to_atom(code))
end
