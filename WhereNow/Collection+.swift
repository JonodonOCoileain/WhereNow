//
//  Collection+.swift
//  WhereNow
//
//  Created by Jon on 11/30/24.
//


extension Collection {
  func enumeratedArray() -> Array<(offset: Int, element: Self.Element)> {
    return Array(self.enumerated())
  }
}