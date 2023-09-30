using Godot;
using Godot.Collections;

public partial class Piece : Selectable
{
    public Array<string> Types = new Array<string>();
    public override void _Ready()
    {
        base._Ready();
    }
    new public Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>(new string[]{"Types"});
    }
}