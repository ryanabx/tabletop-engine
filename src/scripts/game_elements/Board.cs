using System.Linq;
using Godot;
using Godot.Collections;

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
    public GodotObject Game = null;
    public Vector2 Size = Vector2.One;
    public int NumberOfPlayers;
    public int PlayerId;
    public InputModeType InputMode = InputModeType.SELECT;
    public TouchModeType TouchMode = TouchModeType.TAP; // TODO: Change this to set the global setting
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
    private Sprite2D _backgroundSprite;
    public BoardPlayer _boardPlayer;
    private Node2D _boardObjects;
    private Highlights _highlights;
    private int _counter = 0;
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
        if (Game == null)
        {
            return null;
        }
        Dictionary images = (Dictionary)Game.Call("get_images");
        if (images == null)
        {
            return null;
        }
        else if (!images.ContainsKey(path))
        {
            return null;
        }
        return (Texture2D)images[path];
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
    [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    private void NewGameObjectRpc(GameObjectType type, Dictionary properties)
    {
        NewGameObject(type, properties, Multiplayer.GetRemoteSenderId());
    }
}