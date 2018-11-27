//
//  MIDIPianoRollMeasureLineLayer.swift
//  MIDIPianoRollView
//
//  Created by cem.olcay on 27/11/2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit
import MusicTheorySwift

/// Vertical line layer with measure beat text for each beat of the measure on the `MIDIPianoRollView`.
public class MIDIPianoRollMeasureLineLayer: CALayer {
  /// Measure text layer.
  public var beatTextLayer = CATextLayer()
  /// Vertical line layer.
  public var beatLineLayer = CALayer()
  /// Position on piano roll.
  public var pianoRollPosition: MIDIPianoRollPosition = .zero

  /// Property for controlling beat text rendering.
  public var showsBeatText: Bool = true {
    didSet {
      beatTextLayer.isHidden = !showsBeatText
    }
  }

  /// Initilizes the line with the default zero values.
  override init() {
    super.init()
    commonInit()
  }

  /// Initilizes with a layer.
  ///
  /// - Parameter layer: Layer.
  public override init(layer: Any) {
    super.init(layer: layer)
    commonInit()
  }

  /// Initilizes with a coder.
  ///
  /// - Parameter aDecoder: Coder.
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  /// Default initilizer.
  private func commonInit() {
    masksToBounds = false
    beatTextLayer.masksToBounds = false
    beatTextLayer.foregroundColor = UIColor.black.cgColor
    beatTextLayer.contentsScale = UIScreen.main.scale
    addSublayer(beatTextLayer)
    addSublayer(beatLineLayer)
  }
}
