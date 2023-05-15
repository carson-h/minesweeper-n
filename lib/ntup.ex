defmodule Ntup do
  @moduledoc """
  Documentation for `Ntup`.
  """
  
  @doc """
  Access an element of the n-dimensional tuple structure used to encode fields.
  """
  def ntup_elem(tup, {i}), do: elem(tup,i)
  def ntup_elem(tup, pos), do: ntup_elem(elem(tup,elem(pos,0)),Tuple.delete_at(pos,0))

  @doc """
  Modify an element of the n-dimensional tuple structure used to encode fields.
  """
  def ntup_put_elem(tup, {i}, val), do: put_elem(tup, i, val)
  def ntup_put_elem(tup, pos, val), do: put_elem(tup,elem(pos,0), ntup_put_elem(elem(tup,elem(pos,0)), Tuple.delete_at(pos,0), val))

  @doc """
  Determine dimensions for an n-dimensional tuple structure.
  """
  def ntup_dim(tup), do: ntup_dim(tup,[])
  defp ntup_dim({},res), do: res ++ [0]
  defp ntup_dim(tup,res) when is_tuple(tup), do: ntup_dim(elem(tup,0), res ++ [tuple_size(tup)])
  defp ntup_dim(_,res), do: res
end
