defmodule MsprChalTest do
  use ExUnit.Case
  doctest MsprChal

  test "Board Generation" do
    assert MsprChal.gen_board({2,2}, 3, {0,0}) == {{false, true}, {true, true}}
    assert MsprChal.gen_board({2,2}, 4, {1,1}) == {{true, true}, {true, false}}
    assert MsprChal.gen_board({3,3,3}, 0, {1, 1, 1}) == {{{false, false, false}, {false, false, false}, {false, false, false}}, {{false, false, false}, {false, false, false}, {false, false, false}}, {{false, false, false}, {false, false, false}, {false, false, false}}}
  end

  test "Mine List" do
    assert MsprChal.gen_mines(10,10) == [true, true, true, true, true, true, true, true, true, true]
    assert MsprChal.gen_mines(1,0) == [false]
    assert MsprChal.gen_mines(1,1) == [true]
  end

  test "Hidden Board" do
    assert MsprChal.hidden_board({1}) == {-1}
    assert MsprChal.hidden_board({4}) == {-1, -1, -1, -1}
    assert MsprChal.hidden_board({3,3}) == {{-1, -1, -1}, {-1, -1, -1}, {-1, -1, -1}}
  end

  test "Explore" do
    assert MsprChal.explore({-1, -1, -1, -1, -1}, {0, 0, 0, 0, 0}, {0}) == {0, 0, 0, 0, 0}
  end

  test "Bomb count around" do
    tfield = {{0, 0, 0, -2}, {0, 0, 0, 0}, {-2, -2, 0, 0}, {0, -2, 0, 0}}
    assert MsprChal.bcount_around(tfield, {0, 0}) == 0
    assert MsprChal.bcount_around(tfield, {0, 3}) == 0
    assert MsprChal.bcount_around(tfield, {3, 0}) == 3
    assert MsprChal.bcount_around(tfield, {1, 2}) == 2
  end

  test "Parse" do
    tfield = {{false, false, false, true}, {false, false, false, false}, {true, true, false, false}, {false, true, false, false}}
    assert MsprChal.parse(tfield, {0, 0}) == 0
    assert MsprChal.parse(tfield, {0, 3}) == -2
    assert MsprChal.parse(tfield, {3, 0}) == 3
    assert MsprChal.parse(tfield, {1, 2}) == 2
  end

  test "Challenge Generation" do
    assert MsprChal.gen_chal({2,2}, 3, {0, 0}) == {{{3, -2}, {-2, -2}}, {{3, -1}, {-1, -1}}}
    assert MsprChal.gen_chal({2,2}, 4, {1, 0}) == {{{-2, -2}, {3, -2}}, {{-1, -1}, {3, -1}}}
    assert MsprChal.gen_chal({3,3,3}, 0, {0, 0, 0}) == {{{{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}, {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}, {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}}, {{{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}, {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}, {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}}}
  end

  test "Solution Check" do
    assert MsprChal.solved?({{-1, -1, -1}, {2, 3, 2}, {0, 0, 0}}, {{-2, -2, -2}, {2, 3, 2}, {0, 0, 0}})
    assert MsprChal.solved?({{-2, -2, -2}, {2, 3, 2}, {0, 0, 0}}, {{-2, -2, -2}, {2, 3, 2}, {0, 0, 0}})
    refute MsprChal.solved?({{-1, -1, -1}, {-1, 4, 2}, {-1, 1, 0}}, {{-2, -2, -2}, {3, 4, 2}, {-2, 1, 0}})
  end

  test "Safe Actions" do
    tfield = {{-2, -2, -2}, {2, 3, 2}, {0, 0, 0}}
    refute MsprChal.safe_acts?(tfield, [{:explore, {0, 0}}])
    assert MsprChal.safe_acts?(tfield, [{:flag, {2, 0}}])
    assert MsprChal.safe_acts?(tfield, [{:explore, {1, 0}}])
    assert MsprChal.safe_acts?(tfield, [{:flag, {1, 0}}])
  end
end
