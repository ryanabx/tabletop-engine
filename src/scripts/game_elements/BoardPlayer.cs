using System.Linq;
using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class BoardPlayer : Node2D
{
    public Board GameBoard;
    public Selectable SelectedObject = null;
    public Selectable QueuedObject = null;
    public Selectable HighlightedObject = null;
    private Vector2 _grabPosition = Vector2.Zero;
    private Timer _holdTimer;
    private PhysicsDirectSpaceState2D _physicsState;
    private int _selectIndex = -1;
    private int _tapsSinceSelecting = 0;
    private Dictionary<int, InputEvent> _inputEvents = new();
    private int _pollNum = 0;
    private const int POLLING_RATE = 3;
    public override void _Ready()
    {
        _physicsState = GetWorld2D().DirectSpaceState;
        _holdTimer = new(){
            WaitTime = 0.5f
        };
        _holdTimer.Timeout += HoldTimerTimeout;
        AddChild(_holdTimer);
    }
    private void HoldTimerTimeout()
    {
        if (CollectionQueued())
        {
            SelectCollection((GameCollection)QueuedObject);
        }
    }
    public bool IsSelecting()
    {
        return SelectedObject != null && IsInstanceValid(SelectedObject);
    }
    public bool IsQueueing()
    {
        return QueuedObject != null && IsInstanceValid(QueuedObject);
    }
    public bool IsHighlighting()
    {
        return HighlightedObject != null && IsInstanceValid(HighlightedObject);
    }
    public bool PieceSelected()
    {
        return IsSelecting() && SelectedObject is Piece;
    }
    public bool CollectionSelected()
    {
        return IsSelecting() && SelectedObject is GameCollection;
    }
    public bool PieceQueued()
    {
        return IsQueueing() && QueuedObject is Piece;
    }
    public bool CollectionQueued()
    {
        return IsQueueing() && QueuedObject is GameCollection;
    }
    public override void _Input(InputEvent @event)
    {
        if (GameBoard.InputMode == Board.InputModeType.CAMERA)
        {
            _inputEvents.Clear();
            Deselect();
            return;
        }
        InputEvent @ev = MakeInputLocal(@event);
        if (@ev is InputEventMouseMotion || (@ev is InputEventMouseButton button && button.ButtonIndex == MouseButton.Left))
        {
            UpdateHighlighted(@ev);
        }
        if (@ev.IsActionPressed("game_flip"))
        {
            if (IsSelecting() && !SelectedObject.LockState && SelectedObject is IFlippable f)
            {
                f.Flip();
            }
        }
        if (@ev is InputEventScreenTouch touch)
        {
            TouchInput(touch);
        }
        else if (@ev is InputEventScreenDrag drag)
        {
            DragInput(drag);
        }
    }
    private void UpdateHighlighted(InputEvent @event)
    {
        if (GameBoard.TouchMode == Board.TouchModeType.DRAG && @event is InputEventMouseMotion)
        {
            return;
        }
        else if (GameBoard.TouchMode == Board.TouchModeType.TAP && !Input.IsMouseButtonPressed(MouseButton.Left))
        {
            HighlightedObject = null;
            return;
        }

        if (_pollNum == 0 || @event is InputEventMouseButton)
        {
            HighlightedObject = GetColliderAtPosition(GetLocalMousePosition());
            if (HighlightedObject != null && !GameBoard.Game.CanHighlight(HighlightedObject, SelectedObject))
            {
                HighlightedObject = null;
            }
        }
        _pollNum = (_pollNum + 1) % POLLING_RATE;
    }
    private void TouchInput(InputEventScreenTouch touch)
    {
        if (touch.Pressed)
        {
            _inputEvents[touch.Index] = touch;
        }
        else
        {
            _inputEvents.Remove(touch.Index);
        }
        if (_selectIndex != -1 && touch.Index != _selectIndex && _inputEvents.Count > 1)
        {
            return;
        }
        if (touch.Pressed)
        {
            _tapsSinceSelecting++;
            GD.Print("Tapped since selecting!");
        }
        if (touch.DoubleTap)
        {
            DoubleTapInput(touch);
        }
        else
        {
            SingleTapInput(touch);
        }
    }
    private void SingleTapInput(InputEventScreenTouch touch)
    {
        if (touch.Pressed && _inputEvents.Count == 1) // Tap pressed
        {
            if (GameBoard.TouchMode == Board.TouchModeType.DRAG)
            {
                TapPressedDrag(touch);
            }
            else if (GameBoard.TouchMode == Board.TouchModeType.TAP)
            {
                TapPressedTap(touch);
            }
        }
        else if (!touch.Pressed) // Tap released
        {
            if (GameBoard.TouchMode == Board.TouchModeType.DRAG)
            {
                TapReleasedDrag(touch);
            }
            else if (GameBoard.TouchMode == Board.TouchModeType.TAP)
            {
                TapReleasedTap(touch);
            }
        }
    }
    private void TapPressedDrag(InputEventScreenTouch touch)
    {
        SelectWithEvent(touch);
    }
    private void TapReleasedDrag(InputEventScreenTouch touch)
    {
        if (IsSelecting())
        {
            DeselectWithEvent(touch);
        }
        _holdTimer.Stop();
    }
    private void TapPressedTap(InputEventScreenTouch touch)
    {
        if (IsQueueing())
        {
            if (GetColliderAtPosition(GetLocalMousePosition(), 1) != QueuedObject)
            {
                Deselect();
            }
            else
            {
                _grabPosition = touch.Position;
                _holdTimer.Start();
            }
        }
    }
    private void TapReleasedTap(InputEventScreenTouch touch)
    {
        if (!IsSelecting() && !IsQueueing())
        {
            SelectWithEvent(touch);
        }
        else if (IsSelecting() && GetColliderAtPosition(GetLocalMousePosition(), 2) != SelectedObject)
        {
            DeselectWithEvent(touch);
        }
        else if (IsQueueing() && GetColliderAtPosition(GetLocalMousePosition()) != QueuedObject)
        {
            Deselect();
        }
        _holdTimer.Stop();
    }
    private void SelectWithEvent(InputEventScreenTouch touch)
    {
        Selectable collider = GetColliderAtPosition(GetLocalMousePosition());
        if (collider == null) {return;}
        _grabPosition = touch.Position;
        _selectIndex = touch.Index;
        collider.OnSelect(touch);
    }
    private void DeselectWithEvent(InputEventScreenTouch touch)
    {
        GetColliderAtPosition(GetLocalMousePosition())?.OnDeselect(touch);
        Deselect();
    }
    private void DoubleTapInput(InputEventScreenTouch touch)
    {
        if (touch.Pressed)
        {
            if (GameBoard.TouchMode == Board.TouchModeType.TAP && _tapsSinceSelecting < 2)
            {
                return;
            }
            Selectable collider = GetColliderAtPosition(GetLocalMousePosition());
            if (collider != null)
            {
                if (collider is GameCollection gc)
                {
                    GameBoard.EmitSignal(Board.SignalName.CreateContextMenu, gc);
                }
                else if (collider is Piece pc)
                {
                    GameBoard.EmitSignal(Board.SignalName.CreateContextMenu, pc);
                }
                Deselect();
            }
        }
    }
    private Selectable GetColliderAtPosition(Vector2 position, int collisionMask = 1)
    {
        PhysicsPointQueryParameters2D queryParams = new()
        {
            Position = position,
            CollideWithAreas = true,
            CollideWithBodies = false,
            CollisionMask = (uint)collisionMask
        };
        Array<Dictionary> results = _physicsState.IntersectPoint(queryParams, 65535);
        if (results.Count > 0)
        {
            Dictionary topObj = results.MaxBy(res => ((Area2D)res["collider"]).GetParent<Selectable>().Index);
            return ((Area2D)topObj["collider"]).GetParent<Selectable>();
        }
        return null;
    }
    private void DragInput(InputEventScreenDrag drag)
    {
        _inputEvents[drag.Index] = drag;
        if (_selectIndex != drag.Index)
        {
            return;
        }
        if (IsQueueing() && drag.Position.DistanceTo(_grabPosition) > Global.GetSingleton().GRAB_THRESHOLD)
        {
            _holdTimer.Stop();
            if (CollectionQueued() && GameBoard.Game.CanTakePieceOff((GameCollection)QueuedObject))
            {
                Piece piece = ((GameCollection)QueuedObject).RemoveFromTop(QueuedObject.ToLocal(_grabPosition));
                SelectObject(piece);
            }
            else if (PieceQueued())
            {
                SelectObject(QueuedObject);
            }
            MoveObjectsTo(drag.Position);
        }
    }
    private void MoveObjectsTo(Vector2 position)
    {
        if (IsSelecting())
        {
            SelectedObject.Position = (position - SelectedObject.GrabOffset).Clamp(-GameBoard.Size/2.0f, GameBoard.Size/2.0f);
        }
    }
    private void SelectObject(Selectable obj)
    {
        Deselect();
        obj.Authority = Multiplayer.GetUniqueId();
        obj.MoveSelfToTop();
        SelectedObject = obj;
        obj.Selected = Multiplayer.GetUniqueId();
        obj.GrabOffset = _grabPosition - obj.Position;
    }
    public void QueueSelectObject(Selectable obj)
    {
        if (IsQueueing())
        {
            Deselect();
        }
        if (obj.Queued == 0 && obj.Selected == 0)
        {
            obj.Authority = Multiplayer.GetUniqueId();
            _tapsSinceSelecting = 0;
            obj.MoveSelfToTop();
            QueuedObject = obj;
            obj.Queued = Multiplayer.GetUniqueId();
            _holdTimer.Start();
        }
    }
    public void StackSelectionToItem(Selectable item)
    {
        item.Authority = Multiplayer.GetUniqueId();
        if (item is GameCollection collection)
        {
            StackOnCollection(collection);
        }
        else if (item is Piece piece)
        {
            StackOnPiece(piece);
        }
        Deselect();
    }
    private void StackOnCollection(GameCollection collection)
    {
        if (CollectionSelected())
        {
            collection.AddCollection((GameCollection)SelectedObject);
        }
        else if (PieceSelected())
        {
            collection.AddPiece((Piece)SelectedObject);
        }
    }
    private void StackOnPiece(Piece piece)
    {
        if (CollectionSelected())
        {
            SelectedObject.Position = piece.Position;
            SelectedObject.Rotation = piece.Rotation;
            ((GameCollection)SelectedObject).AddPiece(piece, true);
        }
        else if (PieceSelected())
        {
            GameCollection collection = (GameCollection)GameBoard.NewGameObject(
                Board.GameObjectType.DECK,
                new Dictionary
                {
                    ["position"] = piece.Position,
                    ["rotation"] = piece.Rotation,
                    ["FaceUp"] = ((Flat)piece).FaceUp
                }
            );
            collection.AddPiece(piece);
            collection.AddPiece((Piece)SelectedObject);
        }
    }
    private void SelectCollection(GameCollection collection)
    {
        if (collection is Hand || (collection is Deck dck && dck.Permanent))
        {
            GameCollection newCollection = (GameCollection)GameBoard.NewGameObject(
                Board.GameObjectType.DECK,
                new Dictionary
                {
                    ["position"] = collection.Position,
                    ["rotation"] = collection.Rotation,
                    ["FaceUp"] = collection.FaceUp
                }
            );
            newCollection.Inside = collection.Inside;
            newCollection.AddToPropertyChanges("Inside", newCollection.Inside);
            collection.ClearInside();
            collection = newCollection;
        }
        _grabPosition = collection.Position;
        SelectObject(collection);
        collection.GrabOffset = Vector2.Zero;
    }
    private void Deselect()
    {
        _holdTimer.Stop();
        DeselectObject();
        DequeueObject();
    }
    private void DeselectObject()
    {
        if (IsSelecting() && SelectedObject.Selected == Multiplayer.GetUniqueId())
        {
            SelectedObject.Authority = Multiplayer.GetUniqueId();
            SelectedObject.Selected = 0;
            SelectedObject = null;
        }
    }
    private void DequeueObject()
    {
        if (IsQueueing() && QueuedObject.Queued == Multiplayer.GetUniqueId())
        {
            _tapsSinceSelecting = 0;
            QueuedObject.Authority = Multiplayer.GetUniqueId();
            QueuedObject.Queued = 0;
            QueuedObject = null;
        }
    }
    public void RotateSelection(float amount, float axis)
    {
        if (IsSelecting())
        {
            SelectedObject.Rotation += amount;
            if (Mathf.Abs(axis) < 0.1f && Mathf.Abs(Mathf.Round(SelectedObject.RotationDegrees / 45.0) * 45.0 - SelectedObject.RotationDegrees) < 7.5f)
            {
                SelectedObject.RotationDegrees = Mathf.Round(SelectedObject.RotationDegrees / 45.0f) * 45.0f;
            }
        }
    }
}