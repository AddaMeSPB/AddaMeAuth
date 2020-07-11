//
//  MongoKitten+Application.swift
//  
//
//  Created by Alif on 11/7/20.
//

import Vapor
import MongoKitten

public struct MongoDBStorageKey: StorageKey {
    public typealias Value = MongoDatabase
}

extension Application {
    public var mongoDB: MongoDatabase {
        get {
            storage[MongoDBStorageKey.self]!
        }
        set {
            storage[MongoDBStorageKey.self] = newValue
        }
    }

    public func initializeMongoDB(connectionString: String) throws {
        self.mongoDB = try MongoDatabase.lazyConnect(connectionString, on: self.eventLoopGroup)
    }
}


