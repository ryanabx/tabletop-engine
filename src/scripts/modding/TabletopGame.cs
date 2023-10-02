using Godot;
using Godot.Collections;
public abstract partial class TabletopGame : RefCounted
{
    public Board GameBoard;
    private Dictionary<string, Texture2D> _includeImages;
    public string Name = "";
    // MUST IMPLEMENT
    public abstract void Initialize();
    public abstract void GameStart();
    // OPTIONAL OVERRIDE
    public virtual string[] GetActions()
    {
        return new string[0];
    }
    public virtual bool RunAction()
    {
        return false;
    }
    public virtual bool CanStack(Selectable from, Selectable to)
    {
        return true;
    }
    public virtual bool CanTakePieceOff(GameCollection collection)
    {
        return true;
    }
    public virtual bool CanHighlight(Selectable highlighted, Selectable selected)
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
}