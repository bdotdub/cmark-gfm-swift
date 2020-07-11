import XCTest
import cmark_gfm_swift

extension TextElement {
    var string: String {
        switch self {
        case .code(let text): return text
        case .emphasis(let children): return children.string
        case .link(let children, _, _): return children.string
        case .mention(let login): return login
        case .strikethrough(let children): return children.string
        case .strong(let children): return children.string
        case .text(let text): return text
        case .emoji(let emoji): return emoji
        default: return ""
        }
    }
}

extension String {
    func substring(with nsrange: NSRange) -> String? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return String(self[range])
    }
}

extension Sequence where Iterator.Element == TextElement {
    var string: String { return reduce("") { $0 + $1.string } }
}

class Tests: XCTestCase {

    func testMarkdownToHTML() {
        let markdown = "*Hello World*"
        let html = markdownToHtml(string: markdown)
        XCTAssertEqual(html, "<p><em>Hello World</em></p>\n")
    }

    func testMarkdownToNode() {
        let markdown = "*Hello World*"
        let rootNode = Node(markdown: markdown)
        XCTAssertNotNil(rootNode)
    }

    func testMarkdownToArrayOfBlocks() {
        let markdown = """
            # Heading
            ## Subheading
            Lorem ipsum _dolor sit_ amet.
            * List item 1
            * List item 2
            > Quote
            > > Quote 2
            """
        let rootNode = Node(markdown: markdown)!
        let blocks = rootNode.elements
        XCTAssertEqual(blocks.count, 5)
    }

    func testMarkdownTable() {
        let markdown = """
            | foo | bar |
            | --- | --- |
            | baz | bim |
            """
        let rootNode = Node(markdown: markdown, extensions: [.table])!
        let blocks = rootNode.elements
        XCTAssertEqual(blocks.count, 1)
    }

    func testMarkdownStrikethrough() {
        let markdown = """
            ~~foo~~
            """
        let rootNode = Node(markdown: markdown, extensions: [.strikethrough])!
        let blocks = rootNode.elements
        XCTAssertEqual(blocks.count, 1)
    }

    func testMarkdownAutolink() {
        let markdown = """
            https://github.com
            """
        let rootNode = Node(markdown: markdown, extensions: [.autolink])!
        let blocks = rootNode.elements
        XCTAssertEqual(blocks.count, 1)
    }

    func testMarkdownCodeBlock() {
        let markdown = """
            ```swift
            let a = "foo"
            ```
            """
        let rootNode = Node(markdown: markdown)!
        let blocks = rootNode.elements
        XCTAssertEqual(blocks.count, 1)
    }

    func testKitchenSync() {
        let markdown = """
            # Heading
            ## Subheading
            Lorem @ipsum _dolor sit_ **amet**.
            * List item 1
            * List item 2
              * Nested list item 1
              * Nested list item 2
            > Quote
            > > Quote 2
            - [ ] check one
            - [x] check two
            """
        let elements = Node(markdown: markdown, extensions: [.tasklist])!.flatElements
        XCTAssertEqual(elements.count, 7)

        guard case .heading(let h1, let l1) = elements[0] else { fatalError() }
        XCTAssertEqual(h1.string, "Heading")
        XCTAssertEqual(l1, 1)

        guard case .heading(let h2, let l2) = elements[1] else { fatalError() }
        XCTAssertEqual(h2.string, "Subheading")
        XCTAssertEqual(l2, 2)

        guard case .text(let t1) = elements[2] else { fatalError() }
        XCTAssertEqual(t1.string, "Lorem @ipsum dolor sit amet.")

        guard case let .list(i1, _) = elements[3] else { fatalError() }
        XCTAssertEqual(i1.count, 2)
        XCTAssertEqual(i1[0].count, 1)
        XCTAssertEqual(i1[1].count, 2)

        guard case let .list(n1, _, nl1) = i1[1][1] else { fatalError() }
        XCTAssertEqual(n1.count, 2)
        XCTAssertEqual(nl1, 1)

        guard case let .quote(q1, ql1) = elements[4] else { fatalError() }
        XCTAssertEqual(q1.string, "Quote")
        XCTAssertEqual(ql1, 1)

        guard case let .quote(q2, ql2) = elements[5] else { fatalError() }
        XCTAssertEqual(q2.string, "Quote 2")
        XCTAssertEqual(ql2, 2)

        guard case .list(let i2, _) = elements[6] else { fatalError() }
        XCTAssertEqual(i2.count, 2)
        XCTAssertEqual(i2[0].count, 1)
        XCTAssertEqual(i2[1].count, 1)

        // First task list item
        guard case .tasklist(let tlc1, let checked1) = i2[0][0] else { fatalError() }
        XCTAssertFalse(checked1)

        guard case .text(let tl1) = tlc1[0] else { fatalError() }
        XCTAssertEqual(tl1.count, 1)

        guard case .text(let te1) = tl1[0] else { fatalError() }
        XCTAssertEqual(te1, "check one")

        // Second task list item
        guard case .tasklist(let tlc2, let checked2) = i2[1][0] else { fatalError() }
        XCTAssertTrue(checked2)

        guard case .text(let tl2) = tlc2[0] else { fatalError() }
        XCTAssertEqual(tl2.count, 1)

        guard case .text(let te2) = tl2[0] else { fatalError() }
        XCTAssertEqual(te2, "check two")
    }

