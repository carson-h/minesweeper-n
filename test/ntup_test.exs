defmodule NtupTest do
  use ExUnit.Case
  doctest Ntup

  test "Indexing" do
    tfield = {{0, 1, 2, 3},{4, 5, 6, 7},{8, 9, 10, 11}}
    assert Ntup.ntup_elem(tfield, {0, 0}) == 0
    assert Ntup.ntup_elem(tfield, {0, 3}) == 3
    assert Ntup.ntup_elem(tfield, {1, 2}) == 6
    assert Ntup.ntup_elem(tfield, {2, 1}) == 9
    assert Ntup.ntup_elem({0, 1, 2, 3, 4, 5, 6, 7}, {4}) == 4
  end

  test "Dimensions" do
    tfield = {{2, -2, 0, 0, 0, 0, 0, 0, 0}, {-1, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, -2, -2, -1, 0, 0, 0}, {0, 0, 0, -2, 4, -2, 0, 0, 0}}
    assert Ntup.ntup_dim(tfield) == [4, 9]
    assert Ntup.ntup_dim({}) == [0]
    assert Ntup.ntup_dim({0, 1, 2, 3}) == [4]
    assert Ntup.ntup_dim({1}) == [1]
    assert Ntup.ntup_dim({{{{}}}}) == [1, 1, 1, 0]
  end

  test "Put" do
    tfield = {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}
    assert Ntup.ntup_put_elem(tfield, {2, 1}, 9) == {{0, 1, 2}, {3, 4, 5}, {6, 9, 8}}
    assert Ntup.ntup_put_elem(tfield, {0, 0}, 9) == {{9, 1, 2}, {3, 4, 5}, {6, 7, 8}}
    assert Ntup.ntup_put_elem(tfield, {1, 2}, 9) == {{0, 1, 2}, {3, 4, 9}, {6, 7, 8}}
  end
end
