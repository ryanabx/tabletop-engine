using Godot;
using TabletopEngine.Tabletop.Session;

public partial class Game : RefCounted, ITabletopConfig
{
	private Board _board;
	public Board GameBoard
	{
		get { return _board; }
		set { _board = value; }
	}
	
}