using TabletopEngine.Tabletop.Objects;

namespace TabletopEngine.Tabletop.Attributes;

public interface ISelectable : IHasGeometry
{
	public enum SelectState
	{
		None,
		Main,
		Alt
	}
	public SelectState Selected
	{
		set;
		get;
	}
}