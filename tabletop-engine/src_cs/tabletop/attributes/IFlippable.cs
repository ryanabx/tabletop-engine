using TabletopEngine.Tabletop.Objects;

namespace TabletopEngine.Tabletop.Attributes;

public interface IFlippable
{
	public bool Orientation
	{
		set;
		get;
	}
	public abstract void Flip();
}