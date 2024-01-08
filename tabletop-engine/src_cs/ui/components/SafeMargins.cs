using Godot;
namespace TabletopEngine.UI.Components;

public partial class SafeMargins : MarginContainer
{
	[Signal]
	public delegate void OrientationChangedEventHandler();
	private Rect2I _currentSafeArea = new Rect2I(0, 0, 0, 0);

	public override void _Ready()
	{
		base._Ready();
		OrientationChanged += ScreenOrientationChanged;
	}
	private void ScreenOrientationChanged()
	{
		AddThemeConstantOverride("margin_left", Global.safeMarginLeft);
		AddThemeConstantOverride("margin_top", Global.safeMarginUp);
		AddThemeConstantOverride("margin_right", Global.safeMarginRight);
		AddThemeConstantOverride("margin_bottom", Global.safeMarginDown);
	}
	private void OnScreenOrientationChanged()
	{
		Vector2I wSize = DisplayServer.ScreenGetSize(DisplayServer.GetPrimaryScreen());
		Rect2I orientationExtents = DisplayServer.GetDisplaySafeArea();

		Global.safeMarginLeft = orientationExtents.Position.X;
		Global.safeMarginUp = orientationExtents.Position.Y;
		Global.safeMarginRight = wSize.X - orientationExtents.Size.X - Global.safeMarginLeft;
		Global.safeMarginDown = wSize.Y - orientationExtents.Size.Y - Global.safeMarginUp;
		_currentSafeArea = DisplayServer.GetDisplaySafeArea();
		EmitSignal(SignalName.OrientationChanged);
	}
	// NOTE: Omitted fullscreen input check, TODO: put somewhere else
}