using Godot;
namespace TabletopEngine.UI.Components;

public partial class AboutInformation : Control
{
	private Label _version;
	private Label _license;
	public override void _Ready()
	{
		base._Ready();
		_version = GetNode<Label>("VersionNumber");
		_license = GetNode<Label>("Licenses");
	}
	// TODO: Connect these 3 signals to the proper button presses
	private void OnSubmitFeedbackPressed()
	{
		OS.ShellOpen("https://github.com/ryanabx/tabletop-engine/issues/new");
	}
	private void OnDocsPressed()
	{
		OS.ShellOpen("https://github.com/ryanabx/tabletop-engine");
	}
	private void OnGithubPressed()
	{
		OS.ShellOpen("https://github.com/ryanabx/tabletop-engine");
	}
}