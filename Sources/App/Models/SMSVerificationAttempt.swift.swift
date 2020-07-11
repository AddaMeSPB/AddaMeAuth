//
//  SMSVerification.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten

final class SMSVerification: Content {

    static let schema = "smsverifications"

    var id: ObjectId
    var phoneNumber: String
    var code: String
    var expiresAt: Date?

    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case code
        case id = "_id"
        case phoneNumber = "phone_number"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(id: ObjectId, code: String, expiresAt: Date?, phoneNumber: String) {
        self.id = id
        self.code = code
        self.expiresAt = expiresAt
        self.phoneNumber = phoneNumber
    }

    func delete(on mongodb: MongoDatabase) -> EventLoopFuture<DeleteReply> {
        mongodb[SMSVerification.schema].deleteOne(where: ["_id": self.id])
    }
}

