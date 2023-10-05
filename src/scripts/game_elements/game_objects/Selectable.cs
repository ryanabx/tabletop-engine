using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class Selectable : GameObject
{
    public bool LockState = false;
    public Vector2 GrabOffset = Vector2.Zero;
    private int _selected = 0;
    private int _queued = 0;
    public override Array<string> ObjectTypes { get => base.ObjectTypes + new Array<string> {"Selectable"};}
    public int Selected
    {
        get {return _selected;}
        set
        {
            _selected = value;
            _area2d.CollisionLayer = (value != 0) ? 2u : 1u;
            AddToPropertyChanges(PropertyName.Selected, _selected);
        }
    }
    public int Queued
    {
        get {return _queued;}
        set
        {
            _queued = value;
            AddToPropertyChanges(PropertyName.Queued, _queued);
        }
    }
    protected CollisionPolygon2D _collisionPolygon;
    private Area2D _area2d;
    public override void _Ready()
    {
        // Collision stuff
        _area2d = new Area2D
        {
            Monitorable = false,
            Monitoring = false,
            InputPickable = true,
            CollisionLayer = 1
        };
        AddChild(_area2d);
        _collisionPolygon = new CollisionPolygon2D();
        UpdateCollision();
        _area2d.AddChild(_collisionPolygon);
        base._Ready();
    }
    public void UpdateCollision()
    {
        _collisionPolygon.Polygon = GetGameObjectTransform() * Shape;
    }
    public override Array<StringName> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<StringName>
        {
            PropertyName.LockState, PropertyName.Queued, PropertyName.Selected
        };
    }
    public virtual void OnSelect(InputEventScreenTouch touch)
    {
        if (Selected == 0 && Queued == 0)
        {
            GameBoard.GetPlayer().QueueSelectObject(this);
        }
    }
    public virtual void OnDeselect(InputEventScreenTouch touch)
    {
        GameBoard.GetPlayer().StackSelectionToItem(this);
    }
}