using Godot;
namespace Tabletop.Attributes.Properties;

public interface IGeometry
{
	public Vector2[] Shape
	{
		get;
		set;
	}
}