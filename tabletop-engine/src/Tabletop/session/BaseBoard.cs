using System.Collections.Generic;
using Godot;
using Tabletop.Objects;
namespace Tabletop.Session;

public abstract partial class BaseBoard : Node2D
{
	public abstract Vector2 Size
	{
		get;
	}
		public abstract List<string> Actions
	{
		get;
	}
	public abstract void Reset();
	public abstract void InitClient();
	public abstract void InitServer();
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
	public override void _Ready()
	{
		base._Ready();
		if (Multiplayer.IsServer())
		{
			InitServer();
		}
		else
		{
			InitClient();
		}
	}
}