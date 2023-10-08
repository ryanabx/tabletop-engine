// Tabletop Engine API
// Copyright Ryanabx 2023
using Godot.Collections;
using Godot;
using System.Linq;
using System.Collections.Generic;

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
        return new(((Array<GodotObject>)_board.Call("GetAllObjects")).Select(
            value => new GameObject(value)
        ).ToList());
    }
    public void ClearBoard()
    {
        _board.Call("ClearBoard");
    }
    public void MovePiece()
    {
        _board.Call("MovePiece", );
    }

    public abstract void DoThis()
    {

    }

    public abstract void AlsoThis()
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