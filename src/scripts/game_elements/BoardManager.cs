using System.Threading.Tasks;
using Godot;
using Godot.Collections;
public partial class BoardManager : Node
{
    public Board GameBoard;
    private const int MTU = 1476;
    private int _peersReady = 0;
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
    public async void MakeTabletop()
    {
        GD.Print("Waiting for peers to be ready...");
        while (_peersReady != Multiplayer.GetPeers().Length)
        {
            int id = (int)(await ToSignal(this, SignalName.PeerReady))[0];
            GD.Print($"Peer {id} is ready!");
            _peersReady++;
        }
        await LoadGameConfig();
    }
    public async Task LoadGameConfig()
    {
        GD.Print("Loading Game Config");
        await RemoveTabletop();
        if (!Multiplayer.IsServer())
        {
            return;
        }
    }
    public async Task RemoveTabletop()
    {
        if (GameBoard != null)
        {
            GameBoard.QueueFree();
            await ToSignal(GameBoard, Board.SignalName.TreeExited);
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