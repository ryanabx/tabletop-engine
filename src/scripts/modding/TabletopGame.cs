using Godot;
using Godot.Collections;
using System.IO;
using System.IO.Compression;
public partial class TabletopGame : RefCounted
{
    public Board GameBoard;
    private Dictionary<string, Texture2D> _includeImages;
    private RefCounted UserScript;
    public string Name = "";
    // MUST IMPLEMENT
    public void Initialize()
    {

    }
    public void GameStart()
    {

    }
    // OPTIONAL OVERRIDE
    public string[] GetActions()
    {
        return new string[0];
    }
    public bool RunAction()
    {
        return false;
    }
    public bool CanStack(Selectable from, Selectable to)
    {
        return true;
    }
    public bool CanTakePieceOff(GameCollection collection)
    {
        return true;
    }
    public bool CanHighlight(Selectable highlighted, Selectable selected)
    {
        return true;
    }
    // For use by config loader and game
    private void SetImages(Dictionary<string, byte[]> imagesBytes)
    {
        _includeImages = new Dictionary<string, Texture2D>();
        foreach (string image in imagesBytes.Keys)
        {
            Image newImg = new Image();
            newImg.LoadWebpFromBuffer(imagesBytes[image]);
            _includeImages.Add(image, ImageTexture.CreateFromImage(newImg));
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
    // TODO: Implement static functions for tabletopgame
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
        GDScript script = new GDScript();
        script.SourceCode = (string)config["script"];
        script.Reload();
        TabletopGame obj = new TabletopGame();
        obj.UserScript = new RefCounted();
        obj.UserScript.SetScript(script);
        obj.Name = (string)config["name"];
        obj.SetImages((Dictionary<string, byte[]>)config["include_images"]);
        return obj;
    }
    public static byte[] ExportConfig(string sourceCode, Dictionary<string, byte[]> images, string gameName)
    {
        Dictionary config = new Dictionary
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