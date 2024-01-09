using Godot;
using Godot.Collections;
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
	private ISelectable.SelectState _selected;
	public ISelectable.SelectState Selected
	{
		get { return _selected; }
		set { _selected = value; } // TODO: Add extra nuance to object being selected
	}

	public Dictionary<string, Variant> SendStateDeltas()
	{
		return []; // TODO: Send state deltas!
	}
	public void ProcessStateDeltas(Dictionary<string, Variant> deltas)
	{
		// TODO: Implement this!
	}
}