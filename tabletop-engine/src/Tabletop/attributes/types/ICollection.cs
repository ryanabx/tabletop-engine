using System.Collections.Generic;
namespace Tabletop.Attributes.Types;

public interface ICollection
{
	public List<ICollectable> Collectables
	{
		get;
		set;
	}
}