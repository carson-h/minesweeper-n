defmodule Minesweeper do
  @moduledoc """
  Testing utilities for the solver.
  """
  import MsprChal
  import MsprSolve

  @doc """
  Testing service for Minesweeper solver [concurrent testing].

  `dim` is a tuple representing the dimensions of the boards to be tested.
  `num` is the number of mines to be placed on the board.
  `count` is the number of times to repeat this test.
  `verbose` determines whether to print the results of the tests to console.

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

  @doc """
  Testing service for Minesweeper solver [sequential testing].

  `dim` is a tuple representing the dimensions of the boards to be tested.
  `num` is the number of mines to be placed on the board.
  `count` is the number of times to repeat this test.
  `verbose` determines whether to print the results of the tests to console.

  Returns a tuple of the form {wins, losses}.
  """
  def test_solve_seq(dim, num, count, proc_limit \\ -1, verbose \\ false), do: test_solve_seq(dim, num, count, {0, 0}, proc_limit, verbose)
  defp test_solve_seq(_, _, 0, res, _, _), do: res # Return result when all tests completed.
  defp test_solve_seq(dim, num, count, {win, loss}, proc_limit, verbose) do
    chal_serv_nomod(self(), dim, num, proc_limit, verbose) # Run challenge
    receive do # Update results, and proceed with testing
      :success -> test_solve_seq(dim, num, count-1, {win+1, loss}, proc_limit, verbose)
      :failure -> test_solve_seq(dim, num, count-1, {win, loss+1}, proc_limit, verbose)
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
  def chal_serv_nomod(parent, dim, num, proc_limit \\ -1, verbose) do
    {b, f} = gen_chal(dim, num) # Generate challenge board, and accompanying reference
    chal_serv_nomod(parent, b, f, num, [{:nil, {}}], proc_limit, verbose)  # Begin with no initial actions
  end
  defp chal_serv_nomod(parent, _, _, _, [], _, verbose) do # No actions take on previous step
    if verbose, do: IO.inspect("Stuck")
    send(parent, :failure) # Got stuck
  end
  defp chal_serv_nomod(parent, _, _, _, [[:error]], _, verbose) do # No valid action discovered
    if verbose, do: IO.inspect("Search Error")
    send(parent, :failure) # Can't find valid solution
  end
  defp chal_serv_nomod(parent, ref, field, num, acts, proc_limit, verbose) do
    if safe_acts?(ref, acts) do # Only proceed if no bomb has been explored
      if solved?(field |> apply_acts(ref, acts), ref) do # Stop if board is solved
        if verbose, do: IO.inspect("Success")
        send(parent, :success)
      else # Unsolved, continue search
        n_acts = solve(field |> apply_acts(ref, acts), num, proc_limit) # Find new actions
        chal_serv_nomod(parent,
                        ref,
                        field, # Apply actions to field
                        num - (n_acts |> Enum.count(fn x -> elem(x, 0) == :flag end)), # Remove new mine explorations
                        n_acts ++ acts,
                        proc_limit,
                        verbose) 
      end
    else # Game loss on unsafe move
      if verbose, do: IO.inspect("Explored Bomb")
      send(parent, :failure)
    end
  end
end
