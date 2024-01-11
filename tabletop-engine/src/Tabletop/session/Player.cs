using Godot;
using Tabletop.Attributes.Actions;
using System.Collections.Generic;
namespace Tabletop.Session;

public partial class Player : Node2D
{
	private enum ControlScheme
	{
		KeyboardMouse,
		Controller,
		Touch
	}
	private List<ISelectable> _selected;
	private BaseBoard _board;
	public BaseBoard Board
	{
		get { return _board; }
		set { _board = value; }
	}
}