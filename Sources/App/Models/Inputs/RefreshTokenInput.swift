//
//  RefreshTokenInput
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor

struct RefreshTokenInput: Content {
    var refreshToken: String
}

