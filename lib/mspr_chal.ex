defmodule MsprChal do
  @moduledoc """
  Documentation for `MsprChal`.
  """
  import MsprGen
  import Ntup

  @doc """
  Generate challenge board with specified dimensions and number of mines.
  """
  def gen_chal(dim, num), do: gen_chal(dim, num, List.to_tuple(Enum.map(Tuple.to_list(dim), fn x -> Enum.random(0..(x-1)) end)))
  def gen_chal(dim, num, start) do
    b = gen_board(dim, num, start)
    field = all_perms(b)
      |> Enum.map(fn x -> parse(b, x) end)
      |> shape_board(dim)
    f = hidden_board(dim)
      |> explore(field, start)
    {field, f}
  end

  @doc """
  Parse mine locations to generate new board data.
  """
  def parse(b, pos) do
    if ntup_elem(b, pos) == true do
      -2
    else
      bcount_around(b, pos)
    end
  end

  @doc """
  Count elements of each type around specified field location.
  Formatted as numbers of {flags, unexplored, empty}.
  """
  def bcount_around(field, pos), do: elem(count_around(field, pos), 0)

  @doc """
  Generate a hidden board of specified dimensions.
  """
  def hidden_board(dim), do: (for _ <- 0..(Tuple.product(dim)-1), do: -1)
                              |> shape_board(dim)

  @doc """
  Explore at point, and fully expand 0 mine areas.
  """
  @empty MapSet.new
  def explore(board, ref, pos) when is_list(pos), do: explore(board, ref, MapSet.new(pos), MapSet.new())
  def explore(board, ref, pos), do: explore(board, ref, MapSet.new([pos]), MapSet.new())
  defp explore(board, _, pos, _) when pos == @empty, do: board
  defp explore(board, ref, pos, explored) do
    h = Enum.take(pos, 1) |> hd
    t = MapSet.delete(pos, h)
    val = ntup_elem(ref, h)

    if val == 0 do
      explore(ntup_put_elem(board, h, val), ref, MapSet.union(t, MapSet.difference(MapSet.new(valid_indices(board, h) |> gen_perm |> List.delete(h)), explored)), MapSet.put(explored, h))
    else
      explore(ntup_put_elem(board, h, val), ref, t, MapSet.put(explored, h))
    end
  end

  @doc """
  Generate linear list of mines according to specified length and number.
  """
  def gen_mines(len, num), do: gen_mines(len, num, [])
  defp gen_mines(0, _, res), do: res
  defp gen_mines(len, num, res) do
    m = :rand.uniform() <= num/len
    gen_mines(len-1, num-bool_to_int(m), [m | res])
  end

  @doc """
  Generate valid board with safe specified start position.
  """
  def gen_board(dim, num, pos), do: gen_mines(Tuple.product(dim)-1, num)
                                     |> List.insert_at(lin_pos(dim, pos), false)
                                     |> shape_board(dim)

  @doc """
  Checks if the board has been solved.
  """
  def solved?(field, ref), do: all_perms(ref)
                                 |> Enum.filter(fn x -> ntup_elem(ref, x) >= 0 end)
                                 |> Enum.count(fn x -> ntup_elem(field, x) < 0 end)
                                 == 0

  def safe_acts?(ref, acts), do: acts
                                   |> Enum.filter(fn x -> elem(x, 0) == :explore end)
                                   |> Enum.map(fn x -> elem(x, 1) end)
                                   |> Enum.count(fn x -> ntup_elem(ref, x) == -2 end)
                                   == 0

  def apply_acts(field, ref, acts), do: field
                                          |> explore(ref, acts 
                                                            |> Enum.filter(fn x -> elem(x, 0) == :explore end)
                                                            |> Enum.map(fn x -> elem(x, 1) end))
                                          |> write_flags(acts)

  def write_flags(field, []), do: field
  def write_flags(field, [{:flag, x} | tflags]), do: write_flags(ntup_put_elem(field, x, -2), tflags)
  def write_flags(field, [_ | tflags]), do: write_flags(field, tflags)
                                                            
end
