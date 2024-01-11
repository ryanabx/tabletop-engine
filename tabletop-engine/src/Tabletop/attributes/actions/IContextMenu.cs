using Godot;

namespace Tabletop.Attributes.Actions;

public interface IContextMenu
{
	public PopupMenu ContextMenu
	{
		get;
		set;
	}
}