using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class GameCollection : Selectable
{
    public override Array<string> ObjectTypes { get => base.ObjectTypes + new Array<string> {"GameCollection"};}
    public Array<string> Types;
    public Array<Dictionary<StringName, Variant>> Inside = new();
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
        AddToPropertyChanges(PropertyName.Inside, Inside);
    }
    public void Shuffle()
    {
        Authority = Multiplayer.GetUniqueId();
        Inside.Shuffle();
        AddToPropertyChanges(PropertyName.Inside, Inside);
    }
    public virtual Piece DeserializePiece(Dictionary<StringName, Variant> dict)
    {
        dict[Node2D.PropertyName.Position] = Position;
        dict[Node2D.PropertyName.Rotation] = Rotation;
        return _board.NewGameObject(
            ((Array<string>)dict[GameObject.PropertyName.ObjectTypes])[^1],
            dict
        ) as Piece;
    }
    public override Array<StringName> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<StringName>
        {
            PropertyName.Types,
            PropertyName.Inside,
            PropertyName.FaceUp
        };
    }

    public void AddPieceAt(Piece piece, int index)
    {
        if (!GameBoard.Game.CanStack(piece, this)){return;}
        Authority = Multiplayer.GetUniqueId();
        piece.Authority = Multiplayer.GetUniqueId();

        Dictionary<StringName, Variant> pieceDict = piece.Serialize();
        piece.Erase();
        Inside.Insert(index, pieceDict);
        AddToPropertyChanges(PropertyName.Inside, Inside);
    }
    public void AddCollectionAt(GameCollection collection, int index)
    {
        if (!GameBoard.Game.CanStack(collection, this)){return;}
        if (collection is IFlippable fl && this is IFlippable fl2 && fl.GetOrientation() != fl2.GetOrientation())
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
        Dictionary<StringName, Variant> pieceDict = Inside[index];
        Inside.RemoveAt(index);
        AddToPropertyChanges(PropertyName.Inside, Inside);
        Piece piece = DeserializePiece(pieceDict);
        piece.Authority = Multiplayer.GetUniqueId();
        piece.Position = Position;
        piece.Rotation = Rotation;
        return piece;
    }
    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
    public override void EraseRpc(bool recursive)
    {
        if (!recursive && IsMultiplayerAuthority())
        {
            foreach (Dictionary<StringName, Variant> piece in Inside)
            {
                DeserializePiece(piece);
            }
        }
        base.EraseRpc(recursive);
    }
}