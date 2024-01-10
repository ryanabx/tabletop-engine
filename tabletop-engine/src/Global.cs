using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class Global : RefCounted
{
	public static Array<string> SPLASHES = [
		"Vegan, if you so choose!",
		"Fruit salad, yummy yummy!",
		"Can I drown myself? -Jacob",
		"Constantly improving!",
		"What will YOU create?",
		"'THIS IS THE SPLASH'; DROP TABLE Tabletops",
		"The GD in GDScript stands for 'Gosh Darn'!",
		"Why are kids these days always on they puters...",
		"Ryan does have great hair, I agree Minecraft!",
		"https://www.youtube.com/watch?v=u9n-6ZDGUBs",
		"90% of gamblers quit before making it big!"
	];
	public static Array<string> EXPLICIT_SPLASHES = [
		"Because fuck Tabletop Simulator!",
		"You have UNO, you fucking dick!",
		"Since your ass wanna act onions!"
	];
	public const string LICENSE_FILE = "res://src/resources/licenses.txt";
	public const int DEFAULT_MAX_PLAYERS = 4;
	public const float GRAB_THRESHOLD = 40.0f;
	public static Dictionary ICE_SERVERS = new(){
		{
			"iceServers",new Array<Dictionary>()
			{
				new()
				{
					{"urls", new Array<string>
						{
							"stun.l.google.com:19302",
							"iphone-stun.strato-iphone.de:3478",
							"numb.viagenie.ca:3478",
							"s1.taraba.net:3478",
							"s2.taraba.net:3478",
							"stun.12connect.com:3478",
							"stun.12voip.com:3478",
							"stun.1und1.de:3478",
							"stun.2talk.co.nz:3478",
							"stun.2talk.com:3478",
							"stun.3clogic.com:3478",
							"stun.3cx.com:3478",
							"stun.a-mm.tv:3478",
							"stun.aa.net.uk:3478",
							"stun.acrobits.cz:3478"
						}
					}
				},
				new(){{"urls", new Array<string>{"stun:stun.relay.metered.ca:80"}}},
				new()
				{
					{"urls","turn:numb.viagenie.ca"},
					{"credential", "muazkh"},
					{"username","webrtc@live.com"}
				},
				new()
				{
					{"urls","turn:192.158.29.39:3478?transport=udp"},
					{"credential", "JZEOEt2V3Qb0y27GRntt2u2PAYA="},
					{"username","28224511:1379330808"}
				},
				new()
				{
					{"urls","turn:192.158.29.39:3478?transport=tcp"},
					{"credential", "JZEOEt2V3Qb0y27GRntt2u2PAYA="},
					{"username","28224511:1379330808"}
				},
				new()
				{
					{"urls","turn:turn.bistri.com:80"},
					{"credential", "homeo"},
					{"username","homeo"}
				},
				new()
				{
					{"urls","turn:turn.anyfirewall.com:443?transport=tcp"},
					{"credential", "webrtc"},
					{"username","webrtc"}
				},
				new()
				{
					{"urls","turn:a.relay.metered.ca:80"},
					{"credential", "b7153991e76085c83420f473"},
					{"username","S7apm/MC4QIFJG4C"}
				},
				new()
				{
					{"urls","turn:a.relay.metered.ca:80?transport=tcp"},
					{"credential", "b7153991e76085c83420f473"},
					{"username","S7apm/MC4QIFJG4C"}
				},
				new()
				{
					{"urls","turn:a.relay.metered.ca:443?transport=tcp"},
					{"credential", "b7153991e76085c83420f473"},
					{"username","S7apm/MC4QIFJG4C"}
				},
				new()
				{
					{"urls","turn:a.relay.metered.ca:443"},
					{"credential", "b7153991e76085c83420f473"},
					{"username","S7apm/MC4QIFJG4C"}
				}
			}
		}
	};
	public static byte[] loadThisGame = [];

	public static int safeMarginLeft = 0;
	public static int safeMarginRight = 0;
	public static int safeMarginUp = 0;
	public static int safeMarginDown = 0;
	public const float TRANSITION_TIME_IN = 0.125f;
	public const float TRANSITION_TIME_OUT = 0.125f;
	public const float TRANSITION_TIME_WAIT = 0.1f;
	public static bool IsDesktopPlatform()
	{
		return new Array<string>() {
			"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"
		}.Contains(OS.GetName());
	}
	public static bool IsWebPlatform()
	{
		return OS.GetName() == "Web";
	}
	public static bool IsMobilePlatform()
	{
		return new Array<string>() {
			"iOS", "Android"
		}.Contains(OS.GetName());
	}
	public static Dictionary DEFAULT_USER_SETTINGS = new()
	{
		{"fullscreen",false},
		{"defaultTapMode","" /* TODO: Come back to this when Board is implemented.*/},
		{"signalingServer","wss://obf-server-signaling.onrender.com"}
	};
	public static Dictionary userSettings = DEFAULT_USER_SETTINGS.Duplicate(true);
	public static void ApplySetting(string name)
	{
		if (!DEFAULT_USER_SETTINGS.ContainsKey(name))
		{
			return;
		}
		switch (name)
		{
			case "fullscreen":
				DisplayServer.Singleton.WindowSetMode((bool)userSettings[name] ? DisplayServer.WindowMode.Fullscreen : DisplayServer.WindowMode.Windowed);
				break;
			default:
				break;
		}
	}
}