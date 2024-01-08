namespace TabletopEngine.Tabletop.Attributes;

public interface ISelectable : IHasGeometry
{
    public bool Selected
    {
        set;
        get;
    }
}