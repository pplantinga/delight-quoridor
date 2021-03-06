import std.stdio : writeln;
import std.range : iota;
bool In(H, N)(H h, N n) {
	foreach (i; h)
		if (i == n) return true;
	return false;
}
/++
 + The 'Board' class holds all the information
 + pertaining to a quoridor board, like the ai
 +
 + Author: Peter Plantinga
 + Start Date: Dec 16, 2011
 +/

import std.math : abs;
import std.datetime : StopWatch;
import std.random : uniform;
import std.conv : to;
import std.string : format;

class Board
{

	/// Main constructor for 'Board'
	this()
	{
		my_x[0] = (BOARD_SIZE - BOARD_SIZE % 4) / 2;
		my_y[0] = BOARD_SIZE - 1;
		my_x[1] = (BOARD_SIZE - BOARD_SIZE % 4) / 2 + BOARD_SIZE % 4 - 1;
		my_y[1] = 0;
		my_board[my_x[0]][my_y[0]] = 1;
		my_board[my_x[1]][my_y[1]] = 2;
		my_walls[] = WALL_COUNT;
		my_turn = 0;
		path_lengths = [path_length(0), path_length(1)];
		my_openings = [uniform(0, 6), uniform(0, 6)];
	}

	unittest
	{
		writeln("Starting default constructor test");

		Board board = new Board();
		assert(board.my_x == [BOARD_SIZE / 2, BOARD_SIZE / 2]);
		assert(board.my_y == [BOARD_SIZE - 1, 0]);
		assert(board.my_walls == [WALL_COUNT, WALL_COUNT]);
		assert(board.my_turn == 0);
		assert(board.my_board[board.my_x[0]][board.my_y[0]] == 1);
		assert(board.my_board[board.my_x[1]][board.my_y[1]] == 2);
	}

	this(Board b)
	{
		my_x = b.my_x.dup;
		my_y = b.my_y.dup;
		my_walls = b.my_walls.dup;
		foreach (i, row; my_board)
		{
			my_board[i] = b.my_board[i].dup;
		}
		my_turn = b.my_turn;
		path_lengths = b.path_lengths.dup;
		walls_in_path[0] = b.walls_in_path[0].dup;
		walls_in_path[1] = b.walls_in_path[1].dup;
		my_openings = b.my_openings;
	}

	unittest
	{
		writeln("Starting copy constructor test");

		Board board = new Board();
		board.place_wall(3, 3, 1);
		
		Board new_board = new Board(board);
		assert(new_board.my_board[3][3] == 3);
		assert(new_board.my_walls[0] == WALL_COUNT - 1);
		assert(new_board.my_x[0] == BOARD_SIZE / 2);
	}

	/// Accessor methods
	int board_value(int x, int y)
	{
		return my_board[x][y];
	}
	int wall_count(int player)
	{
		return my_walls[player];
	}
	auto board_size()
	{
		return BOARD_SIZE;
	}

	/++
	 + Alters board state with a move if legal.
	 +
	 + Params:
	 +   move_string = a properly formatted move like "e3" or "b7v"
	 +
	 + Returns: 0 unless someone won the game. If so, then the player who won.
	 +/
	int move(string move_string)
	{

		int[3] move_array = move_string_to_array(move_string);
		if (move_array[2] == 0)
		{

			if (!move_piece(move_array[0], move_array[1]))
			{
				throw new Exception(format("Illegal move, [x, y]: %s", move_array[0 .. 2]));
			}
			else if ((
			(my_turn % 2) && move_array[1] == 0
				 || !(my_turn % 2) && move_array[1] == BOARD_SIZE - 1
			))
			{
				return (my_turn + 1) % 2 + 1;
			}
		}

		else
		{
			if (!place_wall(move_array[0], move_array[1], move_array[2]))
			{
				throw new Exception(format("Illegal wall, [x, y, o]: %s", move_array));
			}
		}

		return 0;
	}

