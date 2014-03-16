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
		throw new Exception("Usage: ./quoridor {time for p1} {time for p2} [{move 1}...]\n Time of 0 for p1 or p2 indicates a human player");
	}

	if (!isNumeric(args[1]) || !isNumeric(args[2]))
	{
		throw new Exception("Length of time for p1 must be numeric");
	}

	int[2] times = [to!int(args[1]), to!int(args[2])];

	Board board = new Board();

	/+
	 + Initialize board with moves from initial command
	 +/
	foreach (move; args[3 .. $])
	{
		board.move(move);
	}

	board.print_board();
	
	string move;
	int winner;
	int turn;
	
	/+
	 + Until the game is over, read moves from the command line
	 +/
	while (true)
	{

		/+
		 + If player is human
		 +/
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
						board.print_board();
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

		/+
		 + If player is a computer
		 +/
		else
		{
			move = board.ai_move(times[turn]);
			if (move.length > 2 && move[2] == 'w')
			{

				board.print_board();
				writeln("Player ", turn + 1, " wins!");
				break;
			}
		}

		board.print_board();
		turn = (turn + 1) % 2;
	}
}

