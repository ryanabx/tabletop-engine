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
    public Array<int> DesignatedPlayers = new Array<int>();
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
            Vector2 cardPosition = new Vector2(
                Mathf.Lerp(GetRect().Position.X + SizePieces.X / 2.0f, GetRect().End.X - SizePieces.X / 2.0f, (i + 0.5f) / Inside.Count),
                GetRect().GetCenter().Y
            );
            DrawPiece(pc, false, cardPosition);
            i++;
        }
        if (_selectablePiece != -1 && _selectablePiece < Inside.Count)
        {
            Vector2 cardPosition = new Vector2(
                Mathf.Lerp(GetRect().Position.X + SizePieces.X / 2.0f, GetRect().End.X - SizePieces.X / 2.0f, (_selectablePiece + 0.5f) / Inside.Count),
                GetRect().GetCenter().Y
            );
            DrawPiece(Inside[_selectablePiece], true, cardPosition);
        }
    }
    private void DrawPiece(Dictionary data, bool selectable, Vector2 position)
    {
        Vector2 size = (selectable) ? SizePieces * 1.1f : SizePieces;
        Texture2D texture = GameBoard.GetImage(CanView() ? data["ImageUp"] : data["ImageDown"]);
        DrawTextureRect(texture, new Rect2(position - size / 2.0f, size), false);
    }
    public Rect2 GetSelectedRange()
    {
        // TODO: Implement
        return default;
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
            
        }
        return base.RemoveFromTop(position);
    }
    
}