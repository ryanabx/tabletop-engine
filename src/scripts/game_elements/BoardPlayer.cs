using Godot;
using Godot.Collections;

public partial class BoardPlayer : Node2D
{
    public Board GameBoard;
    private Selectable _selectedObject = null;
    private Selectable _queuedObject = null;
    private Vector2 _grabPosition = Vector2.Zero;
    private Timer _holdTimer;
    private PhysicsDirectSpaceState2D _physicsState;
    private int _selectIndex = -1;
    private int _tapsSinceSelecting = 0;
    private Dictionary _inputEvents;
    private Selectable _highlightedObject = null;
}