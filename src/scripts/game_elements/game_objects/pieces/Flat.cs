using Godot;
using Godot.Collections;
public partial class Flat : Piece, Flippable
{
    public enum ViewOverrideType
    {
        ALL, IF_SELECTED, IF_NOT_SELECTED, NONE
    }
    public ViewOverrideType ViewOverride = ViewOverrideType.NONE;
    public string ImageUp = "";
    public string ImageDown = "";
    private bool _faceUp = false;
    public bool FaceUp
    {
        get {return _faceUp;}
        set
        {
            _faceUp = value;
            AddToPropertyChanges(PropertyName.FaceUp, value);
        }
    }
    protected Sprite2D _sprite;
    public override Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>(new string[]{"ImageUp", "ImageDown", "FaceUp"});
    }
    protected void RefreshImage()
    {
        if (ImageUp == "" || ImageDown == "") {return;}
        if (_board == null || _board.Game == null || _board.GetImage(ImageUp) == null || _board.GetImage(ImageDown) == null || !IsInstanceValid(_sprite))
        {
            return;
        }
        bool ovr = false;
        switch (ViewOverride)
        {
            case ViewOverrideType.ALL:
                ovr = true;
                break;
            case ViewOverrideType.IF_SELECTED:
                ovr = (Selected == Multiplayer.GetUniqueId() || Queued == Multiplayer.GetUniqueId());
                break;
            case ViewOverrideType.IF_NOT_SELECTED:
                ovr = (!(Selected == Multiplayer.GetUniqueId() || Queued == Multiplayer.GetUniqueId()));
                break;
            default:
                break;
        }
        _sprite.Texture = (FaceUp || ovr) ? _board.GetImage(ImageUp) : _board.GetImage(ImageDown);
        _sprite.Scale = Size / _sprite.Texture.GetSize();
    }
    public void Flip()
    {
        FaceUp = !FaceUp;
    }
    public void SetOrientation(bool orientation)
    {
        FaceUp = orientation;
    }
    public override void _Process(double delta)
    {
        RefreshImage();
        base._Process(delta);
    }
    public override void _Ready()
    {
        _sprite = new Sprite2D();
        AddChild(_sprite);
        base._Ready();
    }
    public override Dictionary Serialize()
    {
        Dictionary dict = base.Serialize();
        dict["ImageUp"] = ImageUp;
        dict["ImageDown"] = ImageDown;
        dict["FaceUp"] = FaceUp;
        dict["ViewOverride"] = (int)ViewOverride;
        return dict;
    }
}