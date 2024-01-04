//
//  CreateChat.swift
//
//
//  Created by Ilya Likhachev on 04.01.2024.
//

import Fluent

struct CreateChat: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("chats")
            .id()
            .field("tgIdentifier", .string, .required)
            .unique(on: "tgIdentifier")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("chats").delete()
    }
}
