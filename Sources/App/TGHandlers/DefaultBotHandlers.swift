//
//  DefaultBotHandlers.swift
//
//
//  Created by Ilya Likhachev on 04.01.2024.
//

import Vapor
import TelegramVaporBot

final class DefaultBotHandlers {

    static func addHandlers(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await defaultBaseHandler(app: app, connection: connection)
        await messageHandler(app: app, connection: connection)
        await commandPingHandler(app: app, connection: connection)
        await commandShowButtonsHandler(app: app, connection: connection)
        await buttonsActionHandler(app: app, connection: connection)
    }
    
    /// Handler for all updates
    private static func defaultBaseHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGBaseHandler({ update, bot in
            guard let message = update.message else { return }
            let params: TGSendMessageParams = .init(chatId: .chat(message.chat.id), text: "TGBaseHandler")
            try await connection.bot.sendMessage(params: params)
        }))
    }

    /// Handler for Messages
    private static func messageHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGMessageHandler(filters: (.all && !.command.names(["/ping", "/show_buttons"]))) { update, bot in
            let params: TGSendMessageParams = .init(chatId: .chat(update.message!.chat.id), text: "Success")
            try await connection.bot.sendMessage(params: params)
        })
    }

    /// Handler for Commands
    private static func commandPingHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/ping"]) { update, bot in
            try await update.message?.reply(text: "pong", bot: bot)
        })
    }

    /// Show buttons
    private static func commandShowButtonsHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/show_buttons"]) { update, bot in
            guard let userId = update.message?.from?.id else { fatalError("user id not found") }
            guard let chatId = update.message?.chat.id else { fatalError("chat id not found") }
            let buttons: [[TGInlineKeyboardButton]] = [
                [.init(text: "Button 1", callbackData: "press 1"), .init(text: "Button 2", callbackData: "press 2")]
            ]
            let buttons2: [[TGKeyboardButton]] = [
                [.init(text: "Button 1")]
            ]
            let keyboard: TGInlineKeyboardMarkup = .init(inlineKeyboard: buttons)
            let keyboard2: TGReplyKeyboardMarkup = .init(keyboard: buttons2)
            let params: TGSendMessageParams = .init(chatId: .chat(chatId),
                                                    text: "Keyboard active",
                                                    replyMarkup: .inlineKeyboardMarkup(keyboard))
            try await connection.bot.sendMessage(params: params)
        })
    }

    /// Handler for buttons callbacks
    private static func buttonsActionHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCallbackQueryHandler(pattern: "press 1") { update, bot in
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try await bot.answerCallbackQuery(params: params)
        })
        
        await connection.dispatcher.add(TGCallbackQueryHandler(pattern: "press 2") { update, bot in
            let params: TGAnswerCallbackQueryParams = .init(callbackQueryId: update.callbackQuery?.id ?? "0",
                                                            text: update.callbackQuery?.data  ?? "data not exist",
                                                            showAlert: nil,
                                                            url: nil,
                                                            cacheTime: nil)
            try await bot.answerCallbackQuery(params: params)
        })
    }
}
