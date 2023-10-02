using Godot;
using Godot.Collections;
public partial class Selectable : GameObject
{
    public bool LockState = false;
    public Vector2 GrabOffset = Vector2.Zero;
    public int Selected
    {
        get {return Selected;}
        set
        {
            // TODO: Implement
        }
    }
    public int Queued
    {
        get {return Queued;}
        set
        {
            // TODO: Implement
        }
    }
    private CollisionPolygon2D _collisionPolygon;
    private Area2D _area2d;
    public override void _Ready()
    {
        // Collision stuff
        _area2d = new Area2D();
        _area2d.Monitorable = false;
        _area2d.Monitoring = false;
        _area2d.InputPickable = true;
        _area2d.CollisionLayer = 1;
        AddChild(_area2d);
        _collisionPolygon = new CollisionPolygon2D();
        _collisionPolygon.Polygon = GetGameObjectTransform() * Shape;
        _area2d.AddChild(_collisionPolygon);
        base._Ready();
    }
    public override Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>(new string[]{"LockState", "Selected", "Queued"});
    }
}