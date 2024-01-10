using System.Collections.Generic;
using Godot;
using TabletopEngine.Tabletop.Attributes;
namespace TabletopEngine.Tabletop.Session;

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