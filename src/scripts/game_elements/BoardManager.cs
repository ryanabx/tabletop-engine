using Godot;
using Godot.Collections;
public partial class BoardManager : Node
{
    public Board GameBoard;
    private const int MTU = 1476;
    [Signal]
    public delegate void GameLoadFinishedEventHandler(Board board);
    
}