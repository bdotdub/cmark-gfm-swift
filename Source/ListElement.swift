//
//  ListElement.swift
//  cmark-gfm-swift
//
//  Created by Ryan Nystrom on 3/31/18.
//

import Foundation

public enum ListElement {
    case tasklist(children: [ListElement], checked: Bool)
    case text(text: TextLine)
    case list(children: [[ListElement]], type: ListType, level: Int)
}
