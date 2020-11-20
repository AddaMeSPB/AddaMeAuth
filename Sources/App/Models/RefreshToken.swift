//
//  RefreshToken.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import JWT
import MongoKitten
import AddaAPIGatewayModels

struct RefreshToken: JWTPayload {
    var id: ObjectId?
    var iat: Int
    var exp: Int

  init(user: User.Response, expiration: Int = 31536000) { // Expiration 1 year
        let now = Date().timeIntervalSince1970
        self.id = user.id
        self.iat = Int(now)
        self.exp = Int(now) + expiration
    }

    func verify(using signer: JWTSigner) throws {
        let expiration = Date(timeIntervalSince1970: TimeInterval(self.exp))
        try ExpirationClaim(value: expiration).verifyNotExpired()
    }
}

