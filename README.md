# cmark-gfm-swift

![Build Status](https://github.com/bdotdub/cmark-gfm-swift/workflows/Test/badge.svg)

A Swift wrapper of cmark with GitHub Flavored Markdown extensions.

### Usage

**Import the framework**

```swift
import cmark_gfm_swift
```

**Render Markdown to HTML**

```swift
let markdownText = """
## Heading
"""

if let parsed = Node(markdown: markdownText)?.html {
  print("HTML parsed: \(parsed)")
}
```

**Enabling Markdown extensions and options**

```swift
let markdownText = """
## Heading
"""

// List of markdown options
var options: [MarkdownOption] = [
  .footnotes // Footnote syntax
]

// List of markdown extensions
var extensions: [MarkdownExtension] = [
  .table,        // Tables
  .autolink,     // Autolink URLs
  .tasklist,     // Tasklist
  .wikilink,     // WikiLinks
  .strikethrough // Strikethrough
]

if let parsed = Node(
  markdown: markdownText,
  options: options,
  extensions: extensions
)?.html {
  print("HTML parsed: \(parsed)")
}
```

### Resources

- [GFM spec](https://github.github.com/gfm/) with [blog post](https://githubengineering.com/a-formal-spec-for-github-markdown/)
- [CommonMark extensions](https://github.com/commonmark/CommonMark/wiki/Deployed-Extensions)
- [Using cmark gfm extensions](https://medium.com/@krisgbaker/using-cmark-gfm-extensions-aad759894a89)

### Acknowledgements

- [cmark](https://github.com/commonmark/cmark)
- [GitHub cmark-gfm](https://github.com/github/cmark-gfm)
- Based off of work by:
  - [Ryan Nystrom](https://github.com/rnystrom)'s original library: https://github.com/GitHawkApp/cmark-gfm-swift
  - [Luka Kerr](https://github.com/lukakerr)'s fork that adds initial wikilink support: https://github.com/lukakerr/cmark-gfm-swift
- Original Inspirations
  - [commonmark-swift](https://github.com/chriseidhof/commonmark-swift)
  - [libcmark_gfm](https://github.com/KristopherGBaker/libcmark_gfm)
