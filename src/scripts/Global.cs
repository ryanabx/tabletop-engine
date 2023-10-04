using Godot;
using Godot.Collections;
namespace TabletopEngine;
public partial class Global : RefCounted
{
    public static Global GetSingleton()
    {
        return GlobalSingleton;
    }
    private static readonly Global GlobalSingleton = new();
    public bool HasSetup = false;
    public readonly string[] SPLASHES = {
        "\"Because fuck Tabletop Simulator\"!",
        "Vegan, if you so choose!",
        "You have UNO, you fucking dick!",
        "Fruit salad, yummy yummy!",
        "Can I drown myself? -Jacob",
        "Since your ass wanna act onions!",
        "Constantly improving!",
        "What will YOU create?",
        "THIS IS THE SPLASH\"; DROP TABLE Tabletops",
        "The GD in GDScript stands for \"Gosh Darn\"!",
        "Why are kids these days always on they puters...",
        "Ryan does have great hair, I agree Minecraft!",
        "https://www.youtube.com/watch?v=u9n-6ZDGUBs",
        "90% of gamblers quit before making it big!"
    };
    public readonly float GRAB_THRESHOLD = 40.0f;
    public readonly Dictionary<string, Variant> ICE_SERVERS = new()
    {
        ["iceServers"] = new Array<Dictionary<string, Variant>>{
            new Dictionary<string, Variant>
            {
                ["urls"] = new Array<string>{
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
            },
            new Dictionary<string, Variant>
            {
            ["urls"] = new Array<string>{"stun:stun.relay.metered.ca:80"}
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:numb.viagenie.ca",
                ["credential"] = "muazkh",
                ["username"] = "webrtc@live.com"
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:192.158.29.39:3478?transport=udp",
                ["credential"] = "JZEOEt2V3Qb0y27GRntt2u2PAYA=",
                ["username"] = "28224511:1379330808"
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:192.158.29.39:3478?transport=tcp",
                ["credential"] = "JZEOEt2V3Qb0y27GRntt2u2PAYA=",
                ["username"] = "28224511:1379330808"
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:turn.bistri.com:80",
                ["credential"] = "homeo",
                ["username"] = "homeo"
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:turn.anyfirewall.com:443?transport=tcp",
                ["credential"] = "webrtc",
                ["username"] = "webrtc"
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:a.relay.metered.ca:80",
                ["username"] = "b7153991e76085c83420f473",
                ["credential"] = "S7apm/MC4QIFJG4C",
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:a.relay.metered.ca:80?transport=tcp",
                ["username"] = "b7153991e76085c83420f473",
                ["credential"] = "S7apm/MC4QIFJG4C",
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:a.relay.metered.ca:443",
                ["username"] = "b7153991e76085c83420f473",
                ["credential"] = "S7apm/MC4QIFJG4C",
            },
            new Dictionary<string, Variant>
            {
                ["urls"] = "turn:a.relay.metered.ca:443?transport=tcp",
                ["username"] = "b7153991e76085c83420f473",
                ["credential"] = "S7apm/MC4QIFJG4C",
            }
        }
    };
    public byte[] LoadThisGame = default;
    public int SafeMarginLeft = 0;
    public int SafeMarginTop = 0;
    public int SafeMarginRight = 0;
    public int SafeMarginBottom = 0;
    public readonly float TRANSITION_TIME_IN = 0.125f;
    public readonly float TRANSITION_TIME_OUT = 0.125f;
    public readonly float TRANSITION_TIME_WAIT = 0.1f;
    // FILE PATHS
    public readonly string CONFIG_REPO = "user://configs";
    public readonly string DEFAULT_CONFIG_REPO = "res://configs";
    public readonly string CONFIG_EXTENSION = ".tbt";
    public readonly string SETTINGS_PATH = "user://settings.json";
    // PLATFORMS
    public static bool IsDesktopPlatform()
    {
#if GODOT_PC
        return true;
#else
        return false;
#endif
    }
    public static bool IsWebPlatform()
    {
#if GODOT_WEB
        return true;
#else
        return false;
#endif
    }
    public static bool IsMobilePlatform()
    {
#if GODOT_MOBILE
        return true;
#else
        return false;
#endif
    }
    public readonly Dictionary<string, Variant> DEFAULT_USER_SETTINGS = new()
    {
        ["fullscreen"] = false,
        ["default_tap_mode"] = IsMobilePlatform() ? (int)Board.TouchModeType.TAP : (int)Board.TouchModeType.DRAG,
        ["signaling_server"] = "wss://obf-server-signaling.onrender.com",
        ["ui_scale"] = 5.0f
    };
    private Dictionary<string, Variant> _userSettings = new();
    public void SetUserSetting(string setting, Variant value)
    {
        if (!DEFAULT_USER_SETTINGS.ContainsKey(setting))
        {
            return;
        }
        else if (DEFAULT_USER_SETTINGS[setting].Equals(value))
        {
            _userSettings.Remove(setting);
            return;
        }
        switch (setting)
        {
            case "fullscreen":
                DisplayServer.WindowSetMode(((bool)value) ? DisplayServer.WindowMode.Fullscreen : DisplayServer.WindowMode.Windowed);
                _userSettings[setting] = value;
                break;
            case "ui_scale":
                ThemeDB.GetProjectTheme().DefaultBaseScale = Mathf.Clamp((float)value, 0.25f, 8.0f);
                ThemeDB.GetProjectTheme().DefaultFontSize = Mathf.Clamp((int)((float)value * 8.0f), 2, 64);
                _userSettings[setting] = Mathf.Clamp((float)value, 0.25f, 8.0f);
                GD.Print($"Setting font size to {Mathf.Clamp((int)((float)value * 8.0f), 2, 64)}");
                break;
            default:
                _userSettings[setting] = value;
                break;
        }
        SaveSettings();
    }
    public Variant GetUserSetting(string setting)
    {
        if (_userSettings.ContainsKey(setting))
        {
            return _userSettings[setting];
        }
        else if (DEFAULT_USER_SETTINGS.ContainsKey(setting))
        {
            return DEFAULT_USER_SETTINGS[setting];
        }
        return default;
    }
    public void LoadSettings()
    {
        if (FileAccess.FileExists(SETTINGS_PATH))
        {
            string settingsStr = FileAccess.GetFileAsString(SETTINGS_PATH);
            Dictionary<string, Variant> settingsDict = (Godot.Collections.Dictionary<string, Variant>)Json.ParseString(settingsStr);
            foreach (string prop in settingsDict.Keys)
            {
                SetUserSetting(prop, settingsDict[prop]);
            }
        }
    }
    public void SaveSettings()
    {
        string settingsStr = Json.Stringify(_userSettings);
        FileAccess settingsSave = FileAccess.Open(SETTINGS_PATH, FileAccess.ModeFlags.Write);
        settingsSave.StoreString(settingsStr);
        settingsSave.Close();
    }
    public void Setup()
    {
        LoadSettings();
        HasSetup = true;
    }
}