//
//  AuthController.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import Fluent
import MongoKitten
import Twilio
import JWT
import AddaAPIGatewayModels
import MongoKitten

extension AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("login", use: beginSMSVerification)
        auth.post("verify_sms", use: validateVerificationCode)
        auth.post("refreshToken", use: refreshAccessToken)
    }
}

final class AuthController {
    
    private func beginSMSVerification(_ req: Request) throws -> EventLoopFuture<SendUserVerificationResponse> {
        
        let verification = try req.content.decode(LoginInput.self)
        
        let phoneNumber = verification.phoneNumber.removingInvalidCharacters
        let code = String.randomDigits(ofLength: 6)
        let message = "Hello there! Your verification code is \(code)"
        
        guard let SENDER_NUMBER = Environment.get("SENDER_NUMBER") else {
            fatalError("No value was found at the given public key environment 'SENDER_NUMBER'")
        }
        let sms = OutgoingSMS(body: message, from: SENDER_NUMBER, to: phoneNumber)
        
        req.logger.info("SMS is \(message)")
        
        switch req.application.environment {
        case .production:
            return req.application.twilio.send(sms)
                .flatMap { success -> EventLoopFuture<SMSVerificationAttempt> in
                    
                    guard success.status != .badRequest else {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "SMS could not be sent to \(phoneNumber)"))
                    }
                    
                    let smsAttempt = SMSVerificationAttempt(
                        code: code,
                        expiresAt: Date().addingTimeInterval(5.0 * 60.0),
                        phoneNumber: phoneNumber
                    )
                    
                    return smsAttempt.save(on: req.db).map { smsAttempt }
                }
                .map { attempt in
                    let attemptId = try! attempt.requireID()
                    return SendUserVerificationResponse(phoneNumber: phoneNumber, attemptId: attemptId)
                }.hop(to: req.eventLoop)
            
        case .development:
            
            return req.application.twilio.send(sms)
                .flatMap { success -> EventLoopFuture<SMSVerificationAttempt> in
                    
                    guard success.status != .badRequest else {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "SMS could not be sent to \(phoneNumber)"))
                    }
                    
                    let smsAttempt = SMSVerificationAttempt(
                        code: "336699",
                        expiresAt: Date().addingTimeInterval(5.0 * 60.0),
                        phoneNumber: phoneNumber
                    )
                    
                    print("code: \(336699)")
                    
                    return smsAttempt.save(on: req.db).map { smsAttempt }
                }
                .map { attempt in
                    let attemptId = try! attempt.requireID()
                    return SendUserVerificationResponse(phoneNumber: phoneNumber, attemptId: attemptId)
                }.hop(to: req.eventLoop)
            
            
        default:
            return req.application.twilio.send(sms)
                .flatMap { success -> EventLoopFuture<SMSVerificationAttempt> in
                    
                    guard success.status != .badRequest else {
                        return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "SMS could not be sent to \(phoneNumber)"))
                    }
                    
                    let smsAttempt = SMSVerificationAttempt(
                        code: "336699",
                        expiresAt: Date().addingTimeInterval(5.0 * 60.0),
                        phoneNumber: phoneNumber
                    )
                    
                    print("code: \(336699)")
                    
                    return smsAttempt.save(on: req.db).map { smsAttempt }
                }
                .map { attempt in
                    let attemptId = try! attempt.requireID()
                    return SendUserVerificationResponse(phoneNumber: phoneNumber, attemptId: attemptId)
                }.hop(to: req.eventLoop)
        }
    }
    
    private func validateVerificationCode(_ req: Request) throws -> EventLoopFuture<LoginResponse> {
        // 1
        let payload = try req.content.decode(UserVerificationPayload.self)
        let code = payload.code
        let attemptId = payload.attemptId
        let phoneNumber = payload.phoneNumber.removingInvalidCharacters
        
        return SMSVerificationAttempt.query(on: req.db)
            .filter(\.$code == code)
            .filter(\.$phoneNumber == phoneNumber)
            .filter(\.$id == attemptId)
            .first()
            .flatMap { attempt -> EventLoopFuture<LoginResponse> in
                
                guard let expirationDate = attempt?.expiresAt else {
                    return req.eventLoop.future(
                        LoginResponse(user: nil, status: "invalid-code", access: nil)
                    )
                }
                
                guard expirationDate > Date() else {
                    return req.eventLoop.future(
                        LoginResponse(user: nil, status: "expired-code", access: nil)
                    )
                }
                
                return self.verificationResponseForValidUser(with: phoneNumber, on: req)
            }
    }
    
    private func verificationResponseForValidUser(
        with phoneNumber: String,
        on req: Request) -> EventLoopFuture<LoginResponse> {
        
        return User.query(on: req.db)
            .filter(\.$phoneNumber == phoneNumber)
            .first()
            .flatMap { queriedUser -> EventLoopFuture<User> in
                if let existingUser = queriedUser {
                    return req.eventLoop.future(existingUser)
                }
                
                let user = User.init(phoneNumber)
                return user.save(on: req.db).map { user }
            }
            .flatMap { user -> EventLoopFuture<LoginResponse> in
                
                do {
                    let userPayload = Payload(id: user.id!, phoneNumber: user.phoneNumber)
                    let accessToken = try req.application.jwt.signers.sign(userPayload)
                    let refreshPayload = RefreshToken(user: user)
                    let refreshToken = try req.application.jwt.signers.sign(refreshPayload)
                    // let userResponse = user.response
                    //_ = smsVerification.delete(on: req.mongoDB)
                    let access = RefreshResponse(accessToken: accessToken, refreshToken: refreshToken)
                    return req.eventLoop.future(user).transform(
                        to: LoginResponse(user: user, status: "ok", access: access)
                    )
                }
                catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }
    }
    
    private func refreshAccessToken(_ req: Request) throws -> EventLoopFuture<RefreshTokenResponse>  {
        let data = try req.content.decode(RefreshTokenInput.self)
        let refreshToken = data.refreshToken
        let jwtPayload: RefreshToken = try req.application
            .jwt.signers.verify(refreshToken, as: RefreshToken.self)
        
        guard let userID = jwtPayload.id else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound, reason: "User id missing from RefreshToken"))
        }
        
        return User.query(on: req.db)
            .filter(\.$id == userID)
            .first()
            .unwrap(or: Abort(.notFound, reason: "User not found by id: \(userID) for refresh token"))
            .map { (user : User) -> RefreshTokenResponse in
                let payload = Payload(id: user.id!, phoneNumber: user.phoneNumber)
                var payloadString = ""
                
                let refreshPayload = RefreshToken(user: user)
                var refreshToken = ""
                
                do {
                    refreshToken = try req.application.jwt.signers.sign(refreshPayload)
                    payloadString = try req.application.jwt.signers.sign(payload)
                } catch {}
                
                return RefreshTokenResponse(accessToken: payloadString, refreshToken: refreshToken)
            }
        
    }
    
}

extension AuthController {
    struct LoginInput: Codable, Content {
        let phoneNumber: String
    }
    
    struct SendUserVerificationResponse: Content {
        let phoneNumber: String
        let attemptId: ObjectId
    }
    
    struct UserVerificationPayload: Content {
        let attemptId: ObjectId
        let phoneNumber: String
        let code: String
    }
    
}

extension Model {
    public func save(on req: Request) -> EventLoopFuture<Self> {
        save(on: req.db).map { self }
    }
}
