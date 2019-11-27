MIDIPianoRollView
====

Customisable UIScrollView subclass for rendering/editing MIDI notes on a piano roll view.

Demo
----

![alt tag](https://github.com/cemolcay/MIDIPianoRollView/raw/master/demo.gif)

Requirements
----

* iOS 9.0+
* Swift 4.2+
* Xcode 10.0+


Install
----

#### CocoaPods

``` ruby
pod 'MIDIPianoRollView'
```

Usage
----

Create a `MIDIPianoRollView` either from storyboard (subclass from `UIScrollView`) or programmatically.

#### `MIDIPianoRollView.Keys`

- An enum that represents the data source of the piano roll's keys.
- It can be either
	-  A range of `UInt8` MIDI notes like `30...50` (30th note to 50th note)
	-  A `Scale` of notes between specified octave range
	-  Or custom unordered pitches.

#### `MIDIPianoRollView.Bars`

- An enum that represents the bar count on the piano roll.
- It can be either
	- A fixed value by `.fixed(barCount)` 
	- Or `.auto` that auto-calculating bar count by the data source.

#### `MIDIPianoRollNote`

- Set the `notes` data source array in order to pop the notes. 
- It is a `[MIDIPianoRollNote]` array that has the start position, duration, midi note and velocity data for each note. 

#### `MIDIPianoRollPosition`

- This represents both position and duration values for the notes on the piano roll. Contains `bar`, `beat`, `subbeat` and `cent` values.
- Each of them are `Int` and confomrs to `Comparable`, `Equatable`, `Codable` and custom `+` and `-` operatros.
- Each `bar` has a number of `beat`s that the piano roll's `timesingature` has.
- Each `beat` has 4 `subbeat`s.
- Each `subbeat` has 240 `cent`s for fine tuning.

#### `MIDIPianoRollCellView`

- Each cell on the piano roll is a subclass of the `MIDIPianoRollCellView`.
- You can basically create your custom cell view by subclassing it.

#### `MIDIPianoRollRowView`

- Each key view on the right side of the piano roll is a subclass of `MIDIPianoRollRowView`.
- You can create your custom subclass may be with some piano key images and render it on the piano roll.

#### `MIDIPianoRollMeasureView`

- Measure is a custom view with bunch of `CALayer`s that rendering the position texts and guide lines.
- You can set grid line width and colors.
- You can set measure position label font and text colors.
- If you don't want to render measure, then you can set the `isMeasureEnabled` property to false.

#### `MIDIPianoRollView.ZoomLevel`

- Zoom level represents the currently rendering beat value on the piano roll.
- It has a customisable `minZoomLevel` and `maxZoomLevel` range.
- Each zoom level have note rate, for example,   
	- `.halfNotes` means a bar have 2 beats with 2 half notes, 
	- `.quarterNotes` means a bar have 4 beats with 4 quarter notes.
- If `isZoomingEnabled` is set true, then you can horizontally pinch-to-zoom in or out between customisable `minBeatWidth` and `maxBeatWidth` values to set current `beatWidth`. 
- When a `beatWidth` hits the limit, the zoom level advances the next level depending on the zooming in or out. 
- You can disable this behaviour by setting `isZoomingEnabled` property to false.
- The same behavior also controls the row height zooming. If you vertically pinch-to-zoom, then current `rowHeight` will scale between `minRowHeight` and `maxRowHeight` properties.

#### `MIDIPianoRollView.GridLine`

- Contains line properties for grid line styling.
- You can set each line's width, color or dash pattern styling.

#### Editing

- You can enter the cell editing mode by setting `isEditing` property to true.
- When you are in the edit mode, you can not scroll the view but you can pan the cells to move or resize.
- You can enable/disable the multiple editing by setting the `isMultipleEditingEnabled` property to true. 
	- When it's enabled, you can drag your finger to render a multiple selection view to select all cells that under the drag-to-select box.
	- Then you can move or resize the selected cells.
- When editing is done, piano roll will informs its delegate.

#### `MIDIPianoRollViewDelegate`

- Informs the delegate when the cell is edited.
- You can update your `notes` data source in the delegate calls.

``` swift
  func midiPianoRollView(_ midiPianoRollView: MIDIPianoRollView,
                         didMove cellView: MIDIPianoRollCellView,
                         to newPosition: MIDIPianoRollPosition,
                         pitch: UInt8)
```

- Informs delegate about that the cell is moved a new position and/or row. 
- You can use the `pitch` value to determine which row is the cell moved.


``` swift
func midiPianoRollView(_ midiPianoRollView: MIDIPianoRollView,
                         didResize cellView: MIDIPianoRollCellView,
                         to newDuration: MIDIPianoRollPosition)
```

- Informs delegate about that the cell's duration changed.
- Called when cell is resized.

``` swift
func midiPianoRollViewMultipleEditingDraggingView(_ midiPianoRollView: MIDIPianoRollView) -> UIView?
```

- Return a custom UIView if you want to render your custom drag-to-select view.

#### Example Project

- Check out the example project for getting more information about the implementation.


Documentation
----

You can find the documentation [here](https://cemolcay.github.io/MIDIPianoRollView).
