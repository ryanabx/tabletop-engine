using Godot;
using Godot.Collections;
using System.IO;
using System.IO.Compression;
namespace TabletopEngine;
public partial class TabletopGame : RefCounted
{
    public Board GameBoard;
    private Dictionary<string, Texture2D> _includeImages;
    private RefCounted UserScript;
    public string Name = "";
    public void Initialize()
    {
        UserScript.Set("board", GameBoard);
        UserScript.Call("initialize");
    }
    public void GameStart()
    {
        UserScript.Call("game_start");
    }
    public string[] GetActions()
    {
        return (string[])UserScript.Call("get_actions");
    }
    public bool RunAction(string action)
    {
        return (bool)UserScript.Call("run_action", action);
    }
    public bool CanStack(Selectable from, Selectable to)
    {
        return (bool)UserScript.Call("can_stack", from, to);
    }
    public bool CanTakePieceOff(GameCollection collection)
    {
        return (bool)UserScript.Call("can_take_piece_off", collection);
    }
    public bool CanHighlight(Selectable highlighted, Selectable selected)
    {
        return (bool)UserScript.Call("can_highlight", highlighted, selected);
    }
    // For use by config loader and game
    private void SetImages(Dictionary<string, byte[]> imagesBytes)
    {
        _includeImages = new Dictionary<string, Texture2D>();
        foreach (string image in imagesBytes.Keys)
        {
            Image newImg = new();
            newImg.LoadWebpFromBuffer(imagesBytes[image]);
            _includeImages[image] = ImageTexture.CreateFromImage(newImg);
        }
    }
    public Texture2D GetImage(string path)
    {
        if (!_includeImages.ContainsKey(path))
        {
            return null;
        }
        return _includeImages[path];
    }
    public static TabletopGame ImportConfig(byte[] data)
    {
        using var stream = new MemoryStream();
        stream.Write(data, 0, data.Length);
        byte[] dataDecompressed = DecompressStreamToBytes(stream);
        Dictionary config = (Dictionary)GD.BytesToVar(dataDecompressed);
        return GetTabletopGame(config);
    }
    public static TabletopGame GetTabletopGame(Dictionary config)
    {
        GDScript script = new()
        {
            SourceCode = (string)config["script"]
        };
        script.Reload();
        TabletopGame obj = new()
        {
            UserScript = new RefCounted()
        };
        obj.UserScript.SetScript(script);
        obj.Name = (string)config["name"];
        obj.SetImages((Dictionary<string, byte[]>)config["include_images"]);
        return obj;
    }
    public static byte[] ExportConfig(string sourceCode, Dictionary<string, byte[]> images, string gameName)
    {
        Dictionary config = new()
        {
            ["name"] = gameName,
            ["include_images"] = images,
            ["script"] = sourceCode
        };
        using var stream = new MemoryStream();
        CompressBytesToStream(stream, GD.VarToBytes(config));
        return stream.ToArray();
    }

    private static void CompressBytesToStream(Stream stream, byte[] messageBytes)
    {
        using var compressor = new GZipStream(stream, CompressionLevel.SmallestSize, leaveOpen: true);
        compressor.Write(messageBytes, 0, messageBytes.Length);
    }

    private static byte[] DecompressStreamToBytes(Stream stream)
    {
        stream.Position = 0;
        int bufferSize = 10000000;
        byte[] decompressedBytes = new byte[bufferSize];
        using var decompressor = new GZipStream(stream, CompressionMode.Decompress);
        int length = decompressor.Read(decompressedBytes, 0, bufferSize);
        return decompressedBytes[..length];
    }
}