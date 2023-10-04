using System;
using Godot;
namespace TabletopEngine;
public partial class ContextMenu : PopupMenu
{
    public Selectable Target = default;
    private Board _board = default;
    public override void _Ready()
    {
        Hide();
        GetTree().Root.GetNode<BoardManager>("BoardManager").GameLoadFinished += GameLoadFinished;
    }
    private void GameLoadFinished(Board board)
    {
        _board = board;
        _board.CreateContextMenu += OnMenuCreated;
    }
    private void OnMenuCreated(Selectable target)
    {
        ResetMenu();
        Target = target;
        if (target is Piece pc)
        {
            InitPieceMenu();
        }
        else if (target is GameCollection gc)
        {
            InitCollectionMenu();
        }
        ResetSize();
        Popup();
    }
    private void ResetMenu()
    {
        Position = Vector2I.Zero;
        // Disconnect previously connected signals
        IdPressed -= OnClickedFromCollection;
        IdPressed -= OnClickedFromPiece;
    }

    private void InitPieceMenu()
    {

    }
    private void InitCollectionMenu()
    {

    }
    private void OnClickedFromPiece(long id)
    {
        switch (id)
        {
            case 0:
                ((IFlippable)Target).Flip();
                break;
            case 2:
                Target.MoveSelfToTop();
                break;
            case 3:
                Target.MoveSelfToBack();
                break;
        }
    }
    private void OnClickedFromCollection(long id)
    {
        switch (id)
        {

        }
    }
}