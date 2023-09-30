using System.Collections.Generic;
using Godot;
using Godot.Collections;
using Microsoft.VisualBasic;

public partial class GameCollection : Selectable
{
    public Array<string> Types;
    public Array<Dictionary> Inside = new Array<Dictionary>();
    public bool FaceUp = false;
    public void AddPiece(Piece piece, bool back = false)
    {
        if (back) {AddPieceAt(piece, 0);}
        else {AddPieceAt(piece, Inside.Count);}
    }
    public void AddCollection(Collection collection, bool back = false)
    {
        if (back) {AddCollectionAt(collection, 0);}
        else {AddCollectionAt(collection, Inside.Count);}
    }
    public Piece RemoveFromTop(Vector2 position)
    {
        if (Inside.Count == 0)
        {
            GD.Print("Inside size is 0");
            return null;
        }
        return RemovePieceAt(Inside.Count - 1);
    }
    public void Shuffle()
    {
        Authority = Multiplayer.GetUniqueId();
        Inside.Shuffle();
        AddToPropertyChanges(PropertyName.Inside, Inside);
    }
    protected Dictionary SerializePiece(Piece piece)
    {
        return piece.Serialize();
    }
    protected Piece DeserializePiece(Dictionary dict)
    {
        dict["position"] = Position;
        dict["rotation"] = Rotation;
        return _board.NewGameObject(
            (Board.GameObjectType)(int)dict["ObjectType"],
            dict
        ) as Piece;
    }
    new public Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>(new string[]{"Inside", "FaceUp"});
    }

    protected void AddPieceAt(Piece piece, int index)
    {
        // TODO: Add can_stack check
        Authority = Multiplayer.GetUniqueId();
        piece.Authority = Multiplayer.GetUniqueId();

        Dictionary pieceDict = SerializePiece(piece);
        piece.Erase();
        Inside.Insert(index, pieceDict);
        AddToPropertyChanges(PropertyName.Inside, Inside);
    }
    protected void AddCollectionAt(Collection collection, int index)
    {
        // TODO: Implement
    }
    protected Piece RemovePieceAt(int index)
    {
        // TODO: Add board.game.can_take_piece_off check
        Authority = Multiplayer.GetUniqueId();
        Dictionary pieceDict = Inside[index];
        Inside.RemoveAt(index);
        AddToPropertyChanges(PropertyName.Inside, Inside);
        Piece piece = DeserializePiece(pieceDict);
        piece.Authority = Multiplayer.GetUniqueId();
        piece.Position = Position;
        piece.Rotation = Rotation;
        return piece;
    }
}