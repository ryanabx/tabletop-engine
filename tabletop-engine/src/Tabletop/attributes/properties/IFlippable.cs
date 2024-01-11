namespace Tabletop.Attributes.Properties;

public interface IFlippable
{
	public bool Orientation
	{
		set;
		get;
	}
	public abstract void Flip();
}