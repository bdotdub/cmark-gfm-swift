//
//  Block+ListElement.swift
//  cmark-gfm-swift
//
//  Created by Ryan Nystrom on 3/31/18.
//

import Foundation

extension Block {
    var listElement: ListElement? {
        switch self {
        case .paragraph(let text):
            return .text(text: text.textElements)
        case .blockQuote(let items):
            return .text(text: items.textElements.flatMap { $0 })
        case .custom(let literal):
            return .text(text: [.text(text: literal)])
        case .codeBlock(let text, _):
            return .text(text: [.code(text: text)])
        case .list(let items, let type):
            return .list(children: items.flatMap { $0.listElements }, type: type)
        default: return nil
        }
    }
}

extension Sequence where Iterator.Element == Block {
    var listElements: [ListElement] { return flatMap { $0.listElement } }
}