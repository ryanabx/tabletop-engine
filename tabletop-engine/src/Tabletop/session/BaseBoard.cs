using System.Collections.Generic;
using Godot;
using Tabletop.Objects;
namespace Tabletop.Session;

public abstract partial class BaseBoard : Node2D
{
	private Node2D _objs;
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
		_objs.AddChild(obj);
	}
	public void RemoveGmObject(string name)
	{
		if (_objs.GetNodeOrNull(name) != default)
		{
			_objs.RemoveChild(_objs.GetNode(name));
		}
	}
	public GmObject GetGmObject(string name)
	{
		return _objs.GetNodeOrNull<GmObject>(name);
	}
	public override void _Ready()
	{
		base._Ready();
		_objs = new()
		{
			Name = "GmObjects"
		};
		AddChild(_objs);
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