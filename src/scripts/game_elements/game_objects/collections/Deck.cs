using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class Deck : GameCollection, IFlippable
{
    public bool Permanent = false;
    private Sprite2D _sprite;
    private Label _count;
    public override void AddPiece(Piece piece, bool back = false)
    {
        if (!GameBoard.Game.CanStack(piece, this)) {return;}
        base.AddPiece(piece, back);
    }
    public override Piece RemoveFromTop(Vector2 position)
    {
        Piece piece = base.RemoveFromTop(position);
        if (Inside.Count == 0 && !Permanent)
        {
            Erase(false);
        }
        return piece;
    }
    public void Flip()
    {
        Authority = Multiplayer.GetUniqueId();
        FaceUp = !FaceUp;
        Inside.Reverse();
        AddToPropertyChanges("Inside", Inside);
    }
    public void SetOrientation(bool orientation)
    {
        FaceUp = orientation;
    }
    public bool GetOrientation()
    {
        return FaceUp;
    }
    public override Array<StringName> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<StringName>
        {
            PropertyName.Permanent
        };
    }
    public override void _Ready()
    {
        InitChildren();
        base._Ready();
    }
    private void InitChildren()
    {
        _sprite = new Sprite2D();
        AddChild(_sprite);
        _count = new Label{ZIndex = 1, Scale = new Vector2(0.40f, 0.40f)};
        _count.AddThemeConstantOverride("outline_size", 16);
        _count.AddThemeColorOverride("font_outline_color", Colors.Black);
        AddChild(_count);
    }
    public override void _Process(double delta)
    {
        _count.Position = (GetGameObjectTransform() * Shape)[0];
        _count.Text = $"x{Inside.Count}";
        _count.ResetSize();
        QueueRedraw();
        if (Inside.Count == 0)
        {
            _sprite.Texture = default;
            return;
        }
        Dictionary<StringName, Variant> topPc = Inside[^1];
        if ((Vector2)topPc["Size"] != Size)
        {
            Size = (Vector2)topPc["Size"];
            UpdateCollision();
            _sprite.Texture = GameBoard.GetImage(FaceUp ? (string)topPc["ImageUp"] : (string)topPc["ImageDown"]);
            _sprite.Scale = Size / _sprite.Texture.GetSize();
        }
    }
    public override void _Draw()
    {
        DrawMultiline(_collisionPolygon.Polygon, Colors.White * new Color(1.0f, 1.0f, 1.0f, 0.3f), 2.0f);
    }
    public override void ClearInside()
    {
        base.ClearInside();
        if (!Permanent)
        {
            Erase();
        }
    }
    public override Piece DeserializePiece(Dictionary<StringName, Variant> dict)
    {
        dict[PropertyName.FaceUp] = FaceUp;
        return base.DeserializePiece(dict);
    }
}