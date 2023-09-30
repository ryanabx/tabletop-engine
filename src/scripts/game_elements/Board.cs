
using System;
using Godot;

public partial class Board : Node2D
{
    public enum GameObjectType
    {
        FLAT, DECK, HAND, MAX
    };
    public enum InputModeType
    {
        CAMERA,
        SELECT
    };
    public enum TouchModeType
    {
        TAP,
        DRAG
    };
    public readonly string[] GAME_OBJECT_TYPE_STRING =
    {
        "flat", "deck", "hand"
    };
    // public TabletopGame Game = null;
    public Vector2 Size = Vector2.One;
    public int NumberOfPlayers;
    public int PlayerId;
    public InputModeType InputMode = InputModeType.SELECT;
    public TouchModeType TouchMode = TouchModeType.TAP; // TODO: Change this to set the global setting
    [Signal]
    public delegate void PropertySyncEventHandler();
    
}