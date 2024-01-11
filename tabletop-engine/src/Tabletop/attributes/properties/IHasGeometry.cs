using Godot;
namespace Tabletop.Attributes.Properties;

public interface IHasGeometry
{
	public Vector2[] Shape
	{
		get;
		set;
	}
}