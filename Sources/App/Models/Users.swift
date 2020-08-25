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
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    
    init(id: ObjectId = ObjectId(), firstName: String? = nil, lastName: String? = nil, phoneNumber: String, email: String? = nil, contactIds: [ObjectId]? = nil, deviceIds: [ObjectId]? = nil, createdAt: Date, updatedAt: Date, deletedAt: Date? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.contactIds = contactIds
        self.deviceIds = deviceIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

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
    
    var response: Res {
        .init(self)
    }

    required init(_ request: Req) {
        if request.id != nil {
            self.id = ObjectId(request.id!)!
        } else {
            self.id = ObjectId()
        }
        self.phoneNumber = request.phoneNumber
        self.firstName = request.firstName
        self.lastName = request.lastName
        self.email = request.email
        self.contactIds = request.contactIds
        self.deviceIds = request.deviceIds
        self.createdAt = request.createdAt
        self.updatedAt = request.updatedAt
        self.deletedAt = request.deletedAt
    }
    
    struct Req: Codable {
        var id: String?
        var phoneNumber: String
        var firstName: String?
        var lastName: String?
        var email: String?
        var contactIds: [ObjectId]?
        var deviceIds: [ObjectId]? // device should create 1st before create phoneNumber and user
        var createdAt: Date
        var updatedAt: Date
        var deletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, email
            case phoneNumber = "phone_number"
            case firstName = "first_name"
            case lastName = "last_name"
            case contactIds = "contact_ids"
            case deviceIds = "device_ids"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case deletedAt = "deleted_at"
        }
    }

    struct Res: Codable {
        init(_ user: User) {
            self.id = user.id
            self.phoneNumber = user.phoneNumber
            self.firstName = user.firstName
            self.lastName = user.lastName
            self.email = user.email
            self.contactIds = user.contactIds
            self.deviceIds = user.deviceIds
            self.createdAt = user.createdAt
            self.updatedAt = user.updatedAt
            self.deletedAt = user.deletedAt
        }
        
        var id: ObjectId
        var phoneNumber: String
        var firstName: String?
        var lastName: String?
        var email: String?
        var contactIds: [ObjectId]?
        var deviceIds: [ObjectId]?
        var createdAt: Date
        var updatedAt: Date
        var deletedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, email
            case phoneNumber = "phone_number"
            case firstName = "first_name"
            case lastName = "last_name"
            case contactIds = "contact_ids"
            case deviceIds = "device_ids"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case deletedAt = "deleted_at"
        }

    }
    
}

