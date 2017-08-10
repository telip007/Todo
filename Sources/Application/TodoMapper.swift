//
//  TodoMapper.swift
//  todoApp
//
//  Created by Talip Göksu on 09.08.17.
//
//

import Foundation
import Kitura
import CouchDB
import LoggerAPI
import SwiftyJSON

enum MapperResult<T> {
    case success(T)
    case failure(Error?)
}

internal typealias ResultBlock<T> = (MapperResult<T>) -> Void

class TodoMapper {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func getAll(completionHandler: @escaping ResultBlock<JSON>) {
        database.queryByView("all_todos", ofDesign: "main_design", usingParameters: []) { (result: JSON?, error: NSError?) in
            if let result = result {
                completionHandler(.success(result))
                return
            }
            completionHandler(.failure(error))
        }
    }
    
    func getTodo(by id: String, completionHandler: @escaping ResultBlock<JSON>) {
        database.retrieve(id) { (result: JSON?, error: Error?) in
            if let result = result {
                completionHandler(.success(result))
                return
            }
            completionHandler(.failure(error))
        }
    }
    
    func create(json: JSON, completionHandler: @escaping ResultBlock<Todo>) {
        guard let title = json["title"].string,
            let createdAt = json["createdAt"].uInt,
            let updatedAt = json["updatedAt"].uInt else { completionHandler(.failure(nil)); return }
        let todoJson = JSON([
            "type": Todo.type,
            "title": title,
            "createdAt": createdAt,
            "updatedAt": updatedAt
            ])
        var todo: Todo?
        var error: Error?
        database.create(todoJson) { (id, revision, document, err) in
            if let id = id {
                Log.info("Todo \(title) created with id: \(id)")
                todo = Todo(id: "\(id)", title: title, createdAt: createdAt, updatedAt: updatedAt)
                return
            }
            Log.error("Oops something went wrong; could not create todo.")
            error = err
        }
        guard let createdTodo = todo else { completionHandler(.failure(error)); return }
        completionHandler(.success(createdTodo))
    }
    
}
