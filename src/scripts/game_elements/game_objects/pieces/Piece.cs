using Godot;
using Godot.Collections;

public partial class Piece : Selectable
{
    public Array<string> Types = new Array<string>();
    public override void _Ready()
    {
        base._Ready();
    }
    public override Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>(new string[]{"Types"});
    }
    public Dictionary Serialize()
    {
        Dictionary dict = new Dictionary();
        dict["Shape"] = Shape;
        dict["Size"] = Size;
        dict["Types"] = Types;
        dict["ObjectType"] = (int)ObjectType;
        return dict;
    }
}