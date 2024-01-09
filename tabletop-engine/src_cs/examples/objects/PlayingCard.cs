using Godot;
using TabletopEngine.Tabletop.Objects;
using TabletopEngine.Tabletop.Objects.Standard;
namespace TabletopEngine.Examples.Objects;

public partial class PlayingCard : GmCard
{
	public enum Suit
	{
		Club,
		Diamond,
		Heart,
		Spade
	}
	public enum Rank
	{
		Ace,
		Two,
		Three,
		Four,
		Five,
		Six,
		Seven,
		Eight,
		Nine,
		Ten,
		Jack,
		Queen,
		King
	}
	private Rank _rank;
	public Rank CardRank
	{
		get { return _rank; }
		set { _rank = value; }
	}
	private Suit _suit;
	public Suit CardSuit
	{
		get { return _suit; }
		set { _suit = value; }
	}
	
}