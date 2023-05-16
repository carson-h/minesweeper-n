defmodule MsprSolveTest do
  use ExUnit.Case
  doctest MsprSolve

  test "Check" do
    tfield = {{2, -2, 0, 0, 0, 0, 0, 0, 0}, {-1, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, -2, -2, -1, 0, 0, 0}, {0, 0, 0, -2, 4, -2, 0, 0, 0}}
    assert MsprSolve.check(tfield, {0,0}) == :flag
    assert MsprSolve.check(tfield, {3,4}) == :explore
    assert MsprSolve.check(tfield, {2,8}) == :nil
  end

  test "Standard Search" do
    assert {:flag, {0, 1}} in MsprSolve.stsearch({{3, -1}, {-1, -1}})
    assert {:flag, {0, 1}} in MsprSolve.stsearch({{3, -1}, {-1, -1}})
    assert {:flag, {1, 1}} in MsprSolve.stsearch({{3, -1}, {-1, -1}})
    assert {:explore, {0, 2}} in MsprSolve.stsearch({{-2, 2, -1}, {-2, 3, 1}, {2, -1, 1}})
    assert {:flag, {2, 1}} in MsprSolve.stsearch({{-2, 2, -1}, {-2, 3, 1}, {2, -1, 1}})
  end

  test "Mark Surrounding" do
    assert {:flag, {0, 1}} in MsprSolve.mark_surr({{3, -1}, {-1, -1}}, {0, 0}, :flag)
    assert {:flag, {1, 0}} in MsprSolve.mark_surr({{3, -1}, {-1, -1}}, {0, 0}, :flag)
    assert {:flag, {1, 1}} in MsprSolve.mark_surr({{3, -1}, {-1, -1}}, {0, 0}, :flag)
    assert {:explore, {0, 2}} in MsprSolve.mark_surr({{-2, 2, -1}, {-2, 3, 1}, {2, -1, 1}}, {0, 1}, :explore)
    assert {:flag, {2, 1}} in MsprSolve.mark_surr({{-2, 2, -1}, {-2, 3, 1}, {2, -1, 1}}, {2, 2}, :flag)
  end

  test "Write Actions" do
    tfield = {{2, -2, 1 }, {-1, 2, 0}, {1, 1, -1}}
    assert MsprSolve.write_acts(tfield, [{:explore, {2,2}}, {:flag, {1,0}}]) == {{2, -2, 1}, {-2, 2, 0}, {1, 1, -3}}
    assert MsprSolve.write_acts(tfield, []) == {{2, -2, 1}, {-1, 2, 0}, {1, 1, -1}}
    assert MsprSolve.write_acts(tfield, [{:nil, {1,2}}]) == {{2, -2, 1}, {-1, 2, 0}, {1, 1, -1}}
  end

  test "prsearch" do
    tfield = {{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}}
    assert hd(MsprSolve.prsearch(tfield, 11)) in [{:explore, {1, 1}}, {:explore, {1, 2}}, {:explore, {1, 3}}]
    assert hd(MsprSolve.prsearch(tfield, 11, 1)) in [{:explore, {1, 1}}, {:explore, {1, 2}}, {:explore, {1, 3}}]
  end

  test "Solution Generation" do
    tfield = {{-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, 1, -1, -1, -1}, {-1, -1, 3, 2, -1, -1}, {-1, -1, -1, -1, -1, -1}, {-1, -1, -1, -1, -1, -1}}
    assert [{3, 1}, {4, 2}, {4, 3}] in MsprSolve.gen_sols(tfield, 11, MsprGen.perimeter(tfield))
    assert [{2, 1}, {4, 2}, {4, 3}] in MsprSolve.gen_sols(tfield, 11, MsprGen.perimeter(tfield))
    assert [{2, 3}, {4, 1}, {4, 2}] in MsprSolve.gen_sols(tfield, 11, MsprGen.perimeter(tfield))
    assert [{2, 3}, {4, 1}, {4, 3}] in MsprSolve.gen_sols(tfield, 11, MsprGen.perimeter(tfield))
    assert [{1, 1}, {4, 1}, {4, 2}, {4, 3}] in MsprSolve.gen_sols(tfield, 11, MsprGen.perimeter(tfield))
    #assert [{, }, {, }, {, }, {, }] in MsprSolve.gen_sols(tfield, 11, MsprGen.perimeter(tfield))
    tfield_b = {{-1, -1, 2, -2, 1, 0, 0, 0, 0}, {-1, -1, 2, 1, 1, 0, 0, 0, 0}, {-1, -1, 2, 0, 0, 0, 0, 0, 0}, {-1, -1, 1, 0, 0, 0, 1, 1, 1}, {-1, -1, 1, 0, 0, 0, 1, -2, 1}, {-1, -1, 1, 0, 0, 0, 1, 1, 1}, {-1, -1, 2, 0, 0, 1, 1, 2, 1}, {-1, -1, 2, 1, 1, 2, -2, 2, -2}, {-1, -1, 1, 1, -2, 2, 1, 2, 1}}
    assert MsprSolve.gen_sols(tfield_b, 5, MsprGen.perimeter(tfield_b)) == [[{1, 1}, {3, 1}, {6, 1}, {7, 1}]]
  end

  test "Board Validation" do
    refute MsprSolve.valid_board?({{-2, -2, -2}, {2, 3, 1}, {0, 0, 0}})
    assert MsprSolve.valid_board?({{-2, -2, -2}, {2, 3, 2}, {0, 0, 0}})
    assert MsprSolve.valid_board?({{-1, -2, -2}, {2, 3, 2}, {-1, -1, -1}})
    refute MsprSolve.valid_board?({{-2, -2, -2}, {2, 3, 2}, {-1, -2, -1}})
  end
end
