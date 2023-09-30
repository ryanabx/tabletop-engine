using Godot;
using Godot.Collections;
public partial class BoardManager : Node
{
    public Board GameBoard;
    private const int MTU = 1476;
    [Signal]
    public delegate void GameLoadFinishedEventHandler(Board board);
    [Signal]
    public delegate void PeerReadyEventHandler(int id);
    private void NotifyReady(int id)
    {
        GD.Print($"{Multiplayer.GetUniqueId()} received ready from {id}");
        if (Multiplayer.IsServer())
        {
            EmitSignal(SignalName.PeerReady, id);
        }
    }
    public override void _Ready()
    {
        if (Multiplayer.IsServer())
        {
            // TODO: Continue here!
        }
    }
}