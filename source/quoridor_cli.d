import std.stdio : writeln;
/++
 + A command line interface for the quoridor ai in board.d
 + author: Peter Massey-Plantinga
 + date: 3-3-14
 +/

import board;
import std.stdio;
import std.string;
import std.conv;

void main(string[] args)
{

	if (args.length < 3)
	{
		writeln("Usage: ./quoridor {seconds for p1} {seconds for p2} [{move 1}...]");
		writeln("Time of 0 for p1 or p2 indicates a human player");
		return;
	}

	if (!isNumeric(args[1]))
	{
		writeln("Length of time for p1 must be numeric");
		return;
	}

	if (!isNumeric(args[2]))
	{
		writeln("Length of time for p2 must be numeric");
		return;
	}

	int[2] times = [to!int(args[1]), to!int(args[2])];

	Board board = new Board();

	// Initialize board with moves from initial command
	foreach (move; args[3 .. $])
	{
		board.move(move);
	}

	print_board(board);
	
	string move;
	int winner;
	int turn;
	
	// Until the game is over, read moves from the command line
	while (true)
	{

		// If player is human
		if (times[turn] == 0)
		{

			move = strip(readln());
			if (move == null)
			{
				break;
			}

			else if (move == "u")
			{
				board.undo(2);
				turn = (turn + 1) % 2;
			}

			else
			{
				try
				{
					winner = board.move(move);
					if (winner)
					{
						print_board(board);
						writeln("Player ", winner, " wins!");
						break;
					}
				}

				catch (Exception e)
				{
					writeln("Illegal move");
					continue;
				}
			}
		}

		// If player is a computer
		else
		{
			move = board.ai_move(times[turn]);
			if (move.length > 2 && move[2] == 'w')
			{

				print_board(board);
				writeln("Player ", turn + 1, " wins!");
				break;
			}
		}

		print_board(board);
		turn = (turn + 1) % 2;
	}
}

/// Prints the board nicely
void print_board(ref Board b)
{
	write("\n");
	
	// Draw the walls of player 2
	foreach (j; 0 .. 2)
	{
		foreach (i; 0 .. b.wall_count(1))
		{
			write(" |  ");
		}
		write("\n");
	}

	// Draw the board header
	write("\n   ");
	foreach (c; 'a' .. 'j')
	{
		write("   " ~ c);
	}
	write("\n   ");
	foreach (i; 0 .. b.board_size() / 2 + 1)
	{
		write("+---");
	}
	writeln("+");
	
	// Draw the board with low y at the bottom
	foreach (i; 0 .. b.board_size())
	{
		if (i % 2 == 0)
		{
			string number = format("%s", i / 2 + 1);

			// append a space to shorter numbers so formatting looks nice
			if (number.length == 1)
			{
				number ~= " ";
			}
			write(number, " |");
		}
		else
		{
			write("   +");
		}

		foreach (j; 0 .. b.board_size())
		{
			// If we're at a wall location
			if (j % 2 == 1)
			{
				if (b.board_value(j, i) == 3)
				{
					write("#");
				}
				else
				{
					write("|");
				}
			}

			// Even rows have pieces
			else if (i % 2 == 0)
			{
				// Write a piece if one exists here
				if (b.board_value(j, i) != 0)
				{
					write(" ", b.board_value(j, i), " ");
				}
				else
				{
					write("   ");
				}
			}

			// Odd rows have walls
			else
			{
				if (b.board_value(j, i) == 3)
				{
					write("###");
				}
				else
				{
					write("---");
				}
			}
		}

		if (i % 2 == 0)
		{
			writeln("|");
		}
		else
		{
			writeln("+");
		}
	}

	write("   ");
	foreach (i; 0 .. b.board_size() / 2 + 1)
	{
		write("+---");
	}
	writeln("+\n");
	
	// Draw each player's walls
	foreach (j; 0 .. 2)
	{
		foreach (i; 0 .. b.wall_count(0))
		{
			write(" |  ");
		}
		write("\n");
	}
	write("\n");
}


