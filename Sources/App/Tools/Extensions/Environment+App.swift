//
//  Environment+App.swift
//  
//
//  Created by Alif on 11/7/20.
//

import Vapor

extension Environment {

    // For Apple Login
    static let siwaId = Self.get("SIWA_ID")!
    static let siwaAppId = Self.get("SIWA_APP_ID")!
    static let siwaRedirectUrl = Self.get("SIWA_REDIRECT_URL")!
    static let siwaTeamId = Self.get("SIWA_TEAM_ID")!
    static let siwaJWKId = Self.get("SIWA_JWK_ID")!
    static let siwaKey = Self.get("SIWA_KEY")!.base64Decoded()!

//    static let apnsKeyId = Self.get("APNS_KEY_ID")!
//    static let apnsTeamId = Self.get("APNS_TEAM_ID")!
//    static let apnsTopic = Self.get("APNS_TOPIC")!
//    static let apnsKey = Self.get("APNS_KEY")!.base64Decoded()!


    // HOSTS
    static let eventHost = Self.get("EVENTS_HOST")
}