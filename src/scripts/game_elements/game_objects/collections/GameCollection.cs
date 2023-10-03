using Godot;
using Godot.Collections;

public partial class GameCollection : Selectable
{
    public Array<string> Types;
    public Array<Dictionary> Inside = new();
    public bool FaceUp = false;
    public virtual void AddPiece(Piece piece, bool back = false)
    {
        if (back) {AddPieceAt(piece, 0);}
        else {AddPieceAt(piece, Inside.Count);}
    }
    public virtual void AddCollection(GameCollection collection, bool back = false)
    {
        if (back) {AddCollectionAt(collection, 0);}
        else {AddCollectionAt(collection, Inside.Count);}
    }
    public virtual Piece RemoveFromTop(Vector2 position)
    {
        if (Inside.Count == 0)
        {
            GD.Print("Inside size is 0");
            return null;
        }
        return RemovePieceAt(Inside.Count - 1);
    }
    public virtual void ClearInside()
    {
        Authority = Multiplayer.GetUniqueId();
        Inside.Clear();
        AddToPropertyChanges("Inside", Inside);
    }
    public void Shuffle()
    {
        Authority = Multiplayer.GetUniqueId();
        Inside.Shuffle();
        AddToPropertyChanges(PropertyName.Inside, Inside);
    }
    public virtual Piece DeserializePiece(Dictionary dict)
    {
        dict["position"] = Position;
        dict["rotation"] = Rotation;
        return _board.NewGameObject(
            (Board.GameObjectType)(int)dict["ObjectType"],
            dict
        ) as Piece;
    }
    public override Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>(new string[]{"Inside", "FaceUp"});
    }

    public void AddPieceAt(Piece piece, int index)
    {
        if (!GameBoard.Game.CanStack(piece, this)){return;}
        Authority = Multiplayer.GetUniqueId();
        piece.Authority = Multiplayer.GetUniqueId();

        Dictionary pieceDict = piece.Serialize();
        piece.Erase();
        Inside.Insert(index, pieceDict);
        AddToPropertyChanges(PropertyName.Inside, Inside);
    }
    public void AddCollectionAt(GameCollection collection, int index)
    {
        if (!GameBoard.Game.CanStack(collection, this)){return;}
        if (collection is Flippable fl && this is Flippable fl2 && fl.GetOrientation() != fl2.GetOrientation())
        {
            fl.Flip();
        }
        if (index == Inside.Count)
        {
            Inside.AddRange(collection.Inside);
        }
        else
        {
            Inside = Inside[..index] + collection.Inside + Inside[index..];
        }
        AddToPropertyChanges(PropertyName.Inside, Inside);
        collection.ClearInside();
    }
    public Piece RemovePieceAt(int index)
    {
        if (!GameBoard.Game.CanTakePieceOff(this)){return default;}
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