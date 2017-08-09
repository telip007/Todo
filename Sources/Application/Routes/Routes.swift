//
//  Routes.swift
//  todoApp
//
//  Created by Talip Göksu on 09.08.17.
//
//

import Foundation
import Kitura
import Health

public func setupRoutes(for router: Router) {
    router.all(middleware: BodyParser())
    setupHealthRoute(for: router)
    setupAPIRoutes(for: router)
}

fileprivate func setupAPIRoutes(for router: Router) {
    router.get("/todos", handler: listAllTodos)
    router.post("/todo", handler: addTodo)
}

fileprivate func setupHealthRoute(for router: Router) {
    let health = Health()
    
    router.get("/health") { request, response, _ in
        let result = health.status.toSimpleDictionary()
        if health.status.state == .UP {
            try response.send(json: result).end()
        } else {
            try response.status(.serviceUnavailable).send(json: result).end()
        }
    }
}
