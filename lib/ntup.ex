defmodule Ntup do
  @moduledoc """
  General n-dimensional tuple structures 
  """
  
  @doc """
  Access an element of an n-tuple.

  `tup` is the n-tuple to access.
  `pos` is the position to access.

  Returns the value at the specified position.
  """
  def ntup_elem(tup, {i}), do: elem(tup,i)
  def ntup_elem(tup, pos), do: ntup_elem(elem(tup,elem(pos,0)),Tuple.delete_at(pos,0))

  @doc """
  Modify an element of the n-tuple.

  `tup` is the n-tuple to modify.
  `pos` is the position to modify.
  `val` is the value to insert.

  Returns a new n-tuple with the described modification.
  """
  def ntup_put_elem(tup, {i}, val), do: put_elem(tup, i, val)
  def ntup_put_elem(tup, pos, val), do: put_elem(tup,elem(pos,0), ntup_put_elem(elem(tup,elem(pos,0)), Tuple.delete_at(pos,0), val))

  @doc """
  Determine dimensions of the n-tuple.

  `tup` is the n-tuple to measured.

  Returns a tuple with the width in each dimension.
  """
  def ntup_dim(tup), do: ntup_dim(tup,[])
  defp ntup_dim({},res), do: res ++ [0]
  defp ntup_dim(tup,res) when is_tuple(tup), do: ntup_dim(elem(tup,0), res ++ [tuple_size(tup)])
  defp ntup_dim(_,res), do: res
end
