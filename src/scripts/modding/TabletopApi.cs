// Tabletop Engine API
// Copyright Ryanabx 2023
using System.Collections.Generic;
using Godot;
namespace TabletopApi;
public class Board
{
    private GodotObject _board;
    // Properties
    public Vector2 Size
    {
        get => (Vector2)_board.Get("Size");
        set => _board.Set("Size", value);
    }
    public int NumberOfPlayers
    {
        get => (int)_board.Get("NumberOfPlayers");
    }
    public int PlayerId
    {
        get => (int)_board.Get("PlayerId");
    }
    public string Background
    {
        set => _board.Set("Background", value);
    }
    // Methods
    public GameObject GetObject(string n)
    {
        return new GameObject((GodotObject)_board.Call("GetObject", n));
    }
    public List<GameObject> GetAllObjects()
    {
        
    }

}

public class GameObject
{
    private GodotObject _o;
    public GameObject(GodotObject o)
    {
        _o = o;
    }
}