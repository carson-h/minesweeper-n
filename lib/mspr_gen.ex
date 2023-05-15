defmodule MsprGen do
  @moduledoc """
  Documentation for `MsprGen`.
  """
  import Ntup

  @doc """
  Generate all permutations of field positions
  """
  def all_perms(field), do: gen_perm(List.to_tuple(for n <- ntup_dim(field), do: List.to_tuple(Enum.to_list(0..(n-1)))))

  @doc """
  Count elements of each type around specified field location.
  Formatted as numbers of {flags, unexplored, empty}.
  """
  def count_around(field, pos), do: count(field, valid_indices(field, pos) |> gen_perm |> List.delete(pos))

  @doc """
  Count values at set of indices.
  """
  def count(field, indices), do: count(field, indices, {0, 0, 0})
  defp count(_, [], res), do: res
  defp count(field, [h | t], res), do: count(field, t, ntup_elem(field, h) |> update_count(res))

  @doc """
  Update count of area according to discovered element.
  Formatted as numbers of {flags, unexplored, empty}.
  """
  def update_count(-2, count), do: put_elem(count, 0, elem(count,0)+1)
  def update_count(-1, count), do: put_elem(count, 1, elem(count,1)+1)
  def update_count(true, count), do: put_elem(count, 0, elem(count,0)+1)
  def update_count( _, count), do: put_elem(count, 2, elem(count,2)+1)
  
  @doc """
  Generates permutations of valid field indices.
  """
  def gen_perm(indices), do: gen_perm(Tuple.delete_at(indices,0), (for n <- Tuple.to_list(elem(indices,0)), do: {n} ))
  defp gen_perm({}, res), do: res
  defp gen_perm(indices, res), do: gen_perm(Tuple.delete_at(indices,0), list_map(elem(indices,0),res))

  @doc """
  Generate permutations examining single pair of results and new coordinates.
  """
  def list_map(a, b), do: Enum.flat_map(b, fn x -> for n <- Tuple.to_list(a), do: Tuple.append(x,n) end)

  @doc """
  Determine valid indices for position in a field.
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
  """
  def lin_pos(dim, pos), do: lin_pos(dim, pos, 0)
  defp lin_pos({}, _, res), do: res
  defp lin_pos(dim, pos, res) do
    new_dim = Tuple.delete_at(dim, 0)
    lin_pos(new_dim, Tuple.delete_at(pos, 0), res+Tuple.product(new_dim)*elem(pos, 0))
  end

  @doc """
  Shape a linear board to specified dimensions.
  """
  def shape_board(lin, dim), do: shape_board(rev_tup(dim), lin, [])
  defp shape_board({}, pile, _), do: hd pile
  defp shape_board(dim, [], res), do: shape_board(Tuple.delete_at(dim, 0), Enum.reverse(res), [])
  defp shape_board(dim, pile, res), do: shape_board(dim, Enum.drop(pile, elem(dim, 0)), [List.to_tuple(Enum.take(pile, elem(dim, 0))) | res])

  @doc """
  Reverse order of tuple.
  """
  def rev_tup({}), do: {}
  def rev_tup(tup), do: rev_tup(Tuple.delete_at(tup, 0), {elem(tup, 0)})
  defp rev_tup({}, res), do: res
  defp rev_tup(tup, res), do: rev_tup(Tuple.delete_at(tup, 0), Tuple.insert_at(res, 0, elem(tup, 0)))

  @doc """
  List unexplored tiles around position
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
                                        |> Enum.reverse()

  @doc """
  List all unexplored tiles.
  """
  def get_all_unexplored(field) do
    all_perms(field)
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
  end   

  def perimeter(field) do
    all_perms(field)
      |> Enum.filter(fn x -> ntup_elem(field, x) >= 0 end) # Not unexplored or flagged
      |> Enum.flat_map(fn x -> get_unexplored(field, x) end) # Unexplored around position
      |> MapSet.new # Reduce to set
      |> MapSet.to_list
  end
end
