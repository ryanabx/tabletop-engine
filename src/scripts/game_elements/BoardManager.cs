using System.Linq;
using System.Threading.Tasks;
using Godot;
using Godot.Collections;
public partial class BoardManager : Node
{
    public Board GameBoard;
    private const int MTU = 1476;
    private int _peersReady = 0;
    private Array<byte> _configBytes = new Array<byte>();
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
        _configBytes.AddRange(Global.LoadThisGame);

        int curr = 0;

        while (true)
        {
            byte[] slice = _configBytes.Slice(curr, MTU).ToArray<byte>();
            Rpc(MethodName.ReceiveConfigPart, slice, (curr + MTU >= _configBytes.Count));
            if (curr + MTU >= _configBytes.Count)
            {
                SpawnBoard();
                break;
            }
            curr += MTU;
        }
    }
    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    public void ReceiveConfigPart(byte[] part, bool final)
    {
        _configBytes.AddRange(part);
        if (final)
        {
            SpawnBoard();
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
    public void SpawnBoard()
    {
        GD.Print("Spawning board!");
        TabletopGame game = TabletopGame.ImportConfig(_configBytes.ToArray());
        Board newBoard = GD.Load<PackedScene>("res://src/scenes/game_elements/Board.cs").Instantiate<Board>();
        newBoard.Game = game;
        newBoard.Name = game.Name;
        AddChild(newBoard);
        GameBoard = newBoard;
    }
    public override async void _Ready()
    {
        if (Multiplayer.IsServer()) // Server code
        {
            MakeTabletop();
        }
        else // Client code
        {
            await ToSignal(GetTree().CreateTimer(0.2), SceneTreeTimer.SignalName.Timeout);
            GD.Print("Client notifying ready");
            Rpc(MethodName.NotifyReady, Multiplayer.GetUniqueId());
        }
    }
    public void SaveConfig()
    {
        // TODO: Implement this
    }
}