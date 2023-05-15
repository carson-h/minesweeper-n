defmodule MsprSolve do
  @moduledoc """
  Documentation for `MsprSolve`.

  Field represented as tuple of integers.
  -1 represents an unexplored space.
  -2 represents a flag.
  -3 represents an intended exploration.
  Other values represent the revealed number of adjacent bombs.
  eg. { {-1, -1, 1 }, {-1, -1, 1}, {-1, 2, 0} }
  """
  import MsprGen
  import Ntup
  import Statistics.Math

  @doc """
  Full search strategy. Encompasses standard searches, count searches, and exhaustive probability searches.
  """
  def solve(field, num) do
    st = stsearch_loop(field)
    if st == [] do
      co = cosearch(field, num)
      if co == [] do
        prsearch(field, num)
      else
        co
      end
    else
      st
    end
  end
  

  @doc """
  Overall count search. If no bombs remain, explore all unexplored. If only bombs remain, flag everything.
  """
  def cosearch(field, 0), do: get_all_unexplored(field) |> Enum.map(fn x -> {:explore, x} end)
  def cosearch(field, num), do: cosearch(field, num, count(field, all_perms(field)))
  defp cosearch(field, num, {_, num, _}), do: get_all_unexplored(field) |> Enum.map(fn x -> {:flag, x} end)
  defp cosearch(_, _, _), do: []

  @doc """
  Perform standard searches until no futher modifications possible.
  """
  def stsearch_loop(field), do: stsearch_loop(field, stsearch(field), [])
  defp stsearch_loop(_, [], res), do: res
  defp stsearch_loop(field, act, res) do
    new_field = write_acts(field, act)
    stsearch_loop(new_field, stsearch(new_field), (res ++ act) |> Enum.sort |> Enum.dedup)
  end

  @doc """
  Write actions to field.
  """
  def write_acts(field, []), do: field
  def write_acts(field, [{:explore, x} | tflags]), do: write_acts(ntup_put_elem(field, x, -3), tflags)
  def write_acts(field, [{:flag, x} | tflags]), do: write_acts(ntup_put_elem(field, x, -2), tflags)
  def write_acts(field, [_ | tflags]), do: write_acts(field, tflags)

  @doc """
  Standard search the field for any appropriate actions.
  """
  def stsearch(field) do
    #parent = self()
    perm_list = all_perms(field)
    perm_list |> Stream.map(fn x -> {check(field, x), x} end)
              |> Stream.flat_map(fn {mark, pos} -> mark_surr(field, pos, mark) end)
              |> Enum.sort
              |> Enum.dedup
  end
  """
  defp stsearch(_, 0, res), do: res
  defp stsearch(field, n, res) do
    receive do
      {:nil, _x} -> stsearch(field, n-1,res)
      {:explore, x} -> stsearch(field, n-1, res ++ mark_surr(field, x, :explore))
      {:flag, x} -> stsearch(field, n-1, res ++ mark_surr(field, x, :flag))
    end
  end
  """

  @doc """
  Mark surrounding positions with specified mark.
  """
  def mark_surr(_, _, :nil), do: []
  def mark_surr(field, pos, mark), do: field |> get_unexplored(pos) |> Enum.map(fn pos -> {mark, pos} end)

  @doc """
  Check for appropriate actions at a specified field location by examining adjacent positions.
  """
  def check(field, pos), do: check_res(count_around(field, pos), ntup_elem(field, pos))
  defp check_res({_,0,_}, _), do: :nil # No unexplored positions
  defp check_res(count, val) when elem(count, 0) == val, do: :explore # All bombs flagged
  defp check_res(count, val) when elem(count, 0) + elem(count, 1) == val, do: :flag # All safe explored
  defp check_res(_, _), do: :nil # No new information

  @doc """
  Probability-based search for best move.
  """
  def prsearch(field, num) do
    perim = field |> perimeter
    if perim != [] do
      pri = prob(field, num, perim)
              |> Enum.sort_by(fn x -> elem(x, 0) end)
      safe = Enum.take_while(pri, fn x -> elem(x, 0) == 0 end)
      unsafe = Enum.take_while(Enum.reverse(pri), fn x -> elem(x, 0) == 1 end)
      exp = case safe do
        [] -> [Enum.take_while(pri, fn x -> elem(x, 0) == elem(hd(pri), 0) and elem(x, 0) != 1 end) |> Enum.random |> elem(1)]
        _ -> safe |> Enum.map(fn x -> elem(x, 1) end)
      end
      Enum.map(exp, fn x -> {:explore, x} end) ++ Enum.map(unsafe, fn x -> {:flag, elem(x, 1)} end)
    else
      [{:explore, get_all_unexplored(field) |> Enum.random}]
    end
  end

  @doc """
  Calculate probability of unexplored space being a mine using current clues.
  """
  def prob(field, num, perim) do
    empty = get_all_unexplored(field) |> Enum.filter(fn x -> x not in perim end) |> length
    # Only take solutions where there aren't too many bombs, and there aren't fewer bombs remaining than empty spaces remaining
    sols = gen_sols(field, num, perim) |> Enum.filter(fn x -> length(x) <= num and num-length(x) <= empty end)
    total = Enum.reduce(sols, 0, fn x, acc -> combination(empty, num-length(x)) + acc end)
    prob(sols, empty, num, perim, [])
      |> Enum.reverse
      |> Enum.map(fn x -> x / total end)
      |> Enum.zip(perim)
  end
  defp prob(_, _, _, [], res), do: res
  defp prob(sols, empty, num, [h | tperim], res) do
    prob(sols,
         empty,
         num,
         tperim,
         [sols |> Enum.filter(fn x -> h in x end)
               |> Enum.reduce(0, fn x, acc -> combination(empty, num-length(x)) + acc end) | res])
  end

  @doc """ 
  Generate possible solutions.
  """
  def gen_sols(field, num, perim) do
    pid = self()
    spawn(fn -> gen_sols(field, num, perim, [], pid) end)
    receive do
      sols -> sols
    end
  end
  defp gen_sols(_, num, _, _, parent) when num < 0, do: send(parent, [[:error]])
  defp gen_sols(field, num, perim, acts, parent) do
    if valid_board?(field) do
      n_acts = stsearch_loop(field) ++ acts
      used_pos = Enum.map(n_acts, fn x -> elem(x, 1) end)
      n_perim = Enum.filter(perim, fn x -> x not in used_pos end)
      if n_perim == [] do  # Valid solution, return list of bomb positions
        if field |> write_acts(n_acts) |> valid_board_strict? do
          send(parent, [n_acts |> Enum.filter(fn x -> elem(x, 0) == :flag end) |> Enum.map(fn x -> elem(x, 1) end) |> Enum.sort ])
        else
          send(parent, [[:error]])
        end
      else
        pid = self()
        num_found = n_acts |> Enum.filter(fn x -> elem(x, 0) == :flag end) |> Enum.filter(fn x -> x not in acts end) |> length
        spawn(fn -> gen_sols(write_acts(field, [{:flag, hd n_perim} | n_acts]),
                            num-1-num_found,
                            tl(n_perim),
                            [{:flag, hd n_perim} | n_acts],
                            pid) end)
        gen_sols(write_acts(field, [{:explore, hd n_perim} | n_acts]),
                 num-num_found,
                 tl(n_perim),
                 [{:explore, hd n_perim} | n_acts],
                 pid)
        res = rec_sol()
        send(parent, res)
      end
    else
      send(parent, [[:error]])
    end
  end

  @doc """
  Receive solution.
  """
  defp rec_sol() do
    receive do
      [[:error]] -> rec_sol([])
      res -> rec_sol(res)
    end
  end
  defp rec_sol(res_a) do
    receive do
      [[:error]] -> res_a
      res_b -> res_a ++ res_b
    end
  end

  @doc """
  Test if the provided field is a valid state.
  """
  def valid_board?(field), do: valid_board?(field, all_perms(field), true)
  defp valid_board?(_, _, false), do: false
  defp valid_board?(_, [], _), do: true
  defp valid_board?(field, [h | t], _) do
    valid_board?(field,
                t,
                cond do
                  ntup_elem(field, h) < 0 -> true
                  true -> ntup_elem(field, h) >= (count_around(field, h) |> elem(0))
                end)
  end

  

  @doc """
  Test if the provided field is a strictly solved valid state.
  """
  def valid_board_strict?(field), do: valid_board_strict?(field, all_perms(field), true)
  defp valid_board_strict?(_, _, false), do: false
  defp valid_board_strict?(_, [], _), do: true
  defp valid_board_strict?(field, [h | t], _) do
    valid_board_strict?(field,
                       t,
                       cond do
                         ntup_elem(field, h) < 0 -> true
                         true -> ntup_elem(field, h) == (count_around(field, h) |> elem(0))
                       end)
  end
end
