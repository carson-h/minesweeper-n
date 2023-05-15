defmodule Minesweeper do
  @moduledoc """
  Testing utilities for the solver.
  """
  import MsprChal
  import MsprSolve

  @doc """
  Testing service for Minesweeper solver.

  `dim` is a tuple representing the dimensions of the boards to be tested.
  `num` is the number of mines to be placed on the board.
  `count` is the number of times to repeat this test.

  Returns a tuple of the form {wins, losses}.
  """
  def test_solve(dim, num, count, verbose) do
    pid = self() # Identify current process ID (pid)
    for _ <- 1..count, do: spawn(fn -> chal_serv(pid, dim, num, verbose) end)
    test_solve(count, {0, 0}) # Begin receiving results
  end
  defp test_solve(0, res), do: res # Return results when all are collected
  defp test_solve(count, {s, f}) do
    receive do
      :success -> test_solve(count-1, {s+1, f})
      :failure -> test_solve(count-1, {s, f+1})
    end
  end

  @doc """
  Testing server process.

  `parent` is the process ID of the parent process.
  `dim` is a tuple representing the dimensions of the boards to be tested.
  `num` is the number of mines to be placed on the board.
  `verbose` determines whether to print the results of the tests to console.

  Returns either `:success` or `:failure` depending on the results of the test.
  """
  def chal_serv(parent, dim, num, verbose) do
    {b, f} = gen_chal(dim, num) # Generate challenge board, and accompanying reference
    chal_serv(parent, b, f, num, [{:nil, {}}], verbose)  # Begin with no initial actions
  end
  defp chal_serv(parent, _, _, _, [], verbose) do # No actions take on previous step
    if verbose, do: IO.inspect("Stuck")
    send(parent, :failure) # Got stuck
  end
  defp chal_serv(parent, _, _, _, [[:error]], verbose) do # No valid action discovered
    if verbose, do: IO.inspect("Search Error")
    send(parent, :failure) # Can't find valid solution
  end
  defp chal_serv(parent, ref, field, num, acts, verbose) do
    if safe_acts?(ref, acts) do # Only proceed if no bomb has been explored
      if solved?(field, ref) do # Stop if board is solved
        if verbose, do: IO.inspect("Success")
        send(parent, :success)
      else # Unsolved, continue search
        n_acts = solve(field, num) # Find new actions
        chal_serv(parent,
                  ref,
                  field |> apply_acts(ref, n_acts), # Apply actions to field
                  num - (n_acts |> Enum.count(fn x -> elem(x, 0) == :flag end)), # Remove new mine explorations
                  n_acts,
                  verbose) 
      end
    else # Game loss on unsafe move
      if verbose, do: IO.inspect("Explored Bomb")
      send(parent, :failure)
    end
  end
end
