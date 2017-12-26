class BlockContext {
  class var contextKey: String { return "block_context" }

  // contains mapping of block names to their nodes and templates where they are defined
  var blocks: [String: [(BlockNode, Template?)]]

  init(blocks: [String: [(BlockNode, Template?)]]) {
    self.blocks = blocks
  }

  func pushBlock(_ block: BlockNode, named blockName: String, definedIn template: Template?) {
    if var blocks = blocks[blockName] {
      blocks.append((block, template))
      self.blocks[blockName] = blocks
    } else {
      self.blocks[blockName] = [(block, template)]
    }
  }
  
  func popBlock(named blockName: String) -> (node: BlockNode, template: Template?)? {
    if var blocks = blocks[blockName] {
      let block = blocks.removeFirst()
      if blocks.isEmpty {
        self.blocks.removeValue(forKey: blockName)
      } else {
        self.blocks[blockName] = blocks
      }
      return block
    } else {
      return nil
    }
  }
}


extension Collection {
  func any(_ closure: (Iterator.Element) -> Bool) -> Iterator.Element? {
    for element in self {
      if closure(element) {
        return element
      }
    }

    return nil
  }
}


class ExtendsNode : NodeType {
  let templateName: Variable
  let blocks: [String:BlockNode]
  let token: Token?

  class func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
    let bits = token.components()

    guard bits.count == 2 else {
      throw TemplateSyntaxError("'extends' takes one argument, the template file to be extended")
    }

    let parsedNodes = try parser.parse()
    guard (parsedNodes.any { $0 is ExtendsNode }) == nil else {
      throw TemplateSyntaxError("'extends' cannot appear more than once in the same template")
    }

    let blockNodes = parsedNodes.flatMap { $0 as? BlockNode }

    let nodes = blockNodes.reduce([String: BlockNode]()) { (accumulator, node) -> [String: BlockNode] in
      var dict = accumulator
      dict[node.name] = node
      return dict
    }

    return ExtendsNode(templateName: Variable(bits[1]), blocks: nodes, token: token)
  }

  init(templateName: Variable, blocks: [String: BlockNode], token: Token) {
    self.templateName = templateName
    self.blocks = blocks
    self.token = token
  }

  func render(_ context: Context) throws -> String {
    guard let templateName = try self.templateName.resolve(context) as? String else {
      throw TemplateSyntaxError("'\(self.templateName)' could not be resolved as a string")
    }

    let baseTemplate = try context.environment.loadTemplate(name: templateName)
    let template = context.environment.template
    
    let blockContext: BlockContext
    if let _blockContext = context[BlockContext.contextKey] as? BlockContext {
      blockContext = _blockContext
      for (name, block) in blocks {
        blockContext.pushBlock(block, named: name, definedIn: template)
      }
    } else {
      var blocks = [String: [(BlockNode, Template?)]]()
      self.blocks.forEach { blocks[$0.key] = [($0.value, template)] }
      blockContext = BlockContext(blocks: blocks)
    }

    do {
      // pushes base template and renders it's content
      // block_context contains all blocks from child templates
      return try context.environment.pushTemplate(baseTemplate, token: token) {
        try context.push(dictionary: [BlockContext.contextKey: blockContext]) {
          return try baseTemplate.render(context)
        }
      }
    } catch {
      // if error template is already set (see catch in BlockNode)
      // and it happend in the same template as current template
      // there is no need to wrap it in another error
      if let error = error as? TemplateSyntaxError, error.template !== context.environment.template {
        throw TemplateSyntaxError(reason: error.reason, parentError: error)
      } else {
        throw error
      }
    }
  }
}


class BlockNode : NodeType {
  let name: String
  let nodes: [NodeType]
  let token: Token?

  class func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
    let bits = token.components()

    guard bits.count == 2 else {
      throw TemplateSyntaxError("'block' tag takes one argument, the block name")
    }

    let blockName = bits[1]
    let nodes = try parser.parse(until(["endblock"]))
    _ = parser.nextToken()
    return BlockNode(name:blockName, nodes:nodes, token: token)
  }

  init(name: String, nodes: [NodeType], token: Token) {
    self.name = name
    self.nodes = nodes
    self.token = token
  }

  func render(_ context: Context) throws -> String {
    if let blockContext = context[BlockContext.contextKey] as? BlockContext, let child = blockContext.popBlock(named: name) {
      // child node is a block node from child template that extends this node (has the same name)

      var newContext: [String: Any] = [BlockContext.contextKey: blockContext]
      
      if let blockSuperNode = child.node.nodes.first(where: {
        if case .variable(let variable, _)? = $0.token, variable == "block.super" { return true }
        else { return false}
      }) {
        do {
          // render current (base) node so that its content can be used as part of node that extends it
          newContext["block"] = ["super": try self.render(context)]
        } catch {
          let baseError = context.errorReporter.reportError(error)
          throw TemplateSyntaxError(
            reason: (baseError as? TemplateSyntaxError)?.reason ?? "\(baseError)",
            token: blockSuperNode.token,
            template: child.template,
            parentError: baseError)
        }
      }
      
      // render extension node
      do {
        return try context.push(dictionary: newContext) {
          return try child.node.render(context)
        }
      } catch {
        // child node belongs to child template, which is currently not on top of stack
        // so we need to use node's template to report errors, not current template
        // unless it's already set
        if var error = error as? TemplateSyntaxError {
          error.template = error.template ?? child.template
          error.token = error.token ?? child.node.token
          throw error
        } else {
          throw error
        }
      }
    }

    return try renderNodes(nodes, context)
  }
}
