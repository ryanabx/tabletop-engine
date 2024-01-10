using Godot;
using Godot.Collections;
using TabletopEngine.Tabletop.Objects;

namespace TabletopEngine.Tabletop.Attributes;

public interface ISyncable
{
	public abstract Dictionary<string, Variant> DeltasToDict();
	public abstract Dictionary<string, Variant> DataToDict();
	public abstract void PopulateFromDict(Dictionary<string, Variant> data);
}