	unittest
	{
		writeln("Starting move() test");

		Board board = new Board();

		// XXX: IF YOU CHANGE THE BOARD SIZE, CHANGE THIS
		static if (BOARD_SIZE == 17)
		{

			// moves
			assert(board.move("e8") == 0);
			assert(board.my_board[8][14] == 1);
			assert(board.my_board[8][16] == 0);
			assert(board.my_board[8][0] == 2);

			board.move("e2");
			assert(board.my_board[8][2] == 2);
			assert(board.my_board[8][0] == 0);
			assert(board.my_board[8][14] == 1);

			// Make sure nothing changes during illegal move
			try
			{
				board.move("a4");
				assert(0);
			}

			catch (Exception e)
			{
				assert(board.my_board[8][2] == 2);
				assert(board.my_board[0][6] == 0);
				assert(board.my_board[8][14] == 1);
			}

			// Move till we're adjacent
			board.move("e7");
			board.move("e3");
			board.move("e6");
			board.move("e4");
			board.move("e5");
			
			// Try jump
			board.move("e6");
			assert(board.my_board[8][10] == 2);
			assert(board.my_board[8][8] == 1);
			assert(board.my_board[8][6] == 0);

			// Try walls
			board.move("e6h");
			assert(board.my_board[8][11] == 3);
			assert(board.my_board[9][11] == 3);
			assert(board.my_board[10][11] == 3);

			try
			{
				board.move("e6v");
				assert(0);
			}

			catch (Exception e)
			{
				assert(board.my_board[9][10] == 0);
				assert(board.my_board[9][11] == 3);
				assert(board.my_board[9][12] == 0);
			}

			board.move("d5v");
			assert(board.my_board[7][8] == 3);
			assert(board.my_board[7][9] == 3);
			assert(board.my_board[7][10] == 3);

			board.move("e4h");
			board.move("f5h");
			
			try
			{
				board.move("e7");
				assert(0);
			}

			catch (Exception e)
			{
				assert(board.my_board[8][12] == 0);
				assert(board.my_board[8][10] == 2);
				assert(board.my_board[8][8] == 1);
			}

			try
			{
				board.move("d6");
				assert(0);
			}

			catch (Exception e)
			{
				assert(board.my_board[6][10] == 0);
				assert(board.my_board[8][10] == 2);
				assert(board.my_board[8][8] == 1);
			}

			board.move("f6");
			assert(board.my_board[10][10] == 1);

			board.move("g6");
			board.move("h6");
			board.move("g7");
			board.move("h5");
			board.move("g8");
			board.move("h4");
			
			// check player 2 win
			assert(board.move("g9") == 2);

			board.undo(1);
			
			board.move("h8");
			board.move("h3");
			board.move("i8");
			board.move("h2");
			board.move("i7");
			
			// check player 1 win
			assert(board.move("h1") == 1);
		}
	}

	/++
	 + ai_move uses minimax to decide on a move and take it
	 +
	 + Params:
	 +   seconds = the length of time to search moves
	 +
	 + Returns: the move string (e.g. 'e3' or 'b7v')
	 +   with a 'w' at the end if this move ended the game
	 +/
	string ai_move(int seconds)
	{

		// try: an opening
		int[] opening_move = opening(my_openings[my_turn % 2]);

		bool moved = false;
		if (opening_move)
		{
			if (opening_move[2])
			{
				if (place_wall(opening_move[0], opening_move[1], opening_move[2]))
				{
					moved = true;
				}
			}
			else if (move_piece(opening_move[0], opening_move[1]))
			{
				moved = true;
			}
		}

		// If we didn't do an opening move
		if (!moved)
		{
			int i = 2;
			int[] move = [0];
			int[] test_move;
			StopWatch sw;
			sw.start();
			
			// iterative deepening
			while (i < 100)
			{

				test_move = negascout(new Board(this), i, -1000, 1000, seconds, sw, move);
				i += 1;
				if (sw.peek.seconds < seconds && i < 100)
				{
					move = test_move;
				}
				else
				{
					break;
				}
			}

			// Print the level that we got to
			debug
			{
				writeln(i);
			}

			sw.stop();
			
			if (move[2])
			{
				if (!place_wall(move[0], move[1], move[2]))
				{
					throw new Exception(format("AI TRIED TO PLAY %s", move));
				}
			}

			else
			{
				if (!move_piece(move[0], move[1]))
				{
					throw new Exception(format("AI TRIED TO PLAY %s", move));
				}
			}

			// Check for the end of the game
			auto y = BOARD_SIZE - 1 - move[1];
			if (my_turn % 2)
			{
				y = move[1];
			}
			if (!move[2] && y == 0)
			{
				return move_array_to_string(move) ~ 'w';
			}
			else
			{
				return move_array_to_string(move);
			}
		}

		// return the opening if we get here
		return move_array_to_string(opening_move);
	}

	/++
	 + undo last move
	 +
	 + Params:
	 +   n = the number of moves to undo
	 +/
	auto undo(int n)
	{

		foreach (i; 0 .. n)
		{
			int x = moves[$ - 1][0];
			int y = moves[$ - 1][1];
			int o = moves[$ - 1][2];

			// update turn
			my_turn -= 1;
			int turn = my_turn % 2;

			// undo wall
			if (o)
			{
				int x_add = o - 1;
				int y_add = o % 2;

				my_board[x][y] = 0;
				my_board[x + x_add][y + y_add] = 0;
				my_board[x - x_add][y - y_add] = 0;

				my_walls[turn] += 1;
			}

			// undo move
			else
			{
				my_board[x][y] = turn + 1;
				my_board[my_x[turn]][my_y[turn]] = 0;
				my_x[turn] = x;
				my_y[turn] = y;
			}

			path_lengths = [path_length(0), path_length(1)];

			moves = moves[0 .. $ - 1];
		}
	}

	/++
	 + This function takes an internal move
	 + and formats it as a human-readable string
	 +/
	string move_array_to_string(int[] move)
	{

		string move_string;
		
		// letter
		move_string ~= to!char(move[0] / 2 + 97);

		// number
		move_string ~= format("%s", move[1] / 2 + 1);

		// orientation
		if (move[2] == 1)
		{
			move_string ~= 'v';
		}
		else if (move[2] == 2)
		{
			move_string ~= 'h';
		}

		return move_string;
	}

