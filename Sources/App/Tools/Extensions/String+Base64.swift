//
//  File.swift
//  
//
//  Created by Alif on 11/7/20.
//

import Foundation

extension String {

    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

