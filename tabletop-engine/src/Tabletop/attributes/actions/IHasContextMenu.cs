using Godot;

namespace Tabletop.Attributes.Actions;

public interface IHasContextMenu
{
	public PopupMenu ContextMenu
	{
		get;
		set;
	}
}