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
    private Texture2D _imageOne;
    private Texture2D _imageTwo;
    private string[] _touchTypes = new string[]{"Tap", "Drag"};
    public override void _Ready()
    {
        
    }
}