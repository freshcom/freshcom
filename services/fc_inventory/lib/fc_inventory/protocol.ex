defimpl Vex.Blank, for: Decimal do
  def blank?(v) do
    Decimal.equal?(Decimal.new(0), v)
  end
end
