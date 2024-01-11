using Tabletop.Attributes.Properties;
namespace Tabletop.Attributes.Actions;

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