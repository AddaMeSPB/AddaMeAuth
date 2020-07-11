//
//  File.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten

final class User: Content {

    static var schema = "users"

    var id: ObjectId
    var firstName: String?
    var lastName: String?
    var phoneNumber: String
    var email: String?
    var contactIds: [ObjectId]?
    var deviceIds: [ObjectId]?
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case email
        case id = "_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case contactIds = "contact_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    init(id: ObjectId = ObjectId(), phoneNumber: String, fastName: String?, lastName: String?, email: String?, contactIds: [ObjectId]?, deviceIds: [ObjectId]?) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.firstName = fastName
        self.lastName = lastName
        self.email = email
        self.contactIds = contactIds
        self.deviceIds = deviceIds
    }

    init(_ request: Req) {
        self.id = ObjectId()
        self.phoneNumber = request.phoneNumber
        self.firstName = request.firstName
        self.lastName = request.lastName
        self.email = request.email
        self.contactIds = request.contactIds
        self.deviceIds = request.deviceIds
    }

    struct Req: Codable {
        var id: String?
        var phoneNumber: String
        var firstName: String?
        var lastName: String?
        var email: String?
        var contactIds: [ObjectId]?
        var deviceIds: [ObjectId]? // device should create 1st before create phoneNumber and user

        enum CodingKeys: String, CodingKey {
            case phoneNumber = "phone_number"
            case firstName = "first_name"
            case lastName = "last_name"
            case contactIds = "contact_ids"
            case deviceIds = "device_ids"
            case id, email
        }
    }

    struct Res: Codable {
        var id: String
        var phoneNumber: String
        var firstName: String
        var lastName: String
        var email: String
        var contactIds: [ObjectId]?
        var deviceIds: [ObjectId]?

        enum CodingKeys: String, CodingKey {
            case phoneNumber = "phone_number"
            case firstName = "first_name"
            case lastName = "last_name"
            case contactIds = "contact_ids"
            case deviceIds = "device_ids"
            case id, email
        }
    }
}

