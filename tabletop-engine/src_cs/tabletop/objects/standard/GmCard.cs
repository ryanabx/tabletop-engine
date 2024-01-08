using Godot;
using TabletopEngine.Tabletop.Attributes;
namespace TabletopEngine.Tabletop.Objects.Standard;

public partial class GmCard : GmPiece, IFlippable
{
	private bool _orientation;
	public bool Orientation
	{
		get { return _orientation; }
		set { _orientation = value; }
	}
	public void Flip()
	{
		Orientation = !Orientation;
	}
}