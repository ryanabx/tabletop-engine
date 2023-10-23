## Game Objects
* GameObject
  * Collection
    * Deck implements Flippable
    * Hand
  * Piece
    * Flat implements Flippable

## Traits

* Selectable
* Flippable


> Idea: Allow custom implementations of GameObject from users

Rework GameObject to be extensible, create templates of GameObject with certain Traits

Trait Ideas:

* Collection
* Flippable (Flat)
* HasShape
  * Selectable
  * Interactable? Define interactions for object in context menu, works for flippable too

[] Timer Object

* Signal on_timer_timeout

[] Dice Object (Modifiable Number of Sides)

* Signal on_result

[] Counter Object (Modifiable Max and Min)

* Signal on_changed

Make use of signals to hook methods with these objects.

GameObject ensures property updates and that's it.

TabletopGame.get_custom_types() -> Array[GDScript] (Returns custom classes from the user's game and adds them to the list of existing types for reference)

GameObject constructor takes in property values and assigns them to members, as well as handling RPCs for multiplayer. Adds the object to the board specified if the parameter is not null.