//
//  RefreshTokenInput
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor

struct RefreshTokenInput: Content {
    var refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

