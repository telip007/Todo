//
//  TodoHandlers.swift
//  todoApp
//
//  Created by Talip Göksu on 09.08.17.
//
//

import Foundation
import CouchDB
import Kitura
import LoggerAPI
import SwiftyJSON

internal func listAllTodos(request: RouterRequest,
                           response: RouterResponse, next: @escaping ()->Void) -> Void {
    Log.info("Handling list all todos")
    todoMapper?.getAll() { result in
        switch result {
        case .success(let todos):
            var json = JSON([:])
            json["todos"] = JSON(todos.map({ $0.json }))
            json["count"].int = todos.count
            response.status(.OK).send(json: json)
            break
        case .failure(let error):
            response.status(.internalServerError).send(json: JSON(["error": "Could not service request", "localizedDescription": error?.localizedDescription]))
            break
        }
        next()
    }
}

internal func getTodo(request: RouterRequest,
                      response: RouterResponse, next: @escaping ()->Void) {
    guard let id: String = request.parameters["id"] else {
        response.status(.notFound).send(json: JSON(["error": "Not Found"]))
        next()
        return
    }
    Log.info("Displaying todos for \(id)")
    
    todoMapper?.getTodo(by: id) { result in
        switch result {
        case .success(let todo):
            response.status(.OK).send(json: todo.json)
            break
        case .failure(let error):
            response.status(.internalServerError).send(json: JSON(["error": "Could not service request", "localizedDescription": error?.localizedDescription]))
            break
        }
        next()
    }
}

internal func addTodo(request: RouterRequest,
                      response: RouterResponse, next: @escaping ()->Void) -> Void {
    Log.info("Adding todo")
    let contentType = request.headers["Content-Type"] ?? "";
    guard case let .json(json) = request.body!,
        contentType.hasPrefix("application/json") else {
            Log.info("No data")
            response.status(.badRequest).send(json: JSON(["error": "No data received"]))
            next()
            return
    }
    todoMapper?.create(json: json) { result in
        switch result {
        case .success(let todo):
            response.status(.OK).send(json: todo.json)
            response.headers["Content-Type"] = "applicaion/hal+json"
            break
        case .failure(let error):
            response.status(.internalServerError).send(json: JSON(["error": "Could not service request", "localizedDescription": error?.localizedDescription]))
            break
        }
        next()
    }
}
