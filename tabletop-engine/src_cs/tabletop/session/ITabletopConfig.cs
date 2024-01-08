namespace TabletopEngine.Tabletop.Session;

public interface ITabletopConfig
{
	public Board GameBoard
	{
		get;
		set;
	}
	public abstract void InitClient();
	public abstract void InitServer();


}