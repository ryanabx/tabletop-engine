using Godot;
using Godot.Collections;

namespace Tabletop.Attributes.Properties;

public interface ISyncable
{
	public abstract Dictionary<string, Variant> DeltasToDict();
	public abstract Dictionary<string, Variant> DataToDict();
	public abstract void PopulateFromDict(Dictionary<string, Variant> data);
}