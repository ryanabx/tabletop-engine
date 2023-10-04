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
    public override Array<StringName> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<StringName>
        {
            PropertyName.Types
        };
    }
    public virtual Dictionary<StringName, Variant> Serialize()
    {
        Dictionary<StringName, Variant> dict = new()
        {
            [GameObject.PropertyName.Shape] = Shape,
            [GameObject.PropertyName.Size] = Size,
            [PropertyName.Types] = Types,
            [GameObject.PropertyName.ObjectType] = (int)ObjectType
        };
        return dict;
    }
}