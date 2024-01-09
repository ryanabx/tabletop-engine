using Godot;
using TabletopEngine.Tabletop.Objects;
namespace TabletopEngine.Tabletop.Attributes;

public interface IHasGeometry
{
	public Vector2[] Shape
	{
		get;
		set;
	}
}