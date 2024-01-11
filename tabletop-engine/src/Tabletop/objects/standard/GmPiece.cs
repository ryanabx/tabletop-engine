using Godot;
using Godot.Collections;
using Tabletop.Attributes.Properties;
using Tabletop.Attributes.Actions;
namespace Tabletop.Objects.Standard;

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
	public Dictionary<string, Variant> DeltasToDict()
	{
		return []; // TODO: Send state deltas!
	}
	public Dictionary<string, Variant> DataToDict()
	{
		return []; // TODO: Send entire state dictionary!
	}
	public void PopulateFromDict(Dictionary<string, Variant> deltas)
	{
		// TODO: Implement this!
	}
}