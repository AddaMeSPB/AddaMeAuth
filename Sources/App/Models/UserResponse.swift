//
//  UserResponse.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten

struct UserSuccessResponse: Content {
    let user: UserResponse
}

struct NewUserInput: Content {
    let firstname: String?
    let lastname: String?
    let phoneNumber: String
}

struct UserResponse: Content {
    let id: ObjectId?
    let firstName, lastName: String?
    let phoneNumber: String
}

protocol AccessTokenStorage: class {
    var access: RefreshResponse { get set }
}

struct RefreshResponse: Content {
    var accessToken: String
    var refreshToken: String
}

final class LoginResponse: Content {
    var access: RefreshResponse
    let user: User.Res

    init(access: RefreshResponse, user: User.Res) {
        self.access = access
        self.user = user
    }
}

