#
#  Be sure to run `pod spec lint MIDIPianoRollView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "MIDIPianoRollView"
  spec.version      = "0.0.1"
  spec.summary      = "Customisable UIScrollView subclass for rendering/editing MIDI notes on a piano roll view."
  spec.swift_version = "4.2"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
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
-   A range of `UInt8` MIDI notes like `30...50` (30th note to 50th note)
-  A `Scale` of notes between specified octave range
-  Or custom unordered pitches.

#### `MIDIPianoRollView.Bars`

- An enum that represents the bar count on the piano roll.
- It can be either
- A fixed value by `.fixed(barCount)`
- Or `.auto` that auto-caluclating bar count by the data source.

#### `MIDIPianoRollNote`

- Set the `notes` data source array in order to pop the notes.
- It is a `[MIDIPianoRollNote]` array that has the start position, duration, midi note and velocity data for each note.

#### `MIDIPianoRollPosition`

- This represents the both position and duration values for the notes on the piano roll. Contains `bar`, `beat`, `subbeat` and `cent` values.
- Each of them are `Int` and confomrs to `Comparable`, `Equatable`, `Codable` and custom `+` and `-` operatros.
- Each `bar` has a number of `beat`s that the piano roll's `timesingature` has.
- Each `beat` has 4 `subbeat`s.
- Each `subbeat` has 240 `cent`s for fine tuning.

#### `MIDIPianoRollCellView`

- Each cell on the piano roll is a subclass of the `MIDIPianoRollCellView`.
- You can basically create your custom cell view by subclassing it.

#### `MIDIPianoRollRowView`

- Each key view on the right side of the piano roll is a subclass of `MIDIPianoRollRowView`.
- You can create your custom sublass may be with some piano key images and render it on the piano roll.

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
                   DESC

  spec.homepage     = "https://github.com/cemolcay/MIDIPianoRollView"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See https://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  spec.license      = "MIT"
  # spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.author             = { "cemolcay" => "ccemolcay@gmail.com" }
  # Or just: spec.author    = "cemolcay"
  # spec.authors            = { "cemolcay" => "ccemolcay@gmail.com" }
  # spec.social_media_url   = "https://twitter.com/cem_olcay"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # spec.platform     = :ios
  spec.platform     = :ios, "9.0"

  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.source       = { :git => "https://github.com/cemolcay/MIDIPianoRollView.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  spec.source_files  = "MIDIPianoRollView/Source/*.swift"
  # spec.exclude_files = "Classes/Exclude"

  # spec.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # spec.resource  = "icon.png"
  # spec.resources = "Resources/*.png"

  # spec.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"

  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # spec.dependency "JSONKit", "~> 1.4"

  spec.dependency "MusicTheorySwift"

end
