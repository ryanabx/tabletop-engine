using Godot;
using Godot.Collections;
public partial class Flat : Piece
{
    public enum ViewOverrideType
    {
        ALL, IF_SELECTED, IF_NOT_SELECTED, NONE
    }
    public ViewOverrideType ViewOverride = ViewOverrideType.NONE;
    public string ImageUp = "";
    public string ImageDown = "";
    public bool FaceUp
    {
        get {return FaceUp;}
        set
        {
            FaceUp = value;
            AddToPropertyChanges(PropertyName.FaceUp, value);
        }
    }
    protected Sprite2D _sprite;
    new public Array<string> GetShareableProperties()
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
    }
}