//
//  VerifySMSInput.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor

struct VerifySMSInput: Content {
    let phoneNumber: String
    let code: String

    enum CodingKeys: String, CodingKey {
        case code
        case phoneNumber = "phone_number"
    }
}
