using Godot;
namespace TabletopEngine.UI.Components;

public partial class GalleryImage : BoxContainer
{
	private Texture2D _texture;
	private string _text;
	public override void _Ready()
	{
		base._Ready();
		GetNode<TextureRect>("Texture").Texture = _texture;
		GetNode<LineEdit>("Text").Text = _text;
	}
	private void SetType(Texture2D image, string text)
	{
		_texture = image;
		_text = text;
	}
	// TODO: Connect this signal to the proper button
	private void OnErasePressed()
	{
		QueueFree();
	}
	// TODO: Connect this signal to the lineedit object
	private void OnTextChanged(string newText)
	{
		_text = newText;
	}
}