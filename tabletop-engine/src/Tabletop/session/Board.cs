using Godot;
using Tabletop.Objects;
namespace Tabletop.Session;

public partial class Board : Node2D
{
	private Vector2 _size;
	public Vector2 Size
	{
		get { return _size; }
		set { _size = value; }
	}
	public void AddGmObject(GmObject obj, string name)
	{
		obj.Name = name;
		AddChild(obj);
	}
	public void RemoveGmObject(string name)
	{
		if (GetNodeOrNull(name) != null)
		{
			RemoveChild(GetNode(name));
		}
	}
}