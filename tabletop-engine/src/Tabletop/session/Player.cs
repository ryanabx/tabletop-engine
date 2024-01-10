using Godot;
using Tabletop.Attributes;
namespace Tabletop.Session;

public partial class Player : Node2D
{
	private enum ControlScheme
	{
		KeyboardMouse,
		Controller,
		Touch
	}
	List<ISelectable> _selected;
}