    func test_simpleTaskLists() {
        let markdown = """
          paragraph

          - [ ] not checked
          - [x] checked
          """
        let elements = Node(markdown: markdown, extensions: [.tasklist])!.flatElements
        XCTAssertEqual(elements.count, 2)

        guard case .list(let l, _) = elements[1] else { fatalError() }
        XCTAssertEqual(l.count, 2)
        XCTAssertEqual(l[0].count, 1)
        XCTAssertEqual(l[1].count, 1)

        // First task list item
        guard case .tasklist(let tlc1, let checked1) = l[0][0] else { fatalError() }
        XCTAssertFalse(checked1)

        guard case .text(let tl1) = tlc1[0] else { fatalError() }
        XCTAssertEqual(tl1.count, 1)

        guard case .text(let te1) = tl1[0] else { fatalError() }
        XCTAssertEqual(te1, "not checked")

        // Second task list item
        guard case .tasklist(let tlc2, let checked2) = l[1][0] else { fatalError() }
        XCTAssertTrue(checked2)

        guard case .text(let tl2) = tlc2[0] else { fatalError() }
        XCTAssertEqual(tl2.count, 1)

        guard case .text(let te2) = tl2[0] else { fatalError() }
        XCTAssertEqual(te2, "checked")
    }


    func test_nestedLists() {
        let markdown = "First unordered list item\r\n- Another item\r\n  * Unordered sub-list. \r\n\r\n1. Actual numbers don't matter, just that it's a number\r\n    1. Ordered sub-list\r\n4. And another item.\r\n\r\n* Unordered list can use asterisks\r\n- Or minuses\r\n+ Or pluses\r\n\r\n- [x] And checked boxes\r\n- [ ] Or unchecked"
        let elements = Node(markdown: markdown, extensions: [.tasklist])!.flatElements
        XCTAssertEqual(elements.count, 7)

        guard case .list(let l, _) = elements[6] else { fatalError() }
        XCTAssertEqual(l.count, 2)
        XCTAssertEqual(l[0].count, 1)
        XCTAssertEqual(l[1].count, 1)

        guard case .tasklist(let tl1, let checked1) = l[0][0] else { fatalError() }
        XCTAssertTrue(checked1)

        guard case .text(let tlc1) = tl1[0] else { fatalError() }
        XCTAssertEqual(tlc1.count, 1)

        guard case .text(let te1) = tlc1[0] else { fatalError() }
        XCTAssertEqual(te1, "And checked boxes")

        guard case .tasklist(let tl2, let checked2) = l[1][0] else { fatalError() }
        XCTAssertFalse(checked2)

        guard case .text(let tlc2) = tl2[0] else { fatalError() }
        XCTAssertEqual(tlc2.count, 1)

        guard case .text(let te2) = tlc2[0] else { fatalError() }
        XCTAssertEqual(te2, "Or unchecked")
    }

    func testComplicatedLists() {
        let markdown = """
            - a
              > b
              ```
              c
              ```
            - d
            """
        let elements = Node(markdown: markdown)!.flatElements
        XCTAssertEqual(elements.count, 1)
    }

    func testTables() {
        let markdown = """
            | foo | bar |
            | --- | --- |
            | baz | bim |
            """
        let elements = Node(markdown: markdown, extensions: [.table])!.flatElements
        XCTAssertEqual(elements.count, 1)

        guard case .table(let rows) = elements[0] else { fatalError() }
        XCTAssertEqual(rows.count, 2)

        guard case .header(let headerCells) = rows[0] else { fatalError() }
        XCTAssertEqual(headerCells.count, 2)
        XCTAssertEqual(headerCells[0].string, "foo")
        XCTAssertEqual(headerCells[1].string, "bar")

        guard case .row(let cells) = rows[1] else { fatalError() }
        XCTAssertEqual(cells.count, 2)
        XCTAssertEqual(cells[0].string, "baz")
        XCTAssertEqual(cells[1].string, "bim")
    }

