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
        Clear();
        Position = (Vector2I)GetViewport().GetMousePosition();
    }
    private void InitPieceMenu()
    {
        if (Target is IFlippable)
        {
            AddItem("Flip piece", 0);
        }
        IdPressed += OnClickedFromCollection;
        PopupMenu orderingMenu = new();
        orderingMenu.AddItem("Go to front", 3);
        orderingMenu.AddItem("Send to back", 4);
        orderingMenu.Name = "ordering";
        AddChild(orderingMenu);
        orderingMenu.IdPressed += OnClickedFromCollection;
    }
    private void InitCollectionMenu()
    {
        GameCollection targetCollection = (GameCollection)Target;
        AddItem("Shuffle", 8);
        IdPressed += OnClickedFromCollection;
        if (!targetCollection.LockState && targetCollection is IFlippable)
        {
            PopupMenu orientationMenu = new();
            orientationMenu.AddItem("Face up", 5);
            orientationMenu.AddItem("Face down", 6);
            orientationMenu.AddItem("Flip", 1);
            orientationMenu.Name = "orientation";
            AddChild(orientationMenu);
            AddSubmenuItem("Set Orientation", "orientation", 7);
            orientationMenu.IdPressed += OnClickedFromCollection;
        }
        PopupMenu orderingMenu = new();
        orderingMenu.AddItem("Go to front", 3);
        orderingMenu.AddItem("Send to back", 4);
        orderingMenu.Name = "ordering";
        AddChild(orderingMenu);
        orderingMenu.IdPressed += OnClickedFromCollection;
    }
    private void OnClickedFromPiece(long id)
    {
        switch (id)
        {
            case 0:
                ((IFlippable)Target).Flip();
                break;
            case 3:
                Target.MoveSelfToTop();
                break;
            case 4:
                Target.MoveSelfToBack();
                break;
        }
    }
    private void OnClickedFromCollection(long id)
    {
        GameCollection targetCollection = (GameCollection)Target;
        switch (id)
        {
            case 1:
                if (!(targetCollection.LockState) && targetCollection is IFlippable flp)
                {
                    flp.Flip();
                }
                break;
            case 3:
                targetCollection.MoveSelfToTop();
                break;
            case 4:
                targetCollection.MoveSelfToBack();
                break;
            case 5:
                if (!(targetCollection.LockState) && targetCollection is IFlippable flp2)
                {
                    flp2.SetOrientation(true);
                }
                break;
            case 6:
                if (!(targetCollection.LockState) && targetCollection is IFlippable flp3)
                {
                    flp3.SetOrientation(false);
                }
                break;
            case 8:
                targetCollection.Shuffle();
                break;
        }
    }
}