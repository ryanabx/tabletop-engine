using System.Linq;
using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class GameObject : Node2D
{
    // Shareable properties
    public Vector2[] Shape =
    {
        new Vector2(-0.5f, -0.5f),
        new Vector2(-0.5f, 0.5f),
        new Vector2(0.5f, 0.5f),
        new Vector2(0.5f, -0.5f)
    };
    public Vector2 Size = Vector2.One;
    public virtual Array<string> ObjectTypes {get => new() { "GameObject"};}
    // Private variables
    protected Dictionary _propertyChanges = new();
    protected Board _board;
    public Board GameBoard
    {
        set
        {
            _board = value;
        }
        get
        {
            return _board;
        }
    }
    public int Authority
    {
        get {return GetMultiplayerAuthority();}
        set
        {
            if (IsInsideTree() && Multiplayer.GetUniqueId() == value && GetMultiplayerAuthority() != value)
            {
                Rpc(nameof(SetAuthority), value);
            }
            SetMultiplayerAuthority(value, true);
        }
    }
    public int Index
    {
        get {return GetIndex();}
        set
        {
            GetParent().MoveChild(this, value);
            AddToPropertyChanges(PropertyName.Index, value);
        }
    }
    [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    private void SetAuthority(int id)
    {
        Authority = id;
    }
    public override bool _Set(StringName property, Variant value)
    {
        AddToPropertyChanges(property, value);
        return false;
    }
    public void AddToPropertyChanges(StringName property, Variant value)
    {
        if (IsInsideTree() && GetShareableProperties().Contains(property) && IsMultiplayerAuthority())
        {
            _propertyChanges[property] = value;
        }
    }
    public virtual Array<StringName> GetShareableProperties()
    {
        return new Array<StringName>
        {
            PropertyName.Shape, PropertyName.Size, PropertyName.ObjectTypes, Node2D.PropertyName.Position, Node2D.PropertyName.Rotation
        };
    }
    [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    private void PropertyChangesSyncRpc(Dictionary<string, Variant> props)
    {
        foreach (string prop in props.Keys)
        {
            Set(prop, props[prop]);
        }
    }
    public void MoveSelfToTop()
    {
        Index = -1;
    }
    public void MoveSelfToBack()
    {
        Index = 0;
    }
    public Vector2[] GetExtents()
    {
        return GetMainTransform() * Shape;
    }
    public Vector2[] GetPolylineExtents()
    {
        Vector2[] extents = GetExtents();
        return extents.Concat(new Vector2[]{extents[0]}).ToArray();
    }
    public Transform2D GetMainTransform()
    {
        return new Transform2D(Rotation, Size, 0.0f, Position);
    }
    public Rect2 GetRectExtents()
    {
        return new Rect2(Position - Size / 2.0f, Size);
    }
    public Rect2 GetRect()
    {
        return new Rect2(-Size / 2.0f, Size);
    }
    public Transform2D GetGameObjectTransform()
    {
        return new Transform2D().Scaled(Size);
    }
    public override void _Ready()
    {
        _board.PropertySync += SyncProperties;
    }
    public void SyncProperties()
    {
        if (IsMultiplayerAuthority() && _propertyChanges.Count != 0)
        {
            Rpc(nameof(PropertyChangesSyncRpc), _propertyChanges);
        }
        _propertyChanges.Clear();
    }
    public void Erase(bool recursive = false, bool propagate = true)
    {
        Rpc(nameof(EraseRpc), recursive);
    }
    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    public virtual void EraseRpc(bool recursive)
    {
        QueueFree();
    }
}