    func testEmailNotAMention() {
        let markdown = "me@google"
        let node = Node(markdown: markdown)!
        XCTAssertEqual(node.elements.count, 1)

        guard case .paragraph(let paragraph)? = node.elements.first else { fatalError() }
        XCTAssertEqual(paragraph.count, 1)

        guard case .text(let text)? = paragraph.first else { fatalError() }
        XCTAssertEqual(text, "me@google")
    }

    func testHTML_withGitHawkSignature() {
        let markdown = "<sub>Sent with <a href=\"githawk.com\">GitHawk</a></sub>"
        let node = Node(markdown: markdown)!
        XCTAssertEqual(node.elements.count, 1)

        guard case .paragraph(let paragraph)? = node.elements.first else { fatalError() }
        XCTAssertEqual(paragraph.count, 6)

        let elements = node.flatElements
        XCTAssertEqual(elements.count, 1)
    }

    func testRenderBold_withColon() {
        let markdown = "**i am a test:**"
        let html = Node(markdown: markdown)!.html

        XCTAssertEqual(html, "<p><strong>i am a test:</strong></p>\n")
    }

    func testRenderEmoji_withInvalidEmoji() {
        let markdown = "This is :notvalidemoji:"
        let html = Node(markdown: markdown)!.html

        XCTAssertEqual(html, "<p>This is :notvalidemoji:</p>\n")
    }

    func testRenderHTML_withList() {
        let markdown = """
                - One
                - Two
                """
        let html = Node(markdown: markdown)!.html
        let expected = """
                <ul>
                <li>One</li>
                <li>Two</li>
                </ul>

                """
        XCTAssertEqual(html, expected)
    }

    func testRenderFootnote() {
        let markdown = """
            This is some text![^1].

            [^1]: Some *bolded* footnote definition.
            """
        let html = Node(markdown: markdown, options: [.footnotes])!.html
        let expected = """
            <p>This is some text!<sup class="footnote-ref"><a href="#fn1" id="fnref1">1</a></sup>.</p>
            <section class="footnotes">
            <ol>
            <li id="fn1">
            <p>Some <em>bolded</em> footnote definition. <a href="#fnref1" class="footnote-backref">↩</a></p>
            </li>
            </ol>
            </section>

            """
        XCTAssertEqual(html, expected)
    }

    func testRenderPartWikiLink() {
        let markdown = """
                    This is part of a wikilink [[
                    """
        let html = Node(markdown: markdown, extensions: [.wikilink])!.html
        let expected = """
                    <p>This is part of a wikilink [[</p>

                    """
        XCTAssertEqual(html, expected)
    }

    func testRenderAnotherPartWikiLink() {
        let markdown = "[[]\n"
        let html = Node(markdown: markdown, extensions: [.wikilink])!.html
        let expected = """
                        <p>[[]</p>

                        """
        XCTAssertEqual(html, expected)
    }

    func testRenderEmptyWikiLink() {
        let markdown = """
                        This is an empty wikilink [[|]]
                        """
        let html = Node(markdown: markdown, extensions: [.wikilink])!.html
        let expected = """
                        <p>This is an empty wikilink [[|]]</p>

                        """
        XCTAssertEqual(html, expected)
    }

    func testRenderWikiLink_withOnlyDescription() {
        let markdown = """
                        This is a half empty wikilink [[description]]
                        """
        let html = Node(markdown: markdown, extensions: [.wikilink])!.html
        let expected = """
                        <p>This is a half empty wikilink <a href="description">description</a></p>

                        """
        XCTAssertEqual(html, expected)
    }

    func testRenderWikiLink() {
        let markdown = """
                This is a [[WikiLink|./file.md]]
                """
        let html = Node(markdown: markdown, extensions: [.wikilink])!.html
        let expected = """
                <p>This is a <a href="./file.md">WikiLink</a></p>

                """
        XCTAssertEqual(html, expected)
    }

    func testRenderNormalLink() {
        let markdown = """
                    This is a [Normal Link](https://example.com)
                    """
        let html = Node(markdown: markdown, extensions: [.wikilink])!.html
        let expected = """
                    <p>This is a <a href="https://example.com">Normal Link</a></p>

                    """
        XCTAssertEqual(html, expected)
    }

    func testRenderHTML_withCheckbox() {
        let markdown = """
            - [ ] One
            - [x] Two
            """
        let html = Node(markdown: markdown, extensions: [.tasklist])!.html
        let expected = """
            <ul>
            <li><input type="checkbox" disabled="" /> One</li>
            <li><input type="checkbox" checked="" disabled="" /> Two</li>
            </ul>

            """
        XCTAssertEqual(html, expected)
    }

