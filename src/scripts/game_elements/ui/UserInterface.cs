using Godot;
namespace TabletopEngine;
public partial class UserInterface : Control
{
    private Label _gameInfo;
    private Panel _paddingPanel;
    private Button _inputModeButton;
    private Button _touchTypeButton;
    private MenuButton _menuBar;
    private string _gameName;
    private Board _board = default;
    private Texture2D _imageOne = GD.Load<Texture2D>("res://src/resources/assets/ui/move.svg");
    private Texture2D _imageTwo = GD.Load<Texture2D>("res://src/resources/assets/ui/cursor.svg");
    private Texture2D[] _inputModeImages = new Texture2D[2];
    private string[] _touchTypes = new string[]{"Tap", "Drag"};
    public override void _Ready()
    {
        _gameInfo = GetNode<Label>("%GameInfo");
        _paddingPanel = GetNode<Panel>("PaddingPanel");
        _inputModeButton = GetNode<Button>("%InputModeButton");
        _touchTypeButton = GetNode<Button>("%TouchTypeButton");
        _menuBar = GetNode<MenuButton>("%MenuButton");
        _inputModeImages[0] = _imageOne;
        _inputModeImages[1] = _imageTwo;
        BoardManager bm = GetTree().Root.GetNode<BoardManager>("BoardManager");
        bm.GameLoadFinished += SetBoard;
        GetNode<MarginContainer>("SafeMargins").Connect("orientation_changed", new Callable(this, MethodName.OrientationChanged));
    }
    private void OrientationChanged()
    {
        _paddingPanel.CustomMinimumSize = new Vector2(_paddingPanel.CustomMinimumSize.X, Global.GetSingleton().SafeMarginTop + 2);
    }
    private void SetBoard(Board board)
    {
        _board = board;
        GD.Print("Game load finished");
        SetupMenuBar();
    }
    public override void _Process(double delta)
    {
        _gameInfo.Text = $"Game: {_gameName}";
        if (_board != default)
        {
            _gameName = _board.Game.Name;
            _inputModeButton.Icon = _inputModeImages[(int)_board.InputMode];
            _touchTypeButton.Text = _touchTypes[(int)_board.TouchMode];
            _touchTypeButton.Visible = _board.InputMode == Board.InputModeType.SELECT;
        }
    }
    private void OnInputSettingPressed()
    {
        if (_board.InputMode == Board.InputModeType.CAMERA)
        {
            _board.InputMode = Board.InputModeType.SELECT;
            return;
        }
        else
        {
            _board.InputMode = Board.InputModeType.CAMERA;
            return;
        }
    }
    private void OnTouchTypeButtonPressed()
    {
        if (_board.TouchMode == Board.TouchModeType.TAP)
        {
            _board.TouchMode = Board.TouchModeType.DRAG;
            return;
        }
        else
        {
            _board.TouchMode = Board.TouchModeType.TAP;
            return;
        }
    }
    // Menu Bar
    
    private PopupMenu _player;
    private PopupMenu _actions;
    private PopupMenu _helpMenu;
    private async void SetupMenuBar()
    {
        if (_player != default)
        {
            _player.QueueFree();
            await ToSignal(_player, Node.SignalName.TreeExited);
        }
        if (_actions != default)
        {
            _actions.QueueFree();
            await ToSignal(_actions, Node.SignalName.TreeExited);
        }
        PlayerMenu();
        ActionsMenu();
        AddHelpMenu();
        TabletopMenu();
    }
    private void PlayerMenu()
    {
        _player = new PopupMenu();
        _player.IndexPressed += SetPlayer;
        _player.Name = "Player";
        _menuBar.GetPopup().AddChild(_player);
        _menuBar.GetPopup().AddSubmenuItem("Player", "Player");
        for (int i = 0; i < _board.NumberOfPlayers; i++)
        {
            _player.AddItem($"Player {i + 1}");
        }
    }
    private void ActionsMenu()
    {
        _actions = new PopupMenu();
        _actions.IndexPressed += RunAction;
        _actions.Name = "Actions";
        if (_board.Game.GetActions().Length == 0)
        {
            return;
        }
        foreach (string i in _board.Game.GetActions())
        {
            _actions.AddItem(i);
        }
        _menuBar.GetPopup().AddChild(_actions);
        _menuBar.GetPopup().AddSubmenuItem("Actions", "Actions");
    }
    private void AddHelpMenu()
    {
        _helpMenu = new PopupMenu();
        _helpMenu.IndexPressed += TabletopPressed;
        _helpMenu.Name = "Help";
        _helpMenu.AddItem("Controls", 5);
        _helpMenu.AddItem("About Tabletop Engine", 6);
        _menuBar.GetPopup().AddChild(_helpMenu);
        _menuBar.GetPopup().AddSubmenuItem("Help", "Help");
    }
    private void TabletopMenu()
    {
        _menuBar.GetPopup().IdPressed += TabletopPressed;
        if (!Multiplayer.IsServer())
        {
            if (ConfigTools.ConfigExists(_board.Game.Name))
            {
                _menuBar.GetPopup().AddItem($"Update {_board.Game.Name}.", 2);
            }
            else
            {
                _menuBar.GetPopup().AddItem($"Download {_board.Game.Name}.", 2);
            }
        }
        _menuBar.GetPopup().AddItem("Main Menu", 0);
        if (Global.IsDesktopPlatform())
        {
            _menuBar.GetPopup().AddItem("Quit Game", 1);
        }
    }
    private void SetPlayer(long index)
    {
        _board.PlayerId = (int)index;
    }
    private void RunAction(long index)
    {
        _board.RunAction((int)index);
    }
    private void TabletopPressed(long id)
    {
        switch (id)
        {
            case 0:
                GetNode<Node>("%FaceRect").EmitSignal("scene_transition", "res://src/scenes/ui/pages/main_menu.tscn");
                break;
            case 1:
                GetTree().Quit();
                break;
            case 2:
                GetTree().Root.GetNode<BoardManager>("BoardManager").SaveConfig();
                break;
            case 5:
                GetNode<Window>("%ControlsInfo").Popup();
                break;
            case 6:
                GetNode<Window>("%AboutWindow").Popup();
                break;
        }
    }
}