	private
	{
		static immutable BOARD_SIZE = 17;
		static immutable WALL_COUNT = (BOARD_SIZE + 1) * (BOARD_SIZE + 1) / 32;

		int[BOARD_SIZE][BOARD_SIZE] my_board;
		int my_turn;
		int[2] my_x;
		int[2] my_y;
		int[2] my_walls;
		int[2] path_lengths;
		int[2] my_openings;
		int[][] moves;
		
		/+
		 + This stores the walls that would block a shortest path
		 + so we can best determine when to recalculate paths
		 +/
		bool[(BOARD_SIZE - 1) * (BOARD_SIZE - 1) / 2][2] walls_in_path;
		
		/++
		 + Checks for move legality, and if legal, moves the player
		 +
		 + Params:
		 +   x = the desired horizontal location
		 +   y = the desired vertical location
		 +
		 + Returns: whether or not the move occurred 
		 +/
		bool move_piece(int x, int y)
		{

			int old_x = my_x[my_turn % 2];
			int old_y = my_y[my_turn % 2];

			if (is_legal_move(x, y, old_x, old_y))
			{

				// make the move
				my_x[my_turn % 2] = x;
				my_y[my_turn % 2] = y;
				my_board[old_x][old_y] = 0;
				my_board[x][y] = my_turn % 2 + 1;

				// update shortest path length
				path_lengths[my_turn % 2] = path_length(my_turn % 2);

				// update turn
				my_turn += 1;

				// add old location to undo list
				moves ~= [old_x, old_y, 0];

				return true;
			}

			return false;
		}

		unittest
		{
			writeln("Starting move_piece() test");

			Board board = new Board();
			board.move_piece(BOARD_SIZE / 2, BOARD_SIZE - 3);
			assert(board.my_board[BOARD_SIZE / 2][BOARD_SIZE - 3] == 1);
			assert(board.my_board[BOARD_SIZE / 2][BOARD_SIZE - 1] == 0);
		}

		/++
		 + Checks for wall legality, and if legal, places the wall
		 +
		 + Params:
		 +   x = the horizontal location
		 +   y = the vertical location
		 +   o = the orientation (1 for vertical, 2 for horizontal)
		 +/
		bool place_wall(int x, int y, int o)
		{

			if (!is_legal_wall(x, y, o))
			{
				return false;
			}

			// Add the wall for checking both player's paths
			wall_val(x, y, o, 3);
			
			int test_length_one;
			int test_length_two;
			 // check player 1's path if the wall blocks it
			if (walls_in_path[0][linearize(x, y, o)])
			{

				test_length_one = path_length(0);

				if (!test_length_one)
				{

					// remove wall
					wall_val(x, y, o, 0);
					return false;
				}
			}

			// check player 2's path if the wall blocks it
			if (walls_in_path[1][linearize(x, y, o)])
			{

				test_length_two = path_length(1);

				if (!test_length_two)
				{

					// remove wall
					wall_val(x, y, o, 0);
					return false;
				}
			}

			// Both players have a path, so update shortest paths
			if (test_length_one)
			{
				path_lengths[0] = test_length_one;
			}

			if (test_length_two)
			{
				path_lengths[1] = test_length_two;
			}

			// Reduce the walls remaining
			my_walls[my_turn % 2] -= 1;

			// update turn
			my_turn += 1;

			// add wall to the list of moves (for undo)
			moves ~= [x, y, o];

			return true;
		}

		unittest
		{
			writeln("Starting place_wall() test");

			Board board = new Board();

			// vertical wall
			assert(board.place_wall(1, 7, 1));
			assert(board.my_board[1][7] == 3);
			assert(board.my_board[1][6] == 3);
			assert(board.my_board[1][8] == 3);

			// horizontal wall
			assert(board.place_wall(1, 5, 2));
			assert(board.my_board[1][5] == 3);
			assert(board.my_board[0][5] == 3);
			assert(board.my_board[2][5] == 3);

			static if (BOARD_SIZE == 17)
			{

				// walls in path
				int x = 9;
				int y = 1;
				int o = 2;

				assert(board.walls_in_path[1][board.linearize(x, y, o)]);
				assert(board.walls_in_path[1][board.linearize(x, y, o)]);
				y = 15;
				assert(board.walls_in_path[0][board.linearize(x, y, o)]);
				x = 9;
				assert(board.walls_in_path[0][board.linearize(x, y, o)]);

				// Walls cannot cut off both people
				board.place_wall(3, 7, 2);
				board.place_wall(7, 7, 2);
				board.place_wall(11, 7, 2);
				
				assert(!board.place_wall(15, 7, 2));

				// Walls cannot cut off either person individually
				board.place_wall(7, 1, 1);
				board.place_wall(9, 1, 1);
				board.place_wall(7, 15, 1);
				board.place_wall(9, 15, 1);
				
				assert(!board.place_wall(9, 13, 2));
				assert(!board.place_wall(9, 3, 2));

				// Walls are allowed to technically cut off people,
				 // but only when the last spot is taken by a person
				board.place_wall(1, 15, 2);
				board.place_wall(5, 15, 2);
				board.place_wall(11, 15, 2);
				assert(board.place_wall(15, 15, 2));
				board.place_wall(1, 1, 2);
				board.place_wall(5, 1, 2);
				board.place_wall(11, 1, 2);
				assert(board.place_wall(15, 1, 2));

				// Make sure both players run out of walls at 10 each
				board.place_wall(1, 3, 2);
				board.place_wall(1, 5, 2);
				board.place_wall(1, 9, 2);
				board.place_wall(1, 11, 2);
				
				assert(!board.place_wall(1, 11, 2));
				assert(board.my_walls[0] == 0);
				assert(board.my_walls[1] == 0);

				board.move("e8");
				assert(!board.place_wall(1, 11, 2));

				// Another weird situation that doesn't technically have a path
				 // but is still legal
				board = new Board();
				board.move("a8h");
				board.move("c8h");
				board.move("f8h");
				board.move("h8h");
				board.move("e8");
				
				assert(board.place_wall(7, 3, 2));
			}
		}

		// Add a wall at x, y, o
		auto wall_val(int x, int y, int o, int val)
		{

			int x_add = o - 1;
			int y_add = o % 2;

			my_board[x][y] = val;
			my_board[x + x_add][y + y_add] = val;
			my_board[x - x_add][y - y_add] = val;
		}

		unittest
		{
			writeln("Starting walls_in_path test");

			Board board = new Board();
			foreach (x; [BOARD_SIZE / 2 - 1, BOARD_SIZE / 2 + 1])
			{
				foreach (y; iota(1, BOARD_SIZE - 1, 2))
				{
					assert(board.walls_in_path[0][board.linearize(x, y, 2)]);
					assert(board.walls_in_path[1][board.linearize(x, y, 2)]);
				}
			}
		}

		/++
		 + Translates moves from strings like 'a3h' to a more useful format
		 +
		 + XXX: IF YOU CHANGE THE BOARD_SIZE CHANGE THIS
		 +
		 + Returns: array of form [x, y, o]
		 +   where o is the orientation, 0 no wall, 1 vertical, 2 horizontal
		 +/
		int[3] move_string_to_array(string move_string)
		{
			if (move_string.length == 3)
			{
				assert(In(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'], move_string[0]));
				assert(In(['1', '2', '3', '4', '5', '6', '7', '8'], move_string[1]));
				assert(In(['h', 'v'], move_string[2]));
			}
			else
			{
				assert(In(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'], move_string[0]));
				assert(In(['1', '2', '3', '4', '5', '6', '7', '8', '9'], move_string[1]));
			}

			int[3] move_array;
			
			// Convert chars to ints, normalizing to 0, 2, 4, 6...
			move_array[0] = (move_string[0] - 'a') * 2;
			move_array[1] = (move_string[1] - '1') * 2;

			// Special rules apply if we've got a wall rather than a move
			if (move_string.length == 3)
			{

				move_array[2] = move_string[2] == 'h';

				// Walls are in a different place than moves, so add 1 to each value
				move_array[] += 1;
			}

			return move_array;
		}

		unittest
		{
			writeln("Starting move_string_to_array() test");

			Board board = new Board();
			int[3] move_array = board.move_string_to_array("e3");
			assert(move_array[0] == 8);
			assert(move_array[1] == 4);
			assert(move_array[2] == 0);

			try
			{
				move_array = board.move_string_to_array("d");
				assert(0);
			}

			catch (Exception e)
			{
				assert(move_array[0] == 8);
			}

			try
			{
				move_array = board.move_string_to_array("e4v2");
				assert(0);
			}

			catch (Exception e)
			{
				assert(move_array[0] == 8);
			}
		}

		/++
		 + Check if this piece movement is legal
		 +
		 + Params:
		 +   x, y = potential new location
		 +   old_x, old_y = current location
		 +
		 + Returns:
		 +   Whether or not the move is legal
		 +/
		bool is_legal_move(int x, int y, int old_x, int old_y)
		{

			// Check for out-of-bounds
			if (!is_on_board(x) || !is_on_board(y))
			{
				return false;
			}

			// Check if another player is where we're going
			if (my_board[x][y] != 0)
			{
				return false;
			}

			// jump dist
			int x_dist = abs(x - old_x);
			int y_dist = abs(y - old_y);
			int avg_x = (x + old_x) / 2;
			int avg_y = (y + old_y) / 2;
			int in_between = my_board[avg_x][avg_y];
			int one_past_x = x + avg_x - old_x;
			int one_past_y = y + avg_y - old_y;

			// normal move: one space away and no wall between
			if ((
			// one space away
				(x_dist == 2 && y_dist == 0
				 || y_dist == 2 && x_dist == 0)

				// no wall in-between
				 && in_between != 3
			))
			{
				return true;
			}

			// jump in a straight line
			else if ((
			(
				// target is two away in the row
					x_dist == 4 && y_dist == 0

					// no wall between players or between opponent and target
					 && my_board[avg_x + 1][old_y] != 3
					 && my_board[avg_x - 1][old_y] != 3

					 || 
					// two away in the column
					y_dist == 4 && x_dist == 0

					// no wall between players or between opponent and target
					 && my_board[old_x][avg_y + 1] != 3
					 && my_board[old_x][avg_y - 1] != 3
				)
				// opponent between target and active player
				 && in_between != 0
			))
			{
				return true;
			}

			/+
			 + jump diagonally if blocked by enemy player and a wall
			 + or another enemy player and the edge of the board
			 +/
			else if ((
			x_dist == 2 && y_dist == 2
				 && (
				// opponent above or below
					my_board[x][old_y] != 0

					// wall or the edge is on the far side of opponent
					 && (!is_on_board(one_past_x)
					 || my_board[one_past_x][old_y] == 3)
					
					// no wall between you and opponent
					 && my_board[avg_x][old_y] != 3

					// no wall between opponent and target
					 && my_board[x][avg_y] != 3

					 || 
					// opponent to one side or the other
					my_board[old_x][y] != 0

					// wall or edge of board beyond opponent
					 && (!is_on_board(one_past_y)
					 || my_board[old_x][one_past_y] == 3)
					
					// no wall between players
					 && my_board[old_x][avg_y] != 3

					// no wall between opponent and target
					 && my_board[avg_x][y] != 3
				)
			))
			{
				return true;
			}
			else
			{
				return false;
			}
		}

		unittest
		{
			writeln("Starting is_legal_move() test");

			Board board = new Board();

			int old_x = board.my_x[board.my_turn % 2];
			int old_y = board.my_y[board.my_turn % 2];

			// Moves
			assert(board.is_legal_move(old_x, old_y - 2, old_x, old_y));
			assert(board.is_legal_move(old_x + 2, old_y, old_x, old_y));
			assert(board.is_legal_move(old_x - 2, old_y, old_x, old_y));
			assert(!board.is_legal_move(old_x - 2, old_y - 2, old_x, old_y));
			assert(!board.is_legal_move(old_x, old_y - 4, old_x, old_y));
			assert(!board.is_legal_move(old_x, old_y + 2, old_x, old_y));
			assert(!board.is_legal_move(old_x, old_y - 1, old_x, old_y));

			/+
			 + Jumps
			 + XXX: This assumes size is 17.
			 + TODO: Maybe I'll eventually get around to generalizing
			 +/
			static if (BOARD_SIZE == 17)
			{

				board.move("e8");
				board.move("e2");
				board.move("e7");
				board.move("e3");
				board.move("e6");
				board.move("e4");
				board.move("e5");
				
				old_x = board.my_x[board.my_turn % 2];
				old_y = board.my_y[board.my_turn % 2];

				// Check vertical jump
				assert(board.is_legal_move(old_x, old_y + 4, old_x, old_y));
				assert(!board.is_legal_move(old_x + 2, old_y + 2, old_x, old_y));
				assert(!board.is_legal_move(old_x - 2, old_y + 2, old_x, old_y));

				board.move("e5h");
				board.move("d4v");
				
				// Check diagonal jump
				assert(board.is_legal_move(old_x + 2, old_y + 2, old_x, old_y));
				assert(!board.is_legal_move(old_x, old_y + 4, old_x, old_y));
				assert(!board.is_legal_move(old_x - 2, old_y + 2, old_x, old_y));

				board.move("f5");
				board.move("g5");
				board.move("h5");
				board.move("i5");
				
				old_x = board.my_x[board.my_turn % 2];
				old_y = board.my_y[board.my_turn % 2];

				// Check the edge of the board
				assert(!board.is_legal_move(old_x + 4, old_y, old_x, old_y));
				assert(board.is_legal_move(old_x + 2, old_y + 2, old_x, old_y));
				assert(board.is_legal_move(old_x + 2, old_y - 2, old_x, old_y));

				board.move("i6");
				board.move("i7");
				board.move("i8");
				board.move("i9");
				
				old_x = board.my_x[board.my_turn % 2];
				old_y = board.my_y[board.my_turn % 2];

				// Check the corner
				assert(board.is_legal_move(old_x - 2, old_y + 2, old_x, old_y));
			}
		}

		/++
		 + Asserts a wall placement is legal
		 +
		 + Params:
		 +   x = horizontal location of new wall
		 +   y = vertical location of new wall
		 +   o = orientation of new wall (vertical, 1, or horizontal, 2)
		 +/
		bool is_legal_wall(int x, int y, int o)
		{

			// Make sure wall isn't in move land
			if (x % 2 != 1 || y % 2 != 1)
			{
				return false;
			}

			// check for out-of-bounds
			if (!is_on_board(x) || !is_on_board(y))
			{
				return false;
			}

			// Make sure orientation is valid
			if (o != 1 && o != 2)
			{
				return false;
			}

			// Make sure the player has walls left
			if (my_walls[my_turn % 2] == 0)
			{
				return false;
			}

			int x_add = o - 1;
			int y_add = o % 2;

			if ((my_board[x][y] != 0
			 || my_board[x + x_add][y + y_add] != 0
				 || my_board[x - x_add][y - y_add] != 0
			))
			{
				return false;
			}

			return true;
		}

		unittest
		{
			writeln("Starting is_legal_wall test");

			Board board = new Board();

			// Walls
			assert(board.is_legal_wall(1, 1, 1));
			assert(board.is_legal_wall(1, 1, 2));
			assert(board.is_legal_wall(BOARD_SIZE - 2, BOARD_SIZE - 2, 1));
			assert(board.is_legal_wall(BOARD_SIZE - 2, BOARD_SIZE - 2, 2));
			assert(!board.is_legal_wall(BOARD_SIZE, 1, 1));
			assert(!board.is_legal_wall(2, 2, 2));

			// Walls cannot overlap
			board.place_wall(1, 7, 2);
			assert(!board.is_legal_wall(1, 7, 2));
			assert(!board.is_legal_wall(1, 7, 1));
			assert(!board.is_legal_wall(3, 7, 2));

			static if (BOARD_SIZE == 17)
			{

				// only ten walls each
				board.place_wall(1, 1, 2);
				board.place_wall(1, 3, 2);
				board.place_wall(1, 5, 2);
				board.place_wall(1, 9, 2);
				board.place_wall(1, 11, 2);
				board.place_wall(1, 13, 2);
				board.place_wall(5, 13, 2);
				board.place_wall(5, 11, 2);
				board.place_wall(5, 9, 2);
				board.place_wall(5, 7, 2);
				board.place_wall(5, 5, 2);
				board.place_wall(5, 3, 2);
				board.place_wall(5, 1, 2);
				board.place_wall(9, 1, 2);
				board.place_wall(9, 3, 2);
				board.place_wall(9, 5, 2);
				board.place_wall(9, 7, 2);
				board.place_wall(9, 9, 2);
				board.place_wall(9, 11, 2);
				
				assert(!board.is_legal_wall(9, 9, 2));

				board.move("f9");
				
				assert(!board.is_legal_wall(9, 9, 2));
			}
		}

		/// Asserts a move is within the limits of the board
		bool is_on_board(int d)
		{
			return d >= 0 && d < BOARD_SIZE;
		}

		unittest
		{
			writeln("Starting is_on_board() test");

			Board board = new Board();
			assert(board.is_on_board(0));
			assert(board.is_on_board(1));
			assert(board.is_on_board(BOARD_SIZE - 1));
			assert(!board.is_on_board(-1));
			assert(!board.is_on_board(BOARD_SIZE));
		}

		/++
		 + Finds the length of the shortest path for a player
		 + Also keeps track of walls that would block the path
		 +
		 + Returns: length of the shortest path, ignoring the other player
		 +   0 for no path
		 +/
		int path_length(int player)
		{
			int other_player = (player + 1) % 2;
			my_board[my_x[other_player]][my_y[other_player]] = 0;

			scope (exit)
			{
				my_board[my_x[other_player]][my_y[other_player]] = other_player + 1;
			}

			// get current location
			int x = my_x[player];
			int y = my_y[player];

			// distance from current location
			int g;
			
			// heuristic distance (distance from goal)
			int h = heuristic(player, y);

			// To keep track of where we go
			int[BOARD_SIZE][BOARD_SIZE] paths;
			
			// Starting location
			paths[x][y] = 1;

			// This is a sort of priority queue, specific to this application
			 // We'll only be adding elements of the same or slightly lower priority
			int[][][int] nodes;
			
			// add first node, current location
			nodes[h] ~= [x, y, g];

			// current stores the node we're using on each iteration
			int[] current;
			int length;
			int key = h;

			// while there are nodes left to evaluate
			while (nodes)
			{
				current = nodes[key][0];
				x = current[0];
				y = current[1];
				g = current[2];
				h = heuristic(player, y);

				// if we've reached the end
				if (h == 0)
				{
					break;
				}

				// Try all moves
				foreach (i; [[x - 2, y], [x, y - 2], [x + 2, y], [x, y + 2]])
				{
					if ((
					is_legal_move(i[0], i[1], x, y)
						 && paths[i[0]][i[1]] == 0
					))
					{
						h = heuristic(player, i[1]);
						paths[i[0]][i[1]] = 100 * x + y + 2;
						nodes[g + h + 2] ~= [i[0], i[1], g + 2];
					}
				}

				/+
				 + if this is the last of this weight
				 + check for empty queue and change the key 
				 +/
				if (nodes[key].length == 1)
				{

					nodes.remove(key);
					
					if (nodes.length == 0)
					{
						return 0;
					}

					while (key !in nodes)
					{
						key += 2;
					}
				}

				else
				{
					nodes[key][0] = nodes[key][$ - 1];
					nodes[key].length -= 1;
				}
			}

			if (!nodes)
			{
				return 0;
			}

			// re-initialize
			walls_in_path[player][] = false;
			int old_x;
			int old_y;
			
			while (paths[x][y] != 1)
			{
				old_x = x;
				old_y = y;
				x = paths[x][y] / 100;
				y = paths[old_x][y] % 100 - 2;
				add_walls(player, x, y, old_x, old_y);
			}

			return g / 2;
		}

		unittest
		{
			writeln("Starting path_lengths test");

			Board board = new Board();

			assert(board.path_lengths == [BOARD_SIZE / 2, BOARD_SIZE / 2]);

			static if (BOARD_SIZE == 17)
			{

				// path length ignores jumps
				board.move("e8");
				assert(board.path_lengths == [7, 8]);

				board.move("e2");
				assert(board.path_lengths == [7, 7]);

				board.move("e4h");
				assert(board.path_lengths == [8, 8]);

				board.move("e1");
				assert(board.path_lengths == [8, 9]);
			}
		}


		/++
		 + This is a heuristic for distance to goal.
		 + Pretty simple, just straight line distance to goal.
		 +/
		auto heuristic(int player, int y)
		{
			if (player)
			{
				return BOARD_SIZE - 1 - y;
			}
			else
			{
				return y;
			}
		}

		/++
		 + This function helps keep track of walls that would interrupt
		 + the shortest path, so we can recalculate when necessary
		 +/
		auto add_walls(int player, int x, int y, int old_x, int old_y)
		{
			int avg_x = (x + old_x) / 2;
			int avg_y = (y + old_y) / 2;

			// horizontal move
			if (abs(x - old_x) == 2)
			{
				if (is_on_board(y - 1))
				{
					walls_in_path[player][linearize(avg_x, y - 1, 1)] = true;
				}

				if (is_on_board(y + 1))
				{
					walls_in_path[player][linearize(avg_x, y + 1, 1)] = true;
				}
			}

			// vertical move
			else
			{
				if (is_on_board(x - 1))
				{
					walls_in_path[player][linearize(x - 1, avg_y, 2)] = true;
				}

				if (is_on_board(x + 1))
				{
					walls_in_path[player][linearize(x + 1, avg_y, 2)] = true;
				}
			}
		}

		/// Calculate linear location in array from x and y
		int linearize(int x, int y, int o)
		{
			return x - 1 + BOARD_SIZE / 2 * (y - 1) + o - 1;
		}

		/// Negascout algorithm
		int[] negascout(Board b, int depth, int alpha, int beta, int seconds, StopWatch sw, int[] best)
		{
			if ((depth <= 0
			 || b.my_y[0] == 0
				 || b.my_y[1] == BOARD_SIZE - 1
				 || sw.peek.seconds > seconds
			))
			{
				int score = evaluate(b);
				if (b.my_turn % 2 == 0)
				{
					score = -score;
				}
				return [0, 0, 0, score];
			}

			// initialize values
			int[] opponent_move;
			int scout_val = beta;
			int best_x;
			int best_y;
			int best_o;
			int score;
			int old_x = b.my_x[b.my_turn % 2];
			int old_y = b.my_y[b.my_turn % 2];
			int old_path_length = b.path_lengths[b.my_turn % 2];
			bool first = true;
			Board test_board = new Board(b);

			// We'll only do this for the root node, where we have a best move recorded
			if (best.length > 1)
			{

				if (best[2] == 0)
				{
					test_board.move_piece(best[0], best[1]);
				}
				else
				{
					test_board.place_wall(best[0], best[1], best[2]);
				}

				opponent_move = negascout(
				test_board, 
					depth - 1, 
					-scout_val, 
					-alpha, 
					seconds, 
					sw, 
					null
				);

				alpha = -opponent_move[3];
				best_x = best[0];
				best_y = best[1];
				best_o = best[2];
				first = false;
			}

			// move piece
			foreach (i; (
			[[old_x - 2, old_y], 
				[old_x, old_y - 2], 
				[old_x + 2, old_y], 
				[old_x, old_y + 2]]
			))
			{
				// legal and we haven't checked it already
				if ((
				b.is_legal_move(i[0], i[1], old_x, old_y)
					 && (
					best.length < 2
						 || best[2] != 0
						 || best[0] != i[0]
						 || best[1] != i[1]
					)
				))
				{
					test_board = new Board(b);
					test_board.move_piece(i[0], i[1]);
					
					/+
					 + Don't consider moves that don't shorten our path
					 + This is usually bad, and sometimes the computer will make a
					 + dumb move to avoid getting blocked by a wall
					 +/
					if (test_board.path_lengths[b.my_turn % 2] >= old_path_length)
					{
						continue;
					}

					opponent_move = negascout(
					test_board, 
						depth - 1, 
						-scout_val, 
						-alpha, 
						seconds, 
						sw, 
						null
					);

					if ((
					alpha < -opponent_move[3]
						 && -opponent_move[3] < beta
						 && !first
					))
					{
						opponent_move = negascout(
						test_board, 
							depth - 1, 
							-beta, 
							-alpha, 
							seconds, 
							sw, 
							null
						);
					}

					if (-opponent_move[3] > alpha)
					{
						alpha = -opponent_move[3];
						best_x = i[0];
						best_y = i[1];
						best_o = 0;
					}

					if (alpha >= beta || sw.peek.seconds > seconds)
					{
						return [best_x, best_y, best_o, alpha];
					}

					scout_val = alpha + 1;

					if (first)
					{
						first = false;
					}
				}

				// Check jumps
				else if ((
				is_on_board(i[0])
					 && is_on_board(i[1])
					 && b.my_board[i[0]][i[1]] != 0
				))
				{
					foreach (j; (
					[[i[0] - 2, i[1]], 
						[i[0], i[1] - 2], 
						[i[0] + 2, i[1]], 
						[i[0], i[1] + 2]]
					))
					{
						if (b.is_legal_move(j[0], j[1], old_x, old_y))
						{
							test_board = new Board(b);
							test_board.move_piece(j[0], j[1]);
							
							/+
							 + Don't consider jumps that make our length longer
							 + There can be situations where the only available move is
							 + a jump that doesn't make our path shorter, so examine those.
							 +/
							if (test_board.path_lengths[b.my_turn % 2] > old_path_length)
							{
								continue;
							}

							opponent_move = negascout(
							test_board, 
								depth - 1, 
								-scout_val, 
								-alpha, 
								seconds, 
								sw, 
								null
							);

							if ((
							alpha < -opponent_move[3]
								 && -opponent_move[3] < beta
								 && !first
							))
							{
								opponent_move = negascout(
								test_board, 
									depth - 1, 
									-beta, 
									-alpha, 
									seconds, 
									sw, 
									null
								);
							}

							if (-opponent_move[3] > alpha)
							{
								alpha = -opponent_move[3];
								best_x = j[0];
								best_y = j[1];
								best_o = 0;
							}

							if ((
							alpha >= beta
								 || sw.peek.seconds > seconds
							))
							{
								return [best_x, best_y, best_o, alpha];
							}

							scout_val = alpha + 1;

							if (first)
							{
								first = false;
							}
						}
					}
				}
			}

			// walls
			foreach (x; iota(1, BOARD_SIZE, 2))
			{
				foreach (y; iota(1, BOARD_SIZE, 2))
				{
					foreach (o; 1 .. 3)
					{

						/+
						 + limit to walls in the opponents path,
						 + or walls in their own path, but opposite orientation to block
						 +/
						if ((
						// Walls in my opponent's path
								b.walls_in_path[(b.my_turn + 1) % 2][linearize(x, y, o)]

								// walls that block the wall the opponent would place if I move
								 || opponent_move
								 && (
									// opponent plays vertical wall, blocking walls have same x
										opponent_move[2] == 1 && opponent_move[0] == x

										// check same place, opposite orientation
										 && (opponent_move[1] == y && o == 2
										
											// check blocking either end
											 || abs(opponent_move[1] - y) == 2 && o == 1)
										
										// opponent plays horizontal wall, blocking walls have same y
										 || (opponent_move[2] == 2 && opponent_move[1] == y

										// same place opposite orientation
										 && (opponent_move[0] == x && o == 1
										
											// blocking either end
											 || abs(opponent_move[0] - x) == 2 && o == 2))
										)
								
								/+
								 + check walls around me, in case I can block off my path
								 + (least essential, but I think I'll keep it)
								 +/
								 || abs(x - old_x) == 1 && abs(y - old_y) == 1

								// check walls around the opponent
								 || abs(x - my_x[(b.my_turn + 1) % 2]) == 1 && abs(y - my_y[(b.my_turn + 1) % 2]) == 1

								/+
								 + check all walls in the first case
								 + for obvious moves that we might otherwise miss
								 +/
								 || best.length == 1
							))
						{

							// some testing done twice, but faster to test than allocate
							if (b.is_legal_wall(x, y, o))
							{

								test_board = new Board(b);
								if (test_board.place_wall(x, y, o))
								{

									score = -negascout(
									test_board, 
										depth - 1, 
										-scout_val, 
										-alpha, 
										seconds, 
										sw, 
										null
									)[3];

									if ((
									alpha < score
										 && score < beta
										 && !first
									))
									{
										score = -negascout(
										test_board, 
											depth - 1, 
											-beta, 
											-alpha, 
											seconds, 
											sw, 
											null
										)[3];
									}

									if (score > alpha)
									{

										alpha = score;
										best_x = x;
										best_y = y;
										best_o = o;
									}

									if ((
									alpha >= beta
										 || sw.peek.seconds > seconds
									))
									{
										return [best_x, best_y, best_o, alpha];
									}

									scout_val = alpha + 1;
								}
							}
						}
					}
				}
			}

			return [best_x, best_y, best_o, alpha];
		}

		/// Evaluation function for minimax
		int evaluate(Board b)
		{
			int won;
			if (b.my_y[0] == 0)
			{
				won = -100;
			}
			if (b.my_y[1] == BOARD_SIZE - 1)
			{
				won = 100;
			}
			return (
			won
				 - b.my_walls[0]
				 + b.my_walls[1]
				 + 2 * b.path_lengths[0]
				 - 2 * b.path_lengths[1]
			);
		}

		/// Opening book, very basic
		int[] opening(int which)
		{

			// These openings are only for board of size 9
			if (BOARD_SIZE != 17)
			{
				return null;
			}

			// always move 2 ahead
			int[][] initial_array = [[8, 14, 0], [8, 2, 0], [8, 12, 0], [8, 4, 0]];

			if (my_turn < 4)
			{
				return initial_array[my_turn];
			}

			auto openings = [
			[[8, 10, 0], [8, 6, 0], [9, 11, 2], [9, 5, 2]], 
				[[9, 13, 2], [9, 3, 2], [8, 10, 0], [8, 6, 0]], 
				[[9, 15, 1], [9, 1, 1], [9, 13, 2], [9, 3, 2]], 
				[[8, 10, 0], [8, 6, 0], [7, 11, 2], [7, 5, 2]], 
				[[7, 13, 2], [7, 3, 2], [8, 10, 0], [8, 6, 0]], 
				[[7, 15, 1], [7, 1, 1], [7, 13, 2], [7, 3, 2]]
			];

			// Different openings, moves 4-8
			if (my_turn < 8)
			{
				return openings[which][my_turn - 4];
			}

			// We're past the end of the openings
			return null;
		}

		unittest
		{
			writeln("Starting opening() test");

			static if (BOARD_SIZE == 17)
			{

				Board b;
				 // make sure all moves are legal
				foreach (i; 1 .. 6)
				{

					b = new Board();
					assert(b.opening(i));
					assert(b.opening(i));
					assert(b.opening(i));
					assert(b.opening(i));
				}
			}
		}
	}
}

