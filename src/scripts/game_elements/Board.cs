using System.Linq;
using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class Board : Node2D
{
    public enum GameObjectType
    {
        FLAT, DECK, HAND, MAX
    };
    public enum InputModeType
    {
        CAMERA,
        SELECT
    };
    public enum TouchModeType
    {
        TAP,
        DRAG
    };
    public readonly string[] GAME_OBJECT_TYPE_STRING =
    {
        "flat", "deck", "hand"
    };
    public TabletopGame Game = null;
    public Vector2 Size = Vector2.One;
    public int NumberOfPlayers;
    public int PlayerId;
    public InputModeType InputMode = InputModeType.SELECT;
    public TouchModeType TouchMode = (TouchModeType)(int)Global.GetUserSetting("default_tap_mode");
    [Signal]
    public delegate void PropertySyncEventHandler();
    [Signal]
    public delegate void CreateContextMenuEventHandler(Selectable obj);
    public string Background
    {
        get {return Background;}
        set
        {
            Background = value;
            _backgroundSprite.Texture = GetImage(value);
            _backgroundSprite.Scale = Size / _backgroundSprite.Texture.GetSize();
        }
    }
    public BoardPlayer _boardPlayer;
    private Sprite2D _backgroundSprite;
    private Node2D _boardObjects;
    private Highlights _highlights;
    private Timer _syncTimer;
    private int _counter = 0;
    private Array<int> _readyPlayers = new Array<int>();
    public BoardPlayer GetPlayer()
    {
        return _boardPlayer;
    }
    public GameObject GetObject(string n)
    {
        return _boardObjects.GetNodeOrNull<GameObject>(n);
    }
    public Array<GameObject> GetAllObjects()
    {
        return new Array<GameObject>(_boardObjects.GetChildren().OfType<GameObject>());
    }
    public void ClearBoard()
    {
        foreach (GameObject obj in GetAllObjects())
        {
            obj.Authority = Multiplayer.GetUniqueId();
            obj.Erase(true);
        }
    }
    public void MovePiece(GameCollection from, GameCollection to, int fromInd = -1, int toInd = -1)
    {
        Piece piece;
        if (fromInd != -1)
        {
            piece = from.RemovePieceAt(fromInd);
        }
        else
        {
            piece = from.RemoveFromTop(Vector2.Zero);
        }
        if (toInd != -1)
        {
            to.AddPieceAt(piece, toInd);
        }
        else
        {
            to.AddPiece(piece);
        }
    }
    public GameObject GetObjectByIndex(int index)
    {
        return _boardObjects.GetChild<GameObject>(index);
    }
    public GameObject NewGameObject(GameObjectType type, Dictionary properties, int auth = -1)
    {
        GameObject c;
        if (!properties.ContainsKey("name"))
        {
            properties.Add("name", $"{Multiplayer.GetUniqueId()}_{GAME_OBJECT_TYPE_STRING[((int)type)]}_{_counter}");
            _counter++;
        }
        c = InstantiateByType(type);
        c.GameBoard = this;
        c.ObjectType = type;
        foreach (string prop in properties.Keys)
        {
            c.Set(prop, properties[prop]);
        }
        _boardObjects.AddChild(c);
        // RPC
        Rpc(MethodName.NewGameObjectRpc, new Array(new Variant[]{(int)type, properties}));
        c.SetMultiplayerAuthority((auth == -1) ? Multiplayer.GetUniqueId() : auth);
        return c;
    }
    public bool EraseObject(string objName, bool recursive = false)
    {
        GameObject obj = GetObject(objName);
        if (obj == null)
        {
            return false;
        }
        obj.Erase(recursive);
        return true;
    }
    public Texture2D GetImage(string path)
    {
        return Game.GetImage(path);
    }
    public override void _Ready()
    {
        base._Ready();
        _boardPlayer = GetNode<BoardPlayer>("BoardPlayer");
        _boardObjects = GetNode<Node2D>("BoardObjects");
        _highlights = GetNode<Highlights>("Highlights");
        _syncTimer = GetNode<Timer>("SyncTimer");
        _syncTimer.Timeout += SyncTimerTimeout;
        _boardPlayer.GameBoard = this;
        _highlights.GameBoard = this;
        SetPlayerID();
        _backgroundSprite = new Sprite2D();
        _backgroundSprite.ZIndex = -10;
        AddChild(_backgroundSprite);
        GetViewport().PhysicsObjectPicking = true;
        GetViewport().PhysicsObjectPickingSort = true;
        Game.GameBoard = this;
        Game.Initialize();
        Rpc(MethodName.IsReady, Multiplayer.GetUniqueId());
    }
    public override void _Process(double delta)
    {
        QueueRedraw();
        base._Process(delta);
    }
    public override void _Draw()
    {
        DrawRect(new Rect2(-Size / 2.0f, Size), Colors.White, false, 3);
        base._Draw();
    }
    [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    private void IsReady(int id)
    {
        if (Multiplayer.IsServer())
        {
            _readyPlayers.Add(id);
            if (_readyPlayers.Count == Multiplayer.GetPeers().Length + 1)
            {
                Game.GameStart();
                Rpc(MethodName.GameLoadFinished);
            }
        }
    }
    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    private void GameLoadFinished()
    {
        GetParent<BoardManager>().EmitSignal(BoardManager.SignalName.GameLoadFinished, this);
    }
    private GameObject InstantiateByType(GameObjectType type)
    {
        switch (type)
        {
            case GameObjectType.DECK:
                return new Deck();
            case GameObjectType.FLAT:
                return new Flat();
            case GameObjectType.HAND:
                return new Hand();
            default:
                return null;
        }
    }
    private void SetPlayerID()
    {
        Array<int> fullArray = new Array<int>(Multiplayer.GetPeers());
        fullArray.Add(Multiplayer.GetUniqueId());
        fullArray.Sort();
        PlayerId = fullArray.IndexOf(Multiplayer.GetUniqueId());
    }
    [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    private void NewGameObjectRpc(GameObjectType type, Dictionary properties)
    {
        NewGameObject(type, properties, Multiplayer.GetRemoteSenderId());
    }
    private void SyncTimerTimeout()
    {
        EmitSignal(SignalName.PropertySync);
    }
}