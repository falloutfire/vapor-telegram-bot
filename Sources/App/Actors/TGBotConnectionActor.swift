//
//  TGBotConnectionActor.swift
//
//
//  Created by Ilya Likhachev on 04.01.2024.
//

import Foundation
import TelegramVaporBot

actor TGBotConnection {
    private var _connection: TGConnectionPrtcl!

    var connection: TGConnectionPrtcl {
        self._connection
    }
    
    func setConnection(_ conn: TGConnectionPrtcl) {
        self._connection = conn
    }
}
