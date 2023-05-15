defmodule MsprGenTest do
  use ExUnit.Case
  doctest MsprGen

  test "List Mapping" do
    assert MsprGen.list_map({1,2,3}, []) == []
    assert MsprGen.list_map({}, [{1, 2}]) == []
    assert MsprGen.list_map({1,2,3}, [{1, 2}]) == [{1, 2, 1}, {1, 2, 2}, {1, 2, 3}]
    assert MsprGen.list_map({1,2}, [{1, 2}, {3, 4}]) == [{1, 2, 1}, {1, 2, 2}, {3, 4, 1}, {3, 4, 2}]
  end

  test "Permutations" do
    assert MsprGen.gen_perm({{0, 1}, {0, 1}}) == [{0,0}, {0,1}, {1,0}, {1,1}]
    assert MsprGen.gen_perm({{}, {0, 1}}) == []
    assert MsprGen.gen_perm({{0, 1}, {}}) == []
    assert MsprGen.gen_perm({{}, {}}) == []
    assert MsprGen.gen_perm({{0, 1}, {2}}) == [{0, 2}, {1, 2}]
  end

  test "Count Updates" do
    assert MsprGen.update_count(-2, {0,0,0}) == {1,0,0}
    assert MsprGen.update_count(-1, {0,0,0}) == {0,1,0}
    assert MsprGen.update_count(0, {0,0,0}) == {0,0,1}
    assert MsprGen.update_count(2, {0,0,0}) == {0,0,1}
    assert MsprGen.update_count(8, {0,0,0}) == {0,0,1}
  end

  test "Count Around" do
    tfield = {{2, -2, 0, 0, 0, 0, 0, 0, 0}, {-1, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, -2, -2, -1, 0, 0, 0}, {0, 0, 0, -2, 4, -2, 0, 0, 0}}
    assert MsprGen.count_around(tfield, {0, 0}) == {1, 1, 1}
    assert MsprGen.count_around(tfield, {3, 4}) == {4, 1, 0}
  end

  test "Valid Indexing 1D" do
    tfield = {0, 0, 0, 0, 0, 0, 0, 0, 0}
    assert MsprGen.valid_indices(tfield, {0}) == {{0, 1}}
    assert MsprGen.valid_indices(tfield, {4}) == {{3, 4, 5}}
    assert MsprGen.valid_indices(tfield, {8}) == {{7, 8}}
  end

  test "Valid Indexing 2D" do
    tfield = {{0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0}}
    assert MsprGen.valid_indices(tfield, {0, 0}) == {{0, 1}, {0, 1}}
    assert MsprGen.valid_indices(tfield, {2, 0}) == {{1, 2, 3}, {0, 1}}
    assert MsprGen.valid_indices(tfield, {0, 2}) == {{0, 1}, {1, 2, 3}}
    assert MsprGen.valid_indices(tfield, {2,4}) == {{1, 2, 3}, {3, 4, 5}}
    assert MsprGen.valid_indices(tfield, {3, 4}) == {{2, 3}, {3, 4, 5}}
    assert MsprGen.valid_indices(tfield, {2, 8}) == {{1, 2, 3}, {7, 8}}
    assert MsprGen.valid_indices(tfield, {3, 8}) == {{2, 3}, {7, 8}}
  end
  
  test "neighbours" do
    assert MsprGen.neighbours(0) == [-1, 0, 1]
    assert MsprGen.neighbours(8) == [7, 8, 9]
  end

  test "Tuple Reversal" do
    assert MsprGen.rev_tup({}) == {}
    assert MsprGen.rev_tup({1}) == {1}
    assert MsprGen.rev_tup({0, 1}) == {1, 0}
    assert MsprGen.rev_tup({0, 1, 2}) == {2, 1, 0}
  end

  test "Board Shaping" do
    assert MsprGen.shape_board([0], {1}) == {0}
    assert MsprGen.shape_board([0, 1], {1,2}) == {{0, 1}}
    assert MsprGen.shape_board([0, 1], {2,1}) == {{0},{1}}
    assert MsprGen.shape_board([0, 1, 2, 3, 4, 5], {2,3}) == {{0, 1, 2}, {3, 4, 5}}
    assert MsprGen.shape_board([0, 1, 2, 3, 4, 5, 6, 7], {2, 2, 2}) == {{{0, 1}, {2, 3}}, {{4, 5}, {6, 7}}}
  end

  test "Linear Position" do
    assert MsprGen.lin_pos({8},{0}) == 0
    assert MsprGen.lin_pos({8},{7}) == 7
    assert MsprGen.lin_pos({2,2},{1,0}) == 2
    assert MsprGen.lin_pos({2,2,2},{1,0,1}) == 5
  end

  test "Boolean to Integer" do
    assert MsprGen.bool_to_int(true) == 1
    assert MsprGen.bool_to_int(false) == 0
    assert MsprGen.bool_to_int(nil) == 0
  end

  test "Get Unexplored" do
    refute {0, 0} in MsprGen.get_unexplored({{0, -1}, {-1, -1}}, {0, 0})
    assert {0, 1} in MsprGen.get_unexplored({{0, -1}, {-1, -1}}, {0, 0})
    assert {1, 0} in MsprGen.get_unexplored({{0, -1}, {-1, -1}}, {0, 0})
    assert {1, 1} in MsprGen.get_unexplored({{0, -1}, {-1, -1}}, {0, 0})
    assert MsprGen.get_unexplored({{0, 0}, {0, 0}}, {0, 0}) == []
  end

  test "Perimeter" do
    assert {0, 0} in MsprGen.perimeter({{-1, 1, 0}, {1, 1, 0}, {-1, 1, 0}})
    assert {2, 0} in MsprGen.perimeter({{-1, 1, 0}, {1, 1, 0}, {-1, 1, 0}})
    assert {1, 1} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {1, 2} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {1, 3} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {2, 1} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {2, 3} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {2, 4} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {3, 1} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {3, 4} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {4, 1} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {4, 2} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {4, 3} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
    assert {4, 4} in MsprGen.perimeter({{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}})
  end
end
