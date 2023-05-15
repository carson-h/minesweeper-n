defmodule Minesweeper do
  @moduledoc """
  Documentation for `Minesweeper`.
  """
  import MsprChal
  import MsprSolve

  @doc """
  Testing service for Minesweeper solver.
  """
  def test_solve(dim, num, count, verbose) do
    pid = self() # Identify current process ID (pid)
    for _ <- 1..count, do: spawn(fn -> chal_serv(pid, dim, num, verbose) end)
    test_solve(count, {0, 0})
  end
  defp test_solve(0, res), do: res
  defp test_solve(count, {s, f}) do
    receive do
      :success -> test_solve(count-1, {s+1, f})
      :failure -> test_solve(count-1, {s, f+1})
    end
  end

  @doc """
  Testing server process.
  """
  def chal_serv(parent, dim, num, verbose) do
    {b, f} = gen_chal(dim, num) # Generate challenge board, and accompanying reference
    chal_serv(parent, b, f, num, [{:nil, {}}], verbose)  # Begin with no initial actions
  end
  defp chal_serv(parent, _, _, _, [], verbose) do # No actions take on previous step
    if verbose, do: IO.inspect("Stuck")
    send(parent, :failure) # Got stuck
  end
  defp chal_serv(parent, _, _, _, [[:error]], verbose) do # 
    if verbose, do: IO.inspect("Search Error")
    send(parent, :failure) # Can't find valid solution
  end
  defp chal_serv(parent, ref, field, num, acts, verbose) do
    if safe_acts?(ref, acts) do
      if solved?(field, ref) do
        if verbose, do: IO.inspect("Success")
        send(parent, :success)
      else # Unsolved
        n_acts = solve(field, num)
        chal_serv(parent,
                  ref,
                  field |> apply_acts(ref, n_acts),
                  num - (n_acts |> Enum.count(fn x -> elem(x, 0) == :flag end)),
                  n_acts,
                  verbose) 
      end
    else # Game loss
      if verbose, do: IO.inspect("Explored Bomb")
      send(parent, :failure)
    end
  end
end
