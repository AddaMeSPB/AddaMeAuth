//
//  RefreshTokenResponse.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor

struct RefreshTokenResponse: Content {
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
