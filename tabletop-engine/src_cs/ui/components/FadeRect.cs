// Copyright ryanabx 2024
using Godot;
namespace TabletopEngine.UI.Components;

public partial class FadeRect : ColorRect
{
	private Timer _fadeInTimer;
	private Timer _fadeOutTimer;
	private string _scene = "";

	private bool _fadeInDone = false;
	private bool _fadeOutDone = false;
	// TODO: Find out signals in Godot C#
	[Signal]
	public delegate void SceneTransitionEventHandler(string scn);
	public override void _Ready()
	{
		base._Ready();
		SceneTransition += OnSceneTransition;
		Color = Color with { A = 1.0f };
		Show();
		
		_fadeInTimer = new Timer();
		_fadeOutTimer = new Timer();
		AddChild(_fadeInTimer);
		AddChild(_fadeOutTimer);
		_fadeOutTimer.Timeout += OnFadeTimerTimeout;
		_fadeInTimer.OneShot = true;
		_fadeOutTimer.OneShot = true;
		_fadeInTimer.WaitTime = Global.TRANSITION_TIME_IN;
		_fadeOutTimer.WaitTime = Global.TRANSITION_TIME_OUT;
		GetTree().CreateTimer(Global.TRANSITION_TIME_WAIT).Timeout += StartFadeTimer;
	}

	private void StartFadeTimer()
	{
		_fadeInTimer.Start();
		_fadeInDone = true;
	}

	public override void _Process(double delta)
	{
		base._Process(delta);
		if (_fadeInDone && !_fadeOutDone)
		{
			Color = Color with { A = !_fadeOutTimer.IsStopped() ? 1.0f - (float)(_fadeOutTimer.TimeLeft / _fadeOutTimer.WaitTime) : (float)(_fadeInTimer.TimeLeft / _fadeInTimer.WaitTime) };
		}
		else
		{
			Color = Color with { A = 1.0f };
		}
	}
	private void OnSceneTransition(string scene)
	{
		_scene = scene;
		_fadeOutTimer.Start();
	}
	private async void OnFadeTimerTimeout()
	{
		_fadeOutDone = true;
		await ToSignal(GetTree().CreateTimer(Global.TRANSITION_TIME_WAIT / 2), SceneTreeTimer.SignalName.Timeout);
		GetTree().ChangeSceneToFile(_scene);
	}
}