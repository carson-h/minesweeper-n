defmodule MsprGen do
  @moduledoc """
  General functions.
  """
  import Ntup

  @doc """
  Generate all permutations of field positions.

  `field` is the n-tuple field being examined.

  Returns a list of position tuples to access all positions.
  """
  def all_perms(field), do: gen_perm(List.to_tuple(for n <- ntup_dim(field), do: List.to_tuple(Enum.to_list(0..(n-1)))))

  @doc """
  Count elements of each type around specified field location.

  `field` is the n-tuple field being examined.
  `pos` is the position to be examined around.

  Returns a tuple formatted as the numbers of {flags, unexplored, empty}.
  """
  def count_around(field, pos), do: count(field, valid_indices(field, pos) |> gen_perm |> List.delete(pos))

  @doc """
  Count values at set of indices.

  `field` is the n-tuple field being examined.
  `indices` is a list of positions at which counts should be tallied

  Returns a tuple formatted as the numbers of {flags, unexplored, empty}.
  """
  def count(field, indices), do: count(field, indices, {0, 0, 0})
  defp count(_, [], res), do: res
  defp count(field, [h | t], res), do: count(field, t, ntup_elem(field, h) |> update_count(res))

  @doc """
  Update count of area according to discovered element.

  `update_count(val, count)`

  `val` is the element under examination.
  `count` is the current count similar elements.

  Returns a tuple formatted as the numbers of {flags, unexplored, empty}.
  """
  def update_count(-2, {flags, unexplored, empty}), do: {flags+1, unexplored, empty}
  def update_count(-1, {flags, unexplored, empty}), do: {flags, unexplored+1, empty}
  def update_count(true, {flags, unexplored, empty}), do: {flags+1, unexplored, empty}
  def update_count(_val, {flags, unexplored, empty}), do: {flags, unexplored, empty+1}
  
  @doc """
  Generates permutations of valid field indices.

  `indices` is a tuple containing tuples of positions to generate permutations from.

  Returns a list of all permutations of `indices`
  """
  def gen_perm(indices), do: gen_perm(Tuple.delete_at(indices,0), (for n <- Tuple.to_list(elem(indices,0)), do: {n} ))
  defp gen_perm({}, res), do: res
  defp gen_perm(indices, res), do: gen_perm(Tuple.delete_at(indices,0), list_map(elem(indices,0),res))

  @doc """
  Generate permutations examining single pair of results and new coordinates.

  `a` is the tuple of valid indices.
  `b` is a list all existing permutations.

  Returns a list of all permutations of `a` with `b`.
  """
  def list_map(a, b), do: Enum.flat_map(b, fn x -> for n <- Tuple.to_list(a), do: Tuple.append(x,n) end)

  @doc """
  Determine valid indices for neighbours of position in a field.

  `field` is the n-tuple field being examined.
  `pos` is the position to be examined around.

  Returns a tuple of tuples containing all valid indices in neighbourhood of `pos` in each dimension.
  """
  def valid_indices(field, pos), do: valid_indices(field, pos, {})
  defp valid_indices(_, {}, res), do: res
  defp valid_indices(field, pos, res) do
    valid_indices(elem(field,0),
                  Tuple.delete_at(pos,0),
                  Tuple.append(res, (for n <- neighbours(elem(pos,0)), (n >= 0 and n < tuple_size(field)), do: n ) |> List.to_tuple))
  end

  def neighbours(n), do: [n-1, n, n+1]

  @doc """
  Converts boolean to map integer.
  """
  def bool_to_int(true), do: 1
  def bool_to_int(_), do: 0

  @doc """
  Determines linear position equivalent of n-tuple field.

  `dim` is a tuple representing the dimensions of the boards to be tested.
  `pos` is the position to be found.

  Returns an integer for the linear position.
  """
  def lin_pos(dim, pos), do: lin_pos(dim, pos, 0)
  defp lin_pos({}, _, res), do: res
  defp lin_pos(dim, pos, res) do
    new_dim = Tuple.delete_at(dim, 0)
    lin_pos(new_dim, Tuple.delete_at(pos, 0), res+Tuple.product(new_dim)*elem(pos, 0))
  end

  @doc """
  Shape a linear board to specified dimensions.

  `lin` is a linear tuple board.
  `dim` is the desired dimensions of the n-tuple board.

  Returns an n-tuple board shaped in the specified dimensions.
  """
  def shape_board(lin, dim), do: shape_board(rev_tup(dim), lin, [])
  defp shape_board({}, pile, _), do: hd pile
  defp shape_board(dim, [], res), do: shape_board(Tuple.delete_at(dim, 0), Enum.reverse(res), [])
  defp shape_board(dim, pile, res), do: shape_board(dim, Enum.drop(pile, elem(dim, 0)), [List.to_tuple(Enum.take(pile, elem(dim, 0))) | res])

  @doc """
  Reverse order of tuple.

  `tup` is the tuple to be reversed.

  Returns `tup` reversed.
  """
  def rev_tup({}), do: {}
  def rev_tup(tup), do: rev_tup(Tuple.delete_at(tup, 0), {elem(tup, 0)})
  defp rev_tup({}, res), do: res
  defp rev_tup(tup, res), do: rev_tup(Tuple.delete_at(tup, 0), Tuple.insert_at(res, 0, elem(tup, 0)))

  @doc """
  List unexplored tiles around position.

  `field` is the n-tuple field being examined.
  `pos` is the position to be examined around.

  Returns a list of tuples representing all unexplored positions around `pos`.
  """
  def get_unexplored(field, pos), do: valid_indices(field, pos)
                                        |> gen_perm
                                        |> List.delete(pos)
                                        |> Enum.map(fn x -> 
                                                      case ntup_elem(field, x) do
                                                        -1 -> x
                                                        _  -> :nil
                                                      end
                                                    end)
                                        |> Enum.reduce([], fn
                                                             :nil, acc -> acc
                                                             x, acc    -> [x | acc]
                                                           end)

  @doc """
  List all unexplored tiles.
  
  `field` is the n-tuple field being examined.

  Returns a list of tuples representing all unexplored positions.
  """
  def get_all_unexplored(field), do: all_perms(field)
                                       |> Enum.map(fn x -> 
                                                     case ntup_elem(field, x) do
                                                       -1 -> x
                                                       _  -> :nil
                                                     end
                                                   end)
                                       |> Enum.reduce([], fn
                                                            :nil, acc -> acc
                                                            x, acc    -> [x | acc]
                                                          end)

  @doc """
  Finds the unexplored perimeter of all explored areas of a field.

  `field` is the n-tuple field being examined.

  Returns a list of tuples representing all perimeter positions.
  """
  def perimeter(field), do: all_perms(field)
                              |> Enum.filter(fn x -> ntup_elem(field, x) >= 0 end) # Not unexplored or flagged
                              |> Enum.flat_map(fn x -> get_unexplored(field, x) end) # Unexplored around position
                              |> Enum.sort
                              |> Enum.dedup
end
