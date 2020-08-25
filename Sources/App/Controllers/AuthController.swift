//
//  AuthController.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten
import Twilio
import JWT

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
        let code = 336699
        let message = "Hello there! Your verification code is \(code)"

        guard let SENDER_NUMBER = Environment.get("SENDER_NUMBER") else {
            fatalError("No value was found at the given public key environment 'SENDER_NUMBER'")
        }
        let sms = OutgoingSMS(body: message, from: SENDER_NUMBER, to: phoneNumber)

        req.logger.info("SMS is \(message)")

        let smsAttempt = SMSVerification(
            id: ObjectId(),
            code: "\(code)",
            expiresAt: Date().addingTimeInterval(5.0 * 60.0),
            phoneNumber: phoneNumber
        )

        switch req.application.environment {
        case .production:
            return req.mongoDB[SMSVerification.schema].insertEncoded(smsAttempt).map{_ in smsAttempt}
                .flatMapThrowing { attempt in
                    let attemptId = attempt.id
                    return SendUserVerificationResponse(
                        phoneNumber: phoneNumber, attemptId: attemptId
                    )
                }.hop(to: req.eventLoop)

        case .development:
            return req.application.twilio.send(sms).flatMap { success -> EventLoopFuture<SMSVerification> in

                guard success.status != .badRequest else {
                    return req.eventLoop.makeFailedFuture(Abort(success.status))
                }

                let smsAttempt = SMSVerification(
                    id: ObjectId(),
                    code: "\(code)",
                    expiresAt: Date().addingTimeInterval(5.0 * 60.0),
                    phoneNumber: phoneNumber
                )

                print("code: \(code)")
                
                return req.mongoDB[SMSVerification.schema].insertEncoded(smsAttempt).map{_ in smsAttempt}
            }
            .flatMapThrowing { attempt in
                let attemptId = attempt.id
                return SendUserVerificationResponse(
                    phoneNumber: phoneNumber, attemptId: attemptId
                )
            }.hop(to: req.eventLoop)


        default:
            return req.application.twilio.send(sms).flatMap { success -> EventLoopFuture<SMSVerification> in

                guard success.status != .badRequest else {
                    return req.eventLoop.makeFailedFuture(Abort(success.status))
                }

                let smsAttempt = SMSVerification(
                    id: ObjectId(),
                    code: "\(code)",
                    expiresAt: Date().addingTimeInterval(5.0 * 60.0),
                    phoneNumber: phoneNumber
                )

                return req.mongoDB[SMSVerification.schema].insertEncoded(smsAttempt).map{_ in smsAttempt}
            }
            .flatMapThrowing { attempt in
                let attemptId = attempt.id
                return SendUserVerificationResponse(
                    phoneNumber: phoneNumber, attemptId: attemptId
                )
            }.hop(to: req.eventLoop)        }
    }

    private func validateVerificationCode(_ req: Request) throws -> EventLoopFuture<LoginResponse> {

        let data = try req.content.decode(VerifySMSInput.self)
        let code = data.code
        let phoneNumber = data.phoneNumber.removingInvalidCharacters

        // TODO Verify implementation of .unwrap(or: Abort(.notFound) ) works
        return req.mongoDB[SMSVerification.schema].findOne(["code": code, "phone_number": phoneNumber])
            .flatMapThrowing({ (document : Document?) -> SMSVerification in
                if (document != nil) {
                    return try! BSONDecoder().decode(SMSVerification.self, from: document!)
                } else {
                    throw Abort(.notFound)
                }
            })
            .flatMap { (smsVerification : SMSVerification) -> EventLoopFuture<LoginResponse> in

                guard let expirationDate = smsVerification.expiresAt else {
                    return req.eventLoop.makeFailedFuture(
                        Abort(.noContent, reason: "Missing expiresAt field")
                    )
                }

                guard Date() < expirationDate else {
                    return req.eventLoop.makeFailedFuture(Abort(.unavailableForLegalReasons, reason: "Your verification code is expired"))
                }

                return  self.verificationResponseForValidUser(with: smsVerification, on: req)
            }
    }

    private func verificationResponseForValidUser(with smsVerification: SMSVerification, on req: Request) -> EventLoopFuture<LoginResponse> {

        return req.mongoDB[User.schema].findOne(["phone_number": smsVerification.phoneNumber])
            .map { (document : Document?) -> User? in
                if (document != nil) {
                    return try! BSONDecoder().decode(User.self, from: document!)
                } else {
                    return nil
                }
            }
            .flatMap { (user : User?) -> EventLoopFuture<User> in
                if user != nil {
                    return req.eventLoop.future(user!)
                } else {
                    let createAndUpdate = Date()
                    let newUser = User(firstName: user?.firstName, lastName: user?.lastName, phoneNumber: smsVerification.phoneNumber, email: user?.email, contactIds: user?.contactIds, deviceIds: user?.deviceIds, createdAt: createAndUpdate, updatedAt: createAndUpdate, deletedAt: nil)
                    return req.mongoDB[User.schema]
                        .insertEncoded(newUser)
                        .flatMap { (insertReply: InsertReply) -> EventLoopFuture<User?> in
                            return req.mongoDB[User.schema].findOne(["_id": newUser.id], as: User.self)
                        }
                        .flatMap { (v: User?) -> EventLoopFuture<User> in
                            return req.eventLoop.future(v!)
                        }
                }
            }
            .flatMap { (user: User) -> EventLoopFuture<LoginResponse> in
                let userPayload = Payload(id: user.id, phoneNumber: user.phoneNumber)

                do {
                    let accessToken = try req.application.jwt.signers.sign(userPayload)
                    let refreshPayload = RefreshToken(user: user)
                    let refreshToken = try req.application.jwt.signers.sign(refreshPayload)
                    let userResponse = user.response
                    _ = smsVerification.delete(on: req.mongoDB)
                    let access = RefreshResponse(accessToken: accessToken, refreshToken: refreshToken)
                    return req.eventLoop.future(user).transform(
                        to: LoginResponse.init(access: access, user: userResponse)
                    )
                }
                catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }
    }


    // MArzhaev: I don't quite understand this logic as to what is to be persisted in the DB. Need to verify.
    private func refreshAccessToken(_ req: Request)throws -> EventLoopFuture<RefreshTokenResponse>  {
        let data = try req.content.decode(RefreshTokenInput.self)
        let refreshToken = data.refreshToken
        let jwtPayload: RefreshToken = try req.application
            .jwt.signers.verify(refreshToken, as: RefreshToken.self)

        let userId = jwtPayload.id

        return req.mongoDB[User.schema].findOne("_id" == userId)
            .flatMapThrowing({ (document : Document?) -> User in
                if (document != nil) {
                    return try! BSONDecoder().decode(User.self, from: document!)
                } else {
                    throw Abort(.notFound)
                }
            })
            .map { (user : User) -> RefreshTokenResponse in
                let payload = Payload(id: user.id, phoneNumber: user.phoneNumber)
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

        enum CodingKeys: String, CodingKey {
            case phoneNumber = "phone_number"
        }
    }

    struct SendUserVerificationResponse: Content {
        let phoneNumber: String
        let attemptId: ObjectId

        enum CodingKeys: String, CodingKey {
            case phoneNumber = "phone_number"
            case attemptId = "attempt_id"
        }
    }

    struct UserVerificationPayload: Codable, Content {
        let attemptId: ObjectId
        let phoneNumber: String
        let code: String

        enum CodingKeys: String, CodingKey {
            case code
            case phoneNumber = "phone_number"
            case attemptId = "attempt_id"
        }
    }

}
