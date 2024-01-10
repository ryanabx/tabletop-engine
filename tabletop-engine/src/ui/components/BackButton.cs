using Godot;
namespace TabletopEngine.UI.Components;

public partial class BackButton : Button
{
	[Export]
	private string _backScene;
	[Export]
	private FadeRect _fadeRect;
	public override void _Ready()
	{
		base._Ready();
		Pressed += OnPressed;
	}
	private void OnPressed()
	{
		_fadeRect.EmitSignal(FadeRect.SignalName.SceneTransition);
	}
}