    func testPosition() {
        let markdown = """
        Hello there

        - [ ] Some list
        - [x] With items

        a [[wikilink|./something]]

        [some other link](https://google.com) and then an https://autolink.com and another www.autolink.com
        """

        let node = Node(markdown: markdown, extensions: [.autolink, .tasklist, .wikilink])!

        // Paragraph
        let paragraphNode = node.children[0]
        XCTAssertEqual(paragraphNode.start.line, 1)
        XCTAssertEqual(paragraphNode.start.column, 1)
        XCTAssertEqual(paragraphNode.end.line, 1)
        XCTAssertEqual(paragraphNode.end.column, 11)

        // List
        let listItem1 = node.children[1]
        XCTAssertEqual(listItem1.start.line, 3)
        XCTAssertEqual(listItem1.start.column, 1)
        XCTAssertEqual(listItem1.end.line, 5)
        XCTAssertEqual(listItem1.end.column, 0)

        // Task List
        let taskListItem1 = listItem1.children[0]
        XCTAssertEqual(taskListItem1.start.line, 3)
        XCTAssertEqual(taskListItem1.start.column, 1)
        XCTAssertEqual(taskListItem1.end.line, 3)
        XCTAssertEqual(taskListItem1.end.column, 15)

        // Task list text
        let taskListItemText1 = taskListItem1.children[0]
        XCTAssertEqual(taskListItemText1.start.line, 3)
        XCTAssertEqual(taskListItemText1.start.column, 7)
        XCTAssertEqual(taskListItemText1.end.line, 3)
        XCTAssertEqual(taskListItemText1.end.column, 15)

        // Wikilink
        let wikilink = node.children[2].children[1]
        XCTAssertEqual(wikilink.start.line,6)
        XCTAssertEqual(wikilink.start.column, 3)
        XCTAssertEqual(wikilink.end.line, 6)
        XCTAssertEqual(wikilink.end.column, 27)

        // Link
        let link = node.children[3].children[0]
        XCTAssertEqual(link.start.line, 8)
        XCTAssertEqual(link.start.column, 1)
        XCTAssertEqual(link.end.line, 8)
        XCTAssertEqual(link.end.column, 37)

        // Link text
        let linkText = link.children[0]
        XCTAssertEqual(linkText.start.line, 8)
        XCTAssertEqual(linkText.start.column, 2)
        XCTAssertEqual(linkText.end.line, 8)
        XCTAssertEqual(linkText.end.column, 16)

        // Autolink (URL)
        let autolinkURL = node.children[3].children[2]
        XCTAssertEqual(autolinkURL.start.line, 8)
        XCTAssertEqual(autolinkURL.start.column, 50)
        XCTAssertEqual(autolinkURL.end.line, 8)
        XCTAssertEqual(autolinkURL.end.column, 70)

        // Autolink (www)
        let autolinkWWW = node.children[3].children[4]
        XCTAssertEqual(autolinkWWW.start.line, 8)
        XCTAssertEqual(autolinkWWW.start.column, 83)
        XCTAssertEqual(autolinkWWW.end.line, 8)
        XCTAssertEqual(autolinkWWW.end.column, 99)
    }

    func testValidWikilinks() {
        let cases = [
            ("[[wikilink|https://bwong.net]]", "wikilink", "https://bwong.net"),
            ("[[wikilink|./relative]]", "wikilink", "./relative"),
            ("[[wikilink]]", "wikilink", "wikilink"),
        ]

        cases.forEach { testCase in
            let elements = Node(markdown: testCase.0, extensions: [.wikilink])!.flatElements
            guard case .text(let textElements) = elements[0] else {
                XCTFail("expected a text element")
                return
            }
            guard case .wikilink(_, let title, let url) = textElements[0] else {
                XCTFail("expected a wikilink")
                return
            }

            XCTAssertEqual(title, testCase.1)
            XCTAssertEqual(url, testCase.2)
        }
    }

    func testInvalidWikilinks() {
        let cases = [
            "[[wikilink|https://bwong.net]",
            "[[wikilink]",
            "[wikilink]]",
            "[[]]",
            "[[|]]",
            "[[pre|]]",
            "[[|post]]",
        ]

        cases.forEach { testCase in
            let elements = Node(markdown: testCase, extensions: [.wikilink])!.flatElements
            guard case .text(let textElements) = elements[0] else {
                XCTFail("expected a text element")
                return
            }
            guard case .text(let text) = textElements[0] else {
                XCTFail("expected a wikilink")
                return
            }
            XCTAssertEqual(text, testCase)
        }
    }

}

