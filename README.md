# Stencil

Stencil is a simple and powerful template language for Swift. It provides a
syntax similar to Django and Mustache. If you're familiar with these, you will
feel right at home with Stencil.

_Please note that this is a fork of Stencil (one of [many](https://github.com/stencilproject/Stencil/forks)) with extensions to support [InContext 3](https://github.com/inseven/ic3). It adds a number of bug fixes and extensions to improve compatibility with Jinja 2 templates. I would love to upstream these changes, but it looks like the original Stencil might no longer be in active development._

## Example

```html+django
There are {{ articles.count }} articles.

<ul>
  {% for article in articles %}
    <li>{{ article.title }} by {{ article.author }}</li>
  {% endfor %}
</ul>
```

```swift
import Stencil

struct Article {
  let title: String
  let author: String
}

let context = [
  "articles": [
    Article(title: "Migrating from OCUnit to XCTest", author: "Kyle Fuller"),
    Article(title: "Memory Management with ARC", author: "Kyle Fuller"),
  ]
]

let environment = Environment(loader: FileSystemLoader(paths: ["templates/"]))
let rendered = try environment.renderTemplate(name: "article_list.html", context: context)

print(rendered)
```

## Philosophy

Stencil follows the same philosophy of Django:

> If you have a background in programming, or if you’re used to languages which
> mix programming code directly into HTML, you’ll want to bear in mind that the
> Django template system is not simply Python embedded into HTML. This is by
> design: the template system is meant to express presentation, not program
> logic.

## The User Guide

Resources for Stencil template authors to write Stencil templates:

- [Language overview](http://stencil.fuller.li/en/latest/templates.html)
- [Built-in template tags and filters](http://stencil.fuller.li/en/latest/builtins.html)

Resources to help you integrate Stencil into a Swift project:

- [Installation](http://stencil.fuller.li/en/latest/installation.html)
- [Getting Started](http://stencil.fuller.li/en/latest/getting-started.html)
- [API Reference](http://stencil.fuller.li/en/latest/api.html)
- [Custom Template Tags and Filters](http://stencil.fuller.li/en/latest/custom-template-tags-and-filters.html)

## Projects that use Stencil

[Sourcery](https://github.com/krzysztofzablocki/Sourcery),
[SwiftGen](https://github.com/SwiftGen/SwiftGen),
[Kitura](https://github.com/IBM-Swift/Kitura),
[Weaver](https://github.com/scribd/Weaver),
[Genesis](https://github.com/yonaskolb/Genesis)

## License

Stencil is licensed under the BSD license. See [LICENSE](LICENSE) for more
info.
