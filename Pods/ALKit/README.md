ALKit
===

Easy to use AutoLayout wrapper around `NSLayoutConstraints`.

Requirements
---

- Swift 4.2+
- iOS 8.0+
- tvOS 9.0+

Install
----

#### CocoaPods

``` ruby
use_frameworks!
pod 'ALKit'
```

### Manual

Copy the `ALKit` folder into your project

Usage
----

### Init

Create `UIView` instances from either storyboard or programmatically.
Don't forget to set `view.translatesAutoresizingMaskIntoConstraints = false` if you are creating them programmatically.

### Wraper

The main function of all kit.
Wraps `addConstraint:` method of autolayout.

``` swift
func pin(
  inView inView: UIView? = nil,
  edge: NSLayoutAttribute,
  toEdge: NSLayoutAttribute,
  ofView: UIView?,
  withInset: CGFloat = 0) {
  let view = inView ?? ofView ?? self
  view.addConstraint(NSLayoutConstraint(
      item: self,
      attribute: edge,
      relatedBy: .Equal,
      toItem: ofView,
      attribute: toEdge,
      multiplier: 1,
      constant: withInset))
}
```

#### Example

``` swift
box.fill(toView: view)

blue.pinTop(toView: box, withInset: 10)
blue.fillHorizontal(toView: box, withInset: 10)
blue.pinHeight(90)

red.pinBottom(toView: box, withInset: 10)
red.fillHorizontal(toView: box, withInset: 10)
red.pinHeight(90)

yellow.pinToTop(ofView: red, withOffset: 10)
yellow.pinCenterX(toView: red)
yellow.pinSize(width: 50, height: 50)
```

That would be look like this:

![alt tag](https://github.com/cemolcay/ALKit/blob/master/demo.png?raw=true)

