using Godot;
namespace TabletopEngine;
public partial class ConfigTools
{
    public static bool SaveConfigToFile(byte[] buffer)
    {
        TabletopGame config = TabletopGame.ImportConfig(buffer);
        DirAccess.MakeDirAbsolute(Global.GetSingleton().CONFIG_REPO);
        string confPath = $"{Global.GetSingleton().CONFIG_REPO}/{config.Name}{Global.GetSingleton().CONFIG_EXTENSION}";
        DirAccess.RemoveAbsolute(confPath);
        FileAccess localCopy = FileAccess.Open(confPath, FileAccess.ModeFlags.Write);
        if (localCopy == default)
        {
            GD.Print(FileAccess.GetOpenError(), ": ", confPath);
            return false;
        }
        localCopy.StoreBuffer(buffer);
        localCopy.Close();
        GD.Print("Done! Sent to ",confPath);
        return true;
    }
    public static bool ConfigExists(string confName)
    {
        return FileAccess.FileExists($"{Global.GetSingleton().CONFIG_REPO}/{confName}{Global.GetSingleton().CONFIG_EXTENSION}");
    }

}