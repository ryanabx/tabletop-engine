using Godot;
using TabletopEngine.Tabletop.Session;
namespace TabletopEngine.Examples;

public partial class PlayingCards : RefCounted, ITabletopConfig
{
	private Board _board;
	public Board GameBoard
	{
		get { return _board; }
		set { _board = value; }
	}
	
}