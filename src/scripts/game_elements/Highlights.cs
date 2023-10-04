using Godot;
namespace TabletopEngine;
public partial class Highlights : Node2D
{
    public Board GameBoard;
    public override void _Process(double delta)
    {
        QueueRedraw();
    }
    public override void _Draw()
    {
        DrawPlayerStuff();
    }
    private void DrawPlayerStuff()
    {
        if (GameBoard.GetPlayer().IsHighlighting())
        {
            if (GameBoard.GetPlayer().HighlightedObject is Hand hnd)
            {
                DrawSetTransform(hnd.Position, hnd.Rotation);
                if (GameBoard.GetPlayer().IsSelecting() || (GameBoard.GetPlayer().HighlightedObject is GameCollection gc && gc.Inside.Count == 0))
                {
                    DrawRect(
                        hnd.GetSelectedRange(),
                        Colors.Black * new Color(1.0f, 1.0f, 1.0f, 0.3f)
                    );
                }
                else
                {
                    DrawRect(
                        hnd.GetSelectedRange(),
                        Colors.Black * new Color(1.0f, 1.0f, 1.0f, 0.2f)
                    );
                    DrawRect(
                        hnd.GetSelectedRange(),
                        Colors.White, false, 4.0f
                    );
                }                
                DrawSetTransform(Position, Rotation);
            }
            else
            {
                if (GameBoard.GetPlayer().IsSelecting() || (GameBoard.GetPlayer().HighlightedObject is GameCollection gc && gc.Inside.Count == 0))
                {
                    DrawColoredPolygon(
                        GameBoard.GetPlayer().HighlightedObject.GetExtents(),
                        Colors.Black * new Color(1.0f, 1.0f, 1.0f, 0.3f)
                    );
                }
                else
                {
                    DrawColoredPolygon(
                        GameBoard.GetPlayer().HighlightedObject.GetExtents(),
                        Colors.Black * new Color(1.0f, 1.0f, 1.0f, 0.2f)
                    );
                    DrawMultiline(
                        GameBoard.GetPlayer().HighlightedObject.GetExtents(),
                        Colors.White, 4.0f
                    );
                }
            }
        }
        if (GameBoard.GetPlayer().IsQueueing())
        {
            if (GameBoard.GetPlayer().QueuedObject is Hand hnd)
            {
                DrawSetTransform(hnd.Position, hnd.Rotation);
                DrawRect(
                    hnd.GetSelectedRange(),
                    Colors.Blue * new Color(1.0f, 1.0f, 1.0f, 0.2f)
                );
                DrawSetTransform(Position, Rotation);
            }
            else
            {
                DrawColoredPolygon(
                    GameBoard.GetPlayer().SelectedObject.GetExtents(),
                    Colors.Blue * new Color(1.0f, 1.0f, 1.0f, 0.2f)
                );
            }
        }
        if (GameBoard.GetPlayer().IsSelecting())
        {
            DrawColoredPolygon(
                GameBoard.GetPlayer().SelectedObject.GetExtents(),
                Colors.Green * new Color(1.0f, 1.0f, 1.0f, 0.1f)
            );
            DrawMultiline(
                GameBoard.GetPlayer().SelectedObject.GetExtents(),
                Colors.Green * new Color(1.0f, 1.0f, 1.0f, 0.8f)
            );
        }
    }
}