using Godot;
using Godot.Collections;
public partial class Hand : GameCollection
{
    public enum VisibilitySetting
    {
        ALL, DESIGNATED, NOT_DESIGNATED, NONE
    };
    public float LayeringFactor = 0.9f;
    public VisibilitySetting PieceVisibility = VisibilitySetting.DESIGNATED;
    public Array<int> DesignatedPlayers = new();
    public Vector2 SizePieces = Vector2.One;
    private float _spacingInterval = 1.0f;
    private int _selectablePiece = -1;
    private int _droppableIndex = -1;
    private int _cardToSelect = -1;
    public override Array<string> GetShareableProperties()
    {
        return base.GetShareableProperties() + new Array<string>{"LayeringFactor", "PieceVisibility", "DesignatedPlayers", "SizePieces"};
    }
    public override void _Draw()
    {
        DrawRect(GetRect(), Colors.Black * new Color(1.0f, 1.0f, 1.0f, 0.3f));
        if (CanView())
        {
            DrawRect(GetRect(), Colors.White * new Color(1.0f, 1.0f, 1.0f, 0.3f), false, 2.0f);
        }
        DrawPieces();
    }
    public void DrawPieces()
    {
        int i = 0;
        foreach (Dictionary pc in Inside)
        {
            if (i == _selectablePiece)
            {
                i++;
                continue;
            }
            Vector2 cardPosition = new(
                Mathf.Lerp(GetRect().Position.X + SizePieces.X / 2.0f, GetRect().End.X - SizePieces.X / 2.0f, (i + 0.5f) / Inside.Count),
                GetRect().GetCenter().Y
            );
            DrawPiece(pc, false, cardPosition);
            i++;
        }
        if (_selectablePiece != -1 && _selectablePiece < Inside.Count)
        {
            Vector2 cardPosition = new(
                Mathf.Lerp(GetRect().Position.X + SizePieces.X / 2.0f, GetRect().End.X - SizePieces.X / 2.0f, (_selectablePiece + 0.5f) / Inside.Count),
                GetRect().GetCenter().Y
            );
            DrawPiece(Inside[_selectablePiece], true, cardPosition);
        }
    }
    private void DrawPiece(Dictionary data, bool selectable, Vector2 position)
    {
        Vector2 size = (selectable) ? SizePieces * 1.1f : SizePieces;
        Texture2D texture = GameBoard.GetImage(CanView() ? (string)data["ImageUp"] : (string)data["ImageDown"]);
        DrawTextureRect(texture, new Rect2(position - size / 2.0f, size), false);
    }
    public Rect2 GetSelectedRange()
    {
        if (_selectablePiece == -1)
        {
            return new Rect2(0, 0, 0, 0);
        }
        Vector2 position = new(
            Mathf.Lerp(GetRect().Position.X + SizePieces.X / 2.0f, GetRect().End.X - SizePieces.X / 2.0f, (_selectablePiece + 0.5f) / Inside.Count),
            GetRect().GetCenter().Y
        );
        Vector2 size = SizePieces * 1.1f;
        return new(position - size / 2.0f, size);
    }
    private bool CanView()
    {
        return PieceVisibility switch
        {
            VisibilitySetting.ALL => true,
            VisibilitySetting.NONE => false,
            VisibilitySetting.DESIGNATED => DesignatedPlayers.Contains(GameBoard.PlayerId + 1),
            VisibilitySetting.NOT_DESIGNATED => !DesignatedPlayers.Contains(GameBoard.PlayerId + 1),
            _ => true,
        };
    }
    public override void AddPiece(Piece piece, bool back = false)
    {
        if (_droppableIndex == -1) {
            base.AddPiece(piece, back);
            return;
        }
        AddPieceAt(piece, _droppableIndex);
    }
    public override void AddCollection(GameCollection collection, bool back = false)
    {
        if (_droppableIndex == -1) {
            base.AddCollection(collection, back);
            return;
        }
        AddCollectionAt(collection, _droppableIndex);
    }
    public override Piece RemoveFromTop(Vector2 position)
    {
        if (_cardToSelect == -1)
        {
            FindSelectablePiece(position, false);
        }
        Piece piece = _selectablePiece == -1 ? base.RemoveFromTop(position) : base.RemovePieceAt(_selectablePiece);
        piece.Position = GetGlobalMousePosition();
        piece.Rotation = Rotation;
        piece.GrabOffset = Vector2.Zero;
        if (piece is Flippable f)
        {
            f.SetOrientation(FaceUp);
        }
        return piece;
    }
    private void FindSpacingInterval()
    {
        _spacingInterval = SizePieces.X * LayeringFactor;
        if (_spacingInterval * Inside.Count > Size.X)
        {
            _spacingInterval = (Size.X - SizePieces.X / 2.0f) / Inside.Count;
        }
    }
    private void FindSelectablePiece(Vector2 position, bool checkBoundaries = true)
    {
        if (GameBoard.InputMode == Board.InputModeType.CAMERA)
        {
            ResetSelectablePiece();
            return;
        }
        float check = ((position.X + (Size.X / 2.0f)) - (SizePieces.X / 2.0f) / (Size.X - SizePieces.X)) * Inside.Count;
        _selectablePiece = Mathf.Clamp(Mathf.FloorToInt(check), 0, Inside.Count - 1);
        _droppableIndex = Mathf.Clamp(Mathf.RoundToInt(check), 0, Inside.Count - 1);
    }
    private void ResetSelectablePiece()
    {
        _selectablePiece = -1;
        _droppableIndex = -1;
    }
    public override void _Process(double delta)
    {
        QueueRedraw();
        FindSpacingInterval();
        if (Queued == 0 && Selected == 0)
        {
            _cardToSelect = -1;
            if (GameBoard.TouchMode == Board.TouchModeType.DRAG || (GameBoard.TouchMode == Board.TouchModeType.TAP && Input.IsMouseButtonPressed(MouseButton.Left)))
            {
                FindSelectablePiece(GetLocalMousePosition());
            }
            else
            {
                ResetSelectablePiece();
            }
        }
        else
        {
            _selectablePiece = _cardToSelect;
        }
        base._Process(delta);
    }
    public override void OnSelect(InputEventScreenTouch touch)
    {
        if (Inside.Count == 0 || Selected != 0 || Queued != 0)
        {
            return;
        }
        GameBoard.GetPlayer().QueueSelectObject(this);
        FindSelectablePiece(GetLocalMousePosition());
        _cardToSelect = _selectablePiece;
    }
}