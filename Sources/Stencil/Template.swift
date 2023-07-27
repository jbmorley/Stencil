//
// Stencil
// Copyright © 2022 Stencil
// MIT Licence
//

import Foundation
import PathKit

#if os(Linux)
// swiftlint:disable:next prefixed_toplevel_constant
let NSFileNoSuchFileError = 4
#endif

/// A class representing a template
open class Template: ExpressibleByStringLiteral {
  let templateString: String
  let environment: Environment

  /// The list of parsed (lexed) tokens
  public let tokens: [Token]
  public let nodes: [NodeType]

  /// The name of the loaded Template if the Template was loaded from a Loader
  public let name: String?

  /// Create a template with a template string
  public required init(templateString: String, environment: Environment? = nil, name: String? = nil) throws {
    self.environment = environment ?? Environment()
    self.name = name
    self.templateString = templateString

    let lexer = Lexer(templateName: name, templateString: templateString)
    tokens = lexer.tokenize()

      let parser = TokenParser(tokens: tokens, environment: environment!)
      nodes = try parser.parse()
  }

  /// Create a template with the given name inside the given bundle
  @available(*, deprecated, message: "Use Environment/FileSystemLoader instead")
  public convenience init(named: String, inBundle bundle: Bundle? = nil) throws {
    let useBundle = bundle ?? Bundle.main
    guard let url = useBundle.url(forResource: named, withExtension: nil) else {
      throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }

    try self.init(URL: url)
  }

  /// Create a template with a file found at the given URL
  @available(*, deprecated, message: "Use Environment/FileSystemLoader instead")
  public convenience init(URL: Foundation.URL) throws {
    try self.init(path: Path(URL.path))
  }

  /// Create a template with a file found at the given path
  @available(*, deprecated, message: "Use Environment/FileSystemLoader instead")
  public convenience init(path: Path, environment: Environment? = nil, name: String? = nil) throws {
    try self.init(templateString: try path.read(), environment: environment, name: name)
  }

  // MARK: ExpressibleByStringLiteral

  // Create a templaVte with a template string literal
  public required convenience init(stringLiteral value: String) {
    try! self.init(templateString: value)
  }

  // Create a template with a template string literal
  public required convenience init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self.init(stringLiteral: value)
  }

  // Create a template with a template string literal
  public required convenience init(unicodeScalarLiteral value: StringLiteralType) {
    self.init(stringLiteral: value)
  }

  /// Render the given template with a context
  public func render(_ context: Context) throws -> String {
    if let name {
      context.templates.append(name)
    }
    return try renderNodes(nodes, context)
  }

  // swiftlint:disable discouraged_optional_collection
  /// Render the given template
  open func render(_ dictionary: [String: Any]? = nil) throws -> (String, [String]) {
    var context = Context(dictionary: dictionary ?? [:], environment: environment)
    let contents = try render(context)
      return (contents, context.templates)
  }
}
