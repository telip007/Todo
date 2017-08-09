//
//  Todo.swift
//  todoApp
//
//  Created by Talip Göksu on 09.08.17.
//
//

import SwiftyJSON

struct Todo {
    public static var type: String {
        return "todo"
    }
    let id: String
    let title: String
    let createdAt: UInt
    let updatedAt: UInt
    
    var json: JSON {
        return JSON([
            "type": Todo.type,
            "id": id,
            "title": title,
            "createdAt": createdAt,
            "updatedAt": updatedAt
            ])
    }
    
}
