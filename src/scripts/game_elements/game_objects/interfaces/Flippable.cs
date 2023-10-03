using Godot;
public interface Flippable
{
    public abstract void Flip();
    public abstract void SetOrientation(bool faceUp);
    public abstract bool GetOrientation();
}