//
//  VerifySMSInput.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten

struct VerifySMSInput: Content {
    let phoneNumber: String
    let code: String
    let attemptId: ObjectId
}
