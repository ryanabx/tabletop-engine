using Godot;
namespace Tabletop.Attributes;

public interface IHasGeometry
{
	public Vector2[] Shape
	{
		get;
		set;
	}
}