using Godot;
using Godot.Collections;
using TabletopEngine.Tabletop.Objects;

namespace TabletopEngine.Tabletop.Attributes;

public interface ISyncable
{
	public abstract Dictionary<string, Variant> SendStateDeltas();
	public abstract void ProcessStateDeltas(Dictionary<string, Variant> deltas);
}