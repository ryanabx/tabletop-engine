using Godot;
namespace TabletopEngine.UI.Components;

public partial class InfoPopup : Window
{
	public override void _Ready()
	{
		base._Ready();
		CloseRequested += OnCloseRequested;
	}
	private void OnCloseRequested()
	{
		Hide();
	}
	// TODO: Connect this signal to the OK button
	private void OnOkButtonPressed()
	{
		Hide();
	}
}