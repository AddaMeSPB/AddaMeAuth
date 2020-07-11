//
//  Request+Extension.swift
//  
//
//  Created by Alif on 7/6/20.
//

import Vapor
import MongoKitten
import APNS

extension Request {

    public var mongodb: MongoDatabase {
        if let existing = application.storage[MongoDBStorageKey.self] {
            return existing.hopped(to: self.eventLoop)
        } else {
            #if os(Linux)
                let mongoURL = Environment.get("MONGO_DB_PRO")!
            #else
                let mongoURL = Environment.get("MONGO_DB_DEV")!
                req.logger.info("mongoURL: \(mongoURL)")
            #endif

            let mongoSettings = try! ConnectionSettings(mongoURL)
            let new = try! MongoDatabase.lazyConnect(settings: mongoSettings, on: MultiThreadedEventLoopGroup(numberOfThreads: 1))
            self.application.storage[MongoDBStorageKey.self] = new
            return new.hopped(to: self.eventLoop)
        }
    }

}
