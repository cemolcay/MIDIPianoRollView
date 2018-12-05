//
//  ALKit.swift
//  AutolayoutPlayground
//
//  Created by Cem Olcay on 22/10/15.
//  Copyright © 2015 prototapp. All rights reserved.
//
//  https://www.github.com/cemolcay/ALKit
//

import UIKit

public extension UIEdgeInsets {

  /// Equal insets for all edges.
  public init(inset: CGFloat) {
    self.init()
    top = inset
    bottom = inset
    left = inset
    right = inset
  }
}

public extension UIView{

  /// Auto layout wrapper function to pin a view's edge to another view's edge.
  ///
  /// - Parameters:
  ///   - edge: View's edge is going to be pinned.
  ///   - toEdge: Pinning edge of other view.
  ///   - ofView: The view to be pinned.
  ///   - withInset: Space between pinning edges.
  public func pin(
    edge: NSLayoutConstraint.Attribute,
    toEdge: NSLayoutConstraint.Attribute,
    ofView: UIView?,
    withInset: CGFloat = 0) {
      guard let view = superview else {
        return assertionFailure("view must be added as subview in view hierarchy")
      }
      view.addConstraint(NSLayoutConstraint(
        item: self,
        attribute: edge,
        relatedBy: .equal,
        toItem: ofView,
        attribute: toEdge,
        multiplier: 1,
        constant: withInset))
  }

  // MARK: Pin Super

  /// Pins right edge of view to other view's right edge.
  ///
  /// - Parameters:
  ///   - view: The view going to be pinned.
  ///   - inset: Space between edges.
  public func pinRight(to view: UIView, inset: CGFloat = 0) {
    pin(edge: .right, toEdge: .right, ofView: view, withInset: -inset)
  }

  /// Pins left edge of view to other view's left edge.
  ///
  /// - Parameters:
  ///   - view: The view going to be pinned.
  ///   - inset: Space between edges.
  public func pinLeft(to view: UIView, inset: CGFloat = 0) {
    pin(edge: .left, toEdge: .left, ofView: view, withInset: inset)
  }

  /// Pins top edge of view to other view's top edge.
  ///
  /// - Parameters:
  ///   - view: The view going to be pinned.
  ///   - inset: Space between edges.
  public func pinTop(to view: UIView, inset: CGFloat = 0) {
    pin(edge: .top, toEdge: .top, ofView: view, withInset: inset)
  }

  /// Pins bottom edge of view to other view's bottom edge.
  ///
  /// - Parameters:
  ///   - view: The view going to be pinned.
  ///   - inset: Space between edges.
  public func pinBottom(to view: UIView, inset: CGFloat = 0) {
    pin(edge: .bottom, toEdge: .bottom, ofView: view, withInset: -inset)
  }

  // MARK: Pin To Another View In Super

  /// Pins left edge of view to other view's right edge.
  ///
  /// - Parameters:
  ///   - view: The view going to be pinned.
  ///   - inset: Space between edges.
  public func pinToRight(of view: UIView, offset: CGFloat = 0) {
    pin(edge: .left, toEdge: .right, ofView: view, withInset: offset)
  }

  /// Pins right edge of view to other view's left edge.
  ///
  /// - Parameters:
  ///   - view: The view going to be pinned.
  ///   - inset: Space between edges.
  public func pinToLeft(of view: UIView, offset: CGFloat = 0) {
    pin(edge: .right, toEdge: .left, ofView: view, withInset: -offset)
  }

  /// Pins bottom edge of view to other view's top edge.
  ///
  /// - Parameters:
  ///   - view: The view going to be pinned.
  ///   - inset: Space between edges.
  public func pinToTop(of view: UIView, offset: CGFloat = 0) {
    pin(edge: .bottom, toEdge: .top, ofView: view, withInset: -offset)
  }

  /// Pins top edge of view to other view's bottom edge.
  ///
  /// - Parameters:
  ///   - view: The view going to be pinned.
  ///   - inset: Space between edges.
  public func pinToBottom(of view: UIView, offset: CGFloat = 0) {
    pin(edge: .top, toEdge: .bottom, ofView: view, withInset: offset)
  }

  // MARK: Fill In Super

  /// Pins all edges of the view to other view's edges with insets.
  ///
  /// - Parameters:
  ///   - view: The view is going to be pinned.
  ///   - insets: Spaces between edges.
  public func fill(to view: UIView, insets: UIEdgeInsets = .zero) {
    pinLeft(to: view, inset: insets.left)
    pinRight(to: view, inset: insets.right)
    pinTop(to: view, inset: insets.top)
    pinBottom(to: view, inset: insets.bottom)
  }

  /// Pins left and right edges of the view to other view's left and right edges with equal insets.
  ///
  /// - Parameters:
  ///   - view: The view is going to be pinned.
  ///   - insets: Equal insets between left and right edges.
  public func fillHorizontal(to view: UIView, insets: CGFloat = 0) {
    pinRight(to: view, inset: insets)
    pinLeft(to: view, inset: insets)
  }

  /// Pins top and bottom edges of the view to other view's top and bottom edges with equal insets.
  ///
  /// - Parameters:
  ///   - view: The view is going to be pinned.
  ///   - insets: Equal insets between top and bottom edges.
  public func fillVertical(to view: UIView, insets: CGFloat = 0) {
    pinTop(to: view, inset: insets)
    pinBottom(to: view, inset: insets)
  }

  // MARK: Size

  /// Pins width and height of the view to constant width and height values.
  ///
  /// - Parameters:
  ///   - width: Width constant.
  ///   - height: Height constant.
  public func pinSize(width: CGFloat, height: CGFloat) {
    pinWidth(width: width)
    pinHeight(height: height)
  }

  /// Pins width of the view to constant width value.
  ///
  /// - Parameter width: Width constant.
  public func pinWidth(width: CGFloat) {
    pin(edge: .width, toEdge: .notAnAttribute, ofView: nil, withInset: width)
  }

  /// Pins height of the view to constant width value.
  ///
  /// - Parameter height: Height constant.
  public func pinHeight(height: CGFloat) {
    pin(edge: .height, toEdge: .notAnAttribute, ofView: nil, withInset: height)
  }

  // MARK: Center

  /// Pins center of the view to other view's center.
  ///
  /// - Parameter view: The view is going to be pinned.
  public func pinCenter(to view: UIView) {
    pinCenterX(to: view)
    pinCenterY(to: view)
  }

  /// Pins horizontally center the view to other view's center.
  ///
  /// - Parameter view: The view is going to be pinned.
  public func pinCenterX(to view: UIView) {
    pin(edge: .centerX, toEdge: .centerX, ofView: view)
  }

  /// Pins vertically center of the view to other view's center.
  ///
  /// - Parameter view: The view is going to be pinned.
  public func pinCenterY(to view: UIView) {
    pin(edge: .centerY, toEdge: .centerY, ofView: view)
  }
}
