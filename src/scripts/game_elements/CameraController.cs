using System.Linq;
using Godot;
using Godot.Collections;

namespace TabletopEngine;
public partial class CameraController : Camera2D
{
    private const float MOVEMENT_SPEED = 2000.0f;
    private const float ROTATION_SPEED = 2.5f;
    private Board _gameBoard = default;
    private Dictionary<int, InputEventFromWindow> _currentPoints = new();
    public override void _Ready()
    {
        GetTree().Root.GetNode<BoardManager>("BoardManager").GameLoadFinished += GameLoaded;
    }
    public void GameLoaded(Board board)
    {
        _gameBoard = board;
    }
    public override void _Input(InputEvent @event)
    {
        // Camera scrolling
        if (@event.IsActionPressed("ui_zoom_in"))
        {
            Zoom *= 1.1f;
        }
        else if (@event.IsActionPressed("ui_zoom_out"))
        {
            Zoom /= 1.1f;
        }
        // Everything else
        if (_gameBoard != default && _gameBoard.InputMode == Board.InputModeType.SELECT)
        {
            _currentPoints.Clear();
            return;
        }
        @event = MakeInputLocal(@event);
        if (@event is InputEventScreenTouch touch)
        {
            if (touch.Pressed)
            {
                _currentPoints[touch.Index] = touch;
            }
            else
            {
                _currentPoints.Remove(touch.Index);
            }
        }
        else if (@event is InputEventScreenDrag drag)
        {
            _currentPoints[drag.Index] = drag;
            if (_currentPoints.Count == 1) // Only pan
            {
                Position -= drag.Relative.Rotated(Rotation);
            }
            else if (_currentPoints.Count == 2) // Pan, zoom, rotate
            {
                int other;
                int my = drag.Index;
                Array<int> keys = new(_currentPoints.Keys.ToList());
                if (keys.IndexOf(drag.Index) == 0)
                {
                    other = keys[1];
                }
                else if (keys.IndexOf(drag.Index) == 1)
                {
                    other = keys[0];
                }
                else
                {
                    GD.Print($"Can't find key with index {drag.Index}");
                    return;
                }
                InputEventScreenDrag ptsMy = (InputEventScreenDrag)_currentPoints[my];
                InputEventFromWindow ptsOther = _currentPoints[other];
                Vector2 a1 = ptsMy.Position, b, a2 = ptsMy.Position + ptsMy.Relative;
                if (_currentPoints[other] is InputEventScreenTouch otherTouch)
                {
                    b = otherTouch.Position;
                }
                else if (_currentPoints[other] is InputEventScreenDrag otherDrag)
                {
                    b = otherDrag.Position;
                }
                else
                {
                    GD.Print("Other in current points was neither drag nor touch?");
                    return;
                }
                Vector2 v1 = b - a1;
                Vector2 v2 = b - a2;

                Vector2 c1 = a1 + (v1 / 2.0f);
                Vector2 c2 = a2 + (v2 / 2.0f);
                float deltaAngle = v2.AngleTo(v1);
                Vector2 deltaScale = Vector2.One * (v2.Length() / v1.Length());
                Vector2 deltaPosition = (c2 - c1).Rotated(Rotation + deltaAngle);
                Position -= deltaPosition;
                Rotation += deltaAngle;
                Zoom *= deltaScale;
            }
        }
        if (_gameBoard != default)
        {
            Position = Position.Clamp(-_gameBoard.Size / 2.0f, _gameBoard.Size / 2.0f);
        }
    }
    // TODO: Continue here!
    private bool BoardSelecting()
    {
        return _gameBoard != default && (_gameBoard.GetPlayer().IsSelecting() || _gameBoard.GetPlayer().IsQueueing());
    }
    private void DesktopEvents(float delta)
    {
        if (Input.IsActionPressed("camera_zoom_in"))
        {
            Zoom *= 1.0f + (1.5f * delta);
        }
        if (Input.IsActionPressed("camera_zoom_out"))
        {
            Zoom /= 1.0f + (1.5f * delta);
        }
        Position += (Input.GetVector("camera_left", "camera_right", "camera_up", "camera_down") * MOVEMENT_SPEED * delta).Rotated(Rotation);
        if (_gameBoard != default)
        {
            Position = Position.Clamp(-_gameBoard.Size / 2.0f, _gameBoard.Size / 2.0f);
        }
        float rotationAmt = Input.GetAxis("camera_rotate_clockwise", "camera_rotate_counterclockwise");
        if (_gameBoard == default || !_gameBoard.GetPlayer().IsSelecting())
        {
            Rotation += rotationAmt * ROTATION_SPEED * delta;
        }
        else if (_gameBoard != default)
        {
            _gameBoard.GetPlayer().RotateSelection(rotationAmt * ROTATION_SPEED * delta, rotationAmt);
        }
        if (Mathf.Abs(rotationAmt) < 0.1 && Mathf.Abs(Mathf.Round(RotationDegrees / 45.0f) * 45.0f - RotationDegrees) < 7.5f)
        {
            RotationDegrees = Mathf.Round(RotationDegrees / 45.0f) * 45.0f;
        }
    }
    public override void _Process(double delta)
    {
        if (Global.IsDesktopPlatform())
        {
            DesktopEvents((float)delta);
        }
        Zoom = Zoom.Clamp(new Vector2(0.2f, 0.2f), new Vector2(10.0f, 10.0f));
    }
}