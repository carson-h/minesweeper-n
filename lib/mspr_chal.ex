defmodule MsprChal do
  @moduledoc """
  Board generation and evaluation.
  """
  import MsprGen
  import Ntup

  @doc """
  Generate challenge board with specified dimensions and number of mines.

  `dim` is a tuple representing the dimensions of the boards to be tested.
  `num` is the number of mines to be placed on the board.

  Returns a tuple containing the n-tuple reference board and n-tuple field to be provided to the solver.
  """
  def gen_chal(dim, num), do: gen_chal(dim, num, List.to_tuple(Enum.map(Tuple.to_list(dim), fn x -> Enum.random(0..(x-1)) end)))
  def gen_chal(dim, num, start) do
    b = gen_board(dim, num, start) # Mine positions
    ref = all_perms(b) # Reference board
      |> Enum.map(fn x -> parse(b, x) end)
      |> shape_board(dim)
    f = hidden_board(dim) # Challenge board
      |> explore(ref, start)
    {ref, f}
  end

  @doc """
  Parse `true`/`false` mine locations to generate new board data.

  `b` is the n-tuple reference board.
  `pos` is the position to examine.

  Returns `-2` if a mine, or the count of bombs around `pos` otherwise.
  """
  def parse(b, pos) do
    if ntup_elem(b, pos) do # Bomb at pos
      -2
    else
      count_around(b, pos) |> elem(0)
    end
  end

  @doc """
  Generate a hidden board of specified dimensions.

  `dim` is a tuple representing the dimensions of the boards to be tested.

  Returns an n-tuple board containing all unexplored spaces.
  """
  def hidden_board(dim), do: (for _ <- 0..(Tuple.product(dim)-1), do: -1)
                              |> shape_board(dim)

  @doc """
  Explore at point, and fully expand 0 mine areas.

  `board` is the n-tuple field being examined.
  `ref` is the n-tuple reference containing all board information.
  `pos` is either a list of positions or a single position to explore about.

  Returns the updated n-tuple board.
  """
  @empty MapSet.new
  def explore(board, ref, pos) when is_list(pos), do: explore(board, ref, MapSet.new(pos), MapSet.new())
  def explore(board, ref, pos), do: explore(board, ref, MapSet.new([pos]), MapSet.new())
  defp explore(board, _, pos, _) when pos == @empty, do: board
  defp explore(board, ref, pos, explored) do
    h = Enum.take(pos, 1) |> hd
    t = MapSet.delete(pos, h)
    val = ntup_elem(ref, h)

    if val == 0 do # Explore all spaces around if the present position has zero bombs around.
      explore(ntup_put_elem(board, h, val), ref, MapSet.union(t, MapSet.difference(MapSet.new(valid_indices(board, h) |> gen_perm |> List.delete(h)), explored)), MapSet.put(explored, h))
    else
      explore(ntup_put_elem(board, h, val), ref, t, MapSet.put(explored, h))
    end
  end

  @doc """
  Generate linear list of mines according to specified length and number.

  `len` is the total length of mines available.
  `num` is the number of mines to place.

  Returns a list of `true`/`false` values indicating the presence of mines.
  """
  def gen_mines(len, num), do: gen_mines(len, num, [])
  defp gen_mines(0, _, res), do: res
  defp gen_mines(len, num, res) do
    m = :rand.uniform() <= num/len
    gen_mines(len-1, num-bool_to_int(m), [m | res])
  end

  @doc """
  Generate valid board with safe specified start position.

  `dim` is a tuple representing the dimensions of the boards to be tested.
  `num` is the number of mines to be placed on the board.
  `pos` is the starting position which must always be clear.

  Returns an ntup board of `true`/`false` values indicating the presence of mines.
  """
  def gen_board(dim, num, pos), do: gen_mines(Tuple.product(dim)-1, num)
                                     |> List.insert_at(lin_pos(dim, pos), false)
                                     |> shape_board(dim)

  @doc """
  Checks if the board has been solved.

  `field` is the n-tuple field being examined.
  `ref` is the n-tuple reference board.

  Returns a boolean indicating if all unmined locations have been explored.
  """
  def solved?(field, ref), do: all_perms(ref)
                                 |> Enum.filter(fn x -> ntup_elem(ref, x) >= 0 end)
                                 |> Enum.count(fn x -> ntup_elem(field, x) < 0 end)
                                 == 0

  @doc """
  Checks if all described actions are safe.
  Flagging is always safe. Exploring a bomb is unsafe.

  `ref` is the n-tuple reference board.
  `acts` is a list of action tuples.

  Returns a boolean indicating if all actions are safe.
  """
  def safe_acts?(ref, acts), do: acts
                                   |> Enum.filter(fn x -> elem(x, 0) == :explore end)
                                   |> Enum.map(fn x -> elem(x, 1) end)
                                   |> Enum.count(fn x -> ntup_elem(ref, x) == -2 end)
                                   == 0

  @doc """
  Applies list of actions to provided board, fully exploring as possible.
  
  `field` is the n-tuple field being examined.
  `ref` is the n-tuple reference board.
  `acts` is a list of action tuples.

  Returns an n-tuple board with all actions taken.
  """
  def apply_acts(field, ref, acts), do: field
                                          |> explore(ref, acts 
                                                            |> Enum.filter(fn x -> elem(x, 0) == :explore end)
                                                            |> Enum.map(fn x -> elem(x, 1) end))
                                          |> write_flags(acts)

  @doc """
  Applies all flags in a list of actions to provided board.
  
  `write_flags(field, acts)`

  `field` is the n-tuple field being examined.
  `acts` is a list of action tuples.

  Returns an n-tuple board with all flags added.
  """
  def write_flags(field, []), do: field
  def write_flags(field, [{:flag, x} | tflags]), do: write_flags(ntup_put_elem(field, x, -2), tflags)
  def write_flags(field, [_ | tflags]), do: write_flags(field, tflags)
                                                            
end
