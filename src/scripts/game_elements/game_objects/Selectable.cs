using Godot;
using Godot.Collections;
public partial class Selectable : GameObject
{
    public bool LockState = false;
    public Vector2 GrabOffset = Vector2.Zero;
    private int _selected = 0;
    private int _queued = 0;
    public int Selected
    {
        get {return _selected;}
        set
        {
            _selected = value;
            _area2d.CollisionLayer = (value != 0) ? 2u : 1u;
            AddToPropertyChanges("Selected", _selected);
        }
    }
    public int Queued
    {
        get {return _queued;}
        set
        {
            _queued = value;
            AddToPropertyChanges("Queued", _queued);
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
    public override Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>(new string[]{"LockState", "Selected", "Queued"});
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