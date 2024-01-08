using Godot;
using TabletopEngine.Tabletop.Attributes;
namespace TabletopEngine.Tabletop.Objects.Standard;

public partial class GmPiece : GmObject, ISelectable, ISyncable
{
	private Vector2[] _shape;
	public Vector2[] Shape
	{
		get { return _shape; }
		set { _shape = value; }
	}
	private bool _selected;
	public bool Selected
	{
		get { return _selected; }
		set { _selected = value; } // TODO: Add extra nuance to object being selected
	}
}