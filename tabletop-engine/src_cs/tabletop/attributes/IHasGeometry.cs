using Godot;
namespace TabletopEngine.Tabletop.Attributes;

public interface IHasGeometry
{
	public Vector2[] Shape
	{
		get;
	}
}