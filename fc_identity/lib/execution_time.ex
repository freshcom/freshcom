defmodule ExecutionTime do
  def time_of(function, args \\ []) do
    {time, _} = :timer.tc(function, args)
    IO.puts "Time: #{time}ms"
  end
end