// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
//pragma solidity >=0.6.2 <0.7.0;

// Tools:
// In this assignment we will be programming in Ethereum with Solidity.
// You should be familiar with solidity due to the "cryptozombies" tutorials.
// You can use remix.ethereum.org to gain access to a Solidity programming environment,
// and install the metamask.io browser extension to access an ethereum testnet wallet.

// Project:

// Implement the Nim board game (the "misere" version -- if you move last, you lose).
// See https://en.wikipedia.org/wiki/Nim for details about the game, but in essence
// there are N piles (think array length N of uint256) and in each turn a player must
// take 1 or more items (player chooses) from only 1 pile.  If the pile is empty, of
// course the player cannot take items from it.  The last player to take items loses.
// Also in our version, if a player makes an illegal move, it loses.

// To implement this game, you need to create a contract that implements the interface
// "Nim" (see below).

// Nim.startMisere kicks things off.  It is given the addresses of 2 NimPlayer (contracts)
// and an initial board configuration (for example [1,2] would be 2 piles with 1 and 2 items in them).

// Your code must call the nextMove API alternately in each NimPlayer contract to receive
// that player's next move, ensure its legal, apply it, and see if the player lost.
// Player a gets to go first.
// If the move is illegal, or the player lost, call the appropriate Uxxx functions
// (e.g. Uwon, Ulost, UlostBadMove) functions for both players, and award the winner
// all the money sent into "startMisere" EXCEPT your 0.001 ether fee for hosting the game.

// I have supplied an example player.
// You should submit your solution to Gradescope's auto-tester.  The tests in
// Gradescope are representative of the final tests we will apply to your submission,
// but are not comprehensive.

// To submit to Gradescope, create a zip file with a single file named nim.sol in it (no subdirectories!).
// This is an example Makefile to do this on Linux, if your work is in a subdirectory called "submission":
// nim_solution.zip: submission/nim.sol
//	(cd submission; 7z a ../nim_solution.zip nim.sol)


// TESTING IS A CRITICAL PART OF THIS ASSIGNMENT.
// You must think about how the game can be exploited and write your own
// misbehaving players to attack your own Nim game!

// If you rely on the autograder to be your tests, you will waste a huge amount
// of your own time because the autograder takes a while to run.

// Leave your tests in your submitted nim.sol file either commented out or as
// separate contracts.  The auto-graded points are not the final grade.  The
// graders will look at the quality of your tests and code and may bump you
// up/down based on our assessment of it.

// Good luck! You've got this!


interface NimPlayer
{
    // Given a set of piles, return a pile number and a quantity of items to remove
    function nextMove(uint256[] calldata piles) external returns (uint, uint256);
    // Called if you win, with your winnings!
    function Uwon() external payable;
    // Called if you lost :-(
    function Ulost() external;
    // Called if you lost because you made an illegal move :-(
    function UlostBadMove() external;
}


interface Nim
{
    // fee is 0.001 ether, award the winner the rest
    function startMisere(NimPlayer a, NimPlayer b, uint256[] calldata piles) payable external;
}


contract NimBoard is Nim
{
    uint fee = 0.01 ether;
    uint256[] nimboard;
    bool bad_move = false;
    uint movescount;
    uint current_turn;
    event debug_board(uint256[] nimboard_val);
    event correctmovemsg(uint code);
    event wrongmovemsg(uint code);
    event wrongmovelog(uint index,uint number);

    function startMisere(NimPlayer a, NimPlayer b, uint256[] calldata piles) payable external override {
        require(msg.value >= fee);
        emit debug_board(piles);
        nimboard = piles;
        emit debug_board(nimboard);
        movescount = 0;
        current_turn = 0;

        while(MovesLeft() && bad_move == false)
        {
            if(current_turn == 0)
            {
                Move(a, b);
                current_turn = 1;
            }

            else if(current_turn == 1)
            {
                Move(b, a);
                current_turn = 0;
            }

            movescount++;
        }

        if(bad_move == false)
        {
            if(current_turn == 0)
            {
                a.Uwon{value: msg.value - fee}();
                b.Ulost;
            }

            else if(current_turn == 1)
            {
                b.Uwon{value: msg.value - fee}();
                a.Ulost;
            }
        }
    }


    function getMovesCount() external view returns(uint) {
        return movescount;
    }

    function getNimBoardState() external view returns(uint256[] memory) {
        return nimboard;
    }

    function MovesLeft() internal view returns(bool)
    {
        uint i = 0;
        while(i < nimboard.length)
        {
            if(nimboard[i] > 0)
            {
                return (true);
            }
            i++;
        }

        return (false);
    }

    function LegalMove(uint ind, uint256 num) internal returns(bool)
    {
        if(nimboard[ind] < num)
        {
            emit wrongmovemsg(0);
            return (false);
        }

        if(num <= 0)
        {
            emit wrongmovemsg(1);
            return (false);
        }

        if(ind >= nimboard.length)
        {
            emit wrongmovemsg(2);
            return (false);
        }

        emit correctmovemsg(0);
        return (true);
    }

    function Move(NimPlayer a, NimPlayer b) internal
    {
        uint num;
        uint ind;
        (ind, num) = a.nextMove(nimboard);

        if(LegalMove(ind, num) == false)
        {
            emit wrongmovelog(ind, num);
            a.UlostBadMove;
            bad_move = true;
            b.Uwon{value: msg.value - fee};
            return;
        }

        nimboard[ind] = nimboard[ind] - num;
        emit debug_board(nimboard);
    }

}


contract TrackingNimPlayer is NimPlayer
{
    uint losses=0;
    uint wins=0;
    uint faults=0;
    // Given a set of piles, return a pile number and a quantity of items to remove
    function nextMove(uint256[] calldata) virtual override external pure returns (uint, uint256)
    {
        return(0,1);
    }
    // Called if you win, with your winnings!
    function Uwon() override external payable
    {
        wins += 1;
    }
    // Called if you lost :-(
    function Ulost() override external
    {
        losses += 1;
    }
    // Called if you lost because you made an illegal move :-(
    function UlostBadMove() override external
    {
        faults += 1;
    }

    function results() external view returns(uint, uint, uint, uint)
    {
        return(wins, losses, faults, address(this).balance);
    }

    function reset() external {
        losses = 0;
        wins = 0;
        faults = 0;
    }

}

contract Boring1NimPlayer is TrackingNimPlayer
{
    // Given a set of piles, return a pile number and a quantity of items to remove
    function nextMove(uint256[] calldata piles) override external pure returns (uint, uint256)
    {
        for(uint i=0;i<piles.length; i++)
        {
            if (piles[i]>1) return (i, piles[i]-1);  // consumes all in a pile
        }
        for(uint i=0;i<piles.length; i++)
        {
            if (piles[i]>0) return (i, piles[i]);  // consumes all in a pile
        }
        return(0,0);
    }
}


/*
Test vectors:
deploy your contract NimBoard (we'll call it "C" here)
deploy 2 Boring1NimPlayers, A & B
In remix set the value to 0.002 ether and call
C.startMisere(A,B,[1,1])
A should have 1 win and a balance of 1000000000000000 (0.001 ether)
B should have 1 loss
Now try C.startMisere(A,B,[1,2])
Now A and B should both have 1 win and 1 loss (and B should have gained however many coins you funded the round with)
The above is a pain to click through by hand, except the first few times.
Maybe you could create a contract that tests your Nim contract?
*/