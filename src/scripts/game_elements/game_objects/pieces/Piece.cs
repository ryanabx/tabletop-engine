using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class Piece : Selectable
{
    public Array<string> Types = new();
    public override void _Ready()
    {
        base._Ready();
    }
    public override Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>(new string[]{"Types"});
    }
    public virtual Dictionary Serialize()
    {
        Dictionary dict = new()
        {
            ["Shape"] = Shape,
            ["Size"] = Size,
            ["Types"] = Types,
            ["ObjectType"] = (int)ObjectType
        };
        return dict;
    }
}