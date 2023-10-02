using Godot;
using Godot.Collections;
public partial class Global
{
    public static bool HasSetup = false;
    public static readonly string[] SPLASHES = {
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
    public const float GRAB_THRESHOLD = 40.0f;
    public static readonly Dictionary<string, Variant> ICE_SERVERS = new Dictionary<string, Variant>
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

    public static int[] LoadThisGame = new int[0];
    public static int SafeMarginLeft = 0;
    public static int SafeMarginTop = 0;
    public static int SafeMarginRight = 0;
    public static int SafeMarginBottom = 0;
    public const float TRANSITION_TIME_IN = 0.125f;
    public const float TRANSITION_TIME_OUT = 0.125f;
    public const float TRANSITION_TIME_WAIT = 0.1f;
    // FILE PATHS
    public const string CONFIG_REPO = "user://configs";
    public const string DEFAULT_CONFIG_REPO = "res://configs";
    public const string CONFIG_EXTENSION = ".tbt";
    public const string SETTINGS_PATH = "user://settings.json";
    // PLATFORMS
    static bool IsDesktopPlatform()
    {
#if GODOT_PC
        return true;
#else
        return false;
#endif
    }
    static bool IsWebPlatform()
    {
#if GODOT_WEB
        return true;
#else
        return false;
#endif
    }
    static bool IsMobilePlatform()
    {
#if GODOT_MOBILE
        return true;
#else
        return false;
#endif
    }
    public static readonly Dictionary<string, Variant> DEFAULT_USER_SETTINGS = new Dictionary<string, Variant>
    {
        ["fullscreen"] = false,
        ["default_tap_mode"] = Global.IsMobilePlatform() ? (int)Board.TouchModeType.TAP : (int)Board.TouchModeType.DRAG,
        ["signaling_server"] = "wss://obf-server-signaling.onrender.com",
        ["ui_scale"] = 5.0f
    };
    private static Dictionary<string, Variant> _userSettings = new Dictionary<string, Variant>();
    public static void SetUserSetting(string setting, Variant value)
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
                _userSettings.Add(setting, value);
                break;
            case "ui_scale":
                ThemeDB.GetProjectTheme().DefaultBaseScale = Mathf.Clamp((float)value, 0.25f, 8.0f);
                ThemeDB.GetProjectTheme().DefaultFontSize = Mathf.Clamp((int)value, 2, 64);
                _userSettings.Add(setting, (Variant)(Mathf.Clamp((float)value, 0.25f, 8.0f)));
                break;
            default:
                _userSettings.Add(setting, value);
                break;
        }
        SaveSettings();
    }
    public static void LoadSettings()
    {
        if (FileAccess.FileExists(Global.SETTINGS_PATH))
        {
            string settingsStr = FileAccess.GetFileAsString(Global.SETTINGS_PATH);
            Dictionary<string, Variant> settingsDict = (Godot.Collections.Dictionary<string, Variant>)Json.ParseString(settingsStr);
            foreach (string prop in settingsDict.Keys)
            {
                SetUserSetting(prop, settingsDict[prop]);
            }
        }
    }
    public static void SaveSettings()
    {
        string settingsStr = Json.Stringify(_userSettings);
        FileAccess settingsSave = FileAccess.Open(Global.SETTINGS_PATH, FileAccess.ModeFlags.Write);
        settingsSave.StoreString(settingsStr);
        settingsSave.Close();
    }
    public static void Setup()
    {
        LoadSettings();
        HasSetup = true;
    }
}