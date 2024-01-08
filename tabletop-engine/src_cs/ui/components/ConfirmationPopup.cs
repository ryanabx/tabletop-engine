using Godot;
namespace TabletopEngine.UI.Components;

public partial class ConfirmationPopup : InfoPopup
{
    // TODO: Connect this signal to cancel button
    private void OnCancelButtonPressed()
    {
        Hide();
    }

}