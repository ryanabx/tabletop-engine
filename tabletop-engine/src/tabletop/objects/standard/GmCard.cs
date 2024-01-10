using Godot;
using TabletopEngine.Tabletop.Attributes;
namespace TabletopEngine.Tabletop.Objects.Standard;

public partial class GmCard : GmPiece, IFlippable
{
	private bool _orientation;
	public bool Orientation
	{
		get 
		{
			return _orientation;
		}
		set
		{
			_orientation = value;
			_cardSprite.Texture = value ? _imageUpTexture : _imageDownTexture;
		}
	}
	public void Flip()
	{
		Orientation = !Orientation;
	}
	private Sprite2D _cardSprite;
	private Texture2D _imageUpTexture;
	private Texture2D _imageDownTexture;
	private string _imageUpFname;
	private string _imageDownFname;
	public string ImageUp
	{
		set
		{
			_imageUpFname = value;
			_imageUpTexture = ImageTexture.CreateFromImage(Image.LoadFromFile(value));
		}
		get
		{
			return _imageUpFname;
		}
	}
	public string ImageDown
	{
		set
		{
			_imageDownFname = value;
			_imageDownTexture = ImageTexture.CreateFromImage(Image.LoadFromFile(value));
		}
		get
		{
			return _imageDownFname;
		}
	}
}