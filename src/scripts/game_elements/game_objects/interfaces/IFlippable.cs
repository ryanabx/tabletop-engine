using Godot;
namespace TabletopEngine;
public interface IFlippable
{
    public abstract void Flip();
    public abstract void SetOrientation(bool faceUp);
    public abstract bool GetOrientation();
}