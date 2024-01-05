//
//  CreateChatUsers.swift
//
//
//  Created by Ilya Likhachev on 04.01.2024.
//

import Fluent

struct CreateChatUsers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("chatusers")
            .id()
            .field("tgIdentifier", .string, .required)
            .field("chatID", .uuid, .required, .references("chats", "id"))
            //.unique(on: "tgIdentifier", "chatID")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("chatusers").delete()
    }
}
