//
//  String+extension.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Foundation

private let allowedCharacterSet: CharacterSet = {
  var set = CharacterSet.decimalDigits
  set.insert("+")
  return set
}()

extension String {
    static func randomDigits(ofLength length: Int) -> String {
      guard length > 0 else {
        fatalError("randomDigits must receive length > 0")
      }

      var result = ""
      while result.count < length {
        result.append(String(describing: Int.random(in: 0...9)))
      }

      return result
    }

    var removingInvalidCharacters: String {
      return String(unicodeScalars.filter { allowedCharacterSet.contains($0) })
    }
}
