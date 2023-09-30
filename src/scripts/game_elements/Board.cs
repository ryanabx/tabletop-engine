using System;
using System.Linq;
using Godot;

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
    // public TabletopGame Game = null;
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
    public Godot.Collections.Array<GameObject> GetAllObjects()
    {
        return new Godot.Collections.Array<GameObject>(_boardObjects.GetChildren());
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
        
    }
}