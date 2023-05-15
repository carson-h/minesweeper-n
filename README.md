# N-dimensional Minesweeper

[Minesweeper](https://en.wikipedia.org/wiki/Minesweeper_(video_game)) is a classic video game and puzzle traditionally played in 2-dimensional space. While this is an amusing diversion in itself, an extension was desired for improved complexity. The board and rules were generalised to be applicable in n-dimensions.

Board generation tools and solvers were implemented for n-dimensional boards. Concurrency was highly leveraged to improve the speed of exhaustive searches of board arrangements.

# Strategy

The strategy used in solving the n-dimensional boards was loosely based on the thesis paper [Minesweeper: A Statistical and Computational Analysis](https://minesweepergame.com/math-papers.php) by Andrew Fowler and Andrew Young in 2004. An initial basic search is performed in a loop until no more additional actions are discovered. If this fails, a search is performed considering the total number of mines remaining and the total number of unexplored spaces remaining. If this also fails, an exhaustive search of potential configurations of the perimeter of known spaces is performed to determine if any spaces are guaranteed to be safe or unsafe in valid configurations, or failing this the safest place to explore.

# Representation

Fields are represented as n-tuples of integers (eg. { {-1, -1, 1 }, {-1, -1, 1}, {-1, 2, 0} }).
- -1 represents an unexplored space.
- -2 represents a flag.
- -3 represents an intended exploration.
- Other values represent the revealed number of adjacent bombs.

# Contributing

If you really want to you can contribute. No active maintenace is going to be provided for this project.
