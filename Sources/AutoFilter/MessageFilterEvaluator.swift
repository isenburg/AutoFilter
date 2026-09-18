import Foundation

/// A high-performance, case-insensitive Boolean expression parser and evaluator for radio spot and decode message content.
/// Supports `AND`, `OR`, grouping parentheses `( )`, and quoted phrases like `"5 up"` or `"SSB"`.
public enum MessageFilterEvaluator {
    
    // MARK: - Tokens
    private enum Token: Equatable {
        case literal(String)
        case andOp
        case orOp
        case lparen
        case rparen
    }
    
    // MARK: - AST Nodes
    private indirect enum ASTNode {
        case literal(String)
        case andNode(ASTNode, ASTNode)
        case orNode(ASTNode, ASTNode)
        
        func evaluate(against message: String) -> Bool {
            switch self {
            case .literal(let term):
                guard !term.isEmpty else { return true }
                return message.localizedCaseInsensitiveContains(term)
            case .andNode(let left, let right):
                return left.evaluate(against: message) && right.evaluate(against: message)
            case .orNode(let left, let right):
                return left.evaluate(against: message) || right.evaluate(against: message)
            }
        }
    }
    
    // MARK: - Public API
    
    /// Evaluates whether a given `message` matches the boolean `query`.
    /// - Parameters:
    ///   - message: The message/comment field to inspect (e.g. from WSJT-X or DX-Cluster).
    ///   - query: The search query with boolean syntax (e.g. `ssb OR rtty OR 73 OR "5 up"`).
    /// - Returns: `true` if the message matches the query, or if the query is empty.
    public static func evaluate(message: String, query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return true }
        
        let tokens = tokenize(trimmedQuery)
        guard !tokens.isEmpty else { return true }
        
        var parser = Parser(tokens: tokens)
        guard let ast = parser.parse() else {
            // Fallback: if parsing failed, treat query as a simple case-insensitive substring search
            return message.localizedCaseInsensitiveContains(trimmedQuery)
        }
        
        return ast.evaluate(against: message)
    }
    
    // MARK: - Tokenizer
    private static func tokenize(_ input: String) -> [Token] {
        var tokens: [Token] = []
        let chars = Array(input)
        var i = 0
        let count = chars.count
        
        while i < count {
            let c = chars[i]
            
            if c.isWhitespace {
                i += 1
                continue
            }
            
            if c == "(" {
                tokens.append(.lparen)
                i += 1
                continue
            }
            
            if c == ")" {
                tokens.append(.rparen)
                i += 1
                continue
            }
            
            // Quoted string (e.g. "5 up", "SSB", "AND")
            if c == "\"" || c == "'" {
                let quoteChar = c
                i += 1
                var phrase = ""
                while i < count && chars[i] != quoteChar {
                    phrase.append(chars[i])
                    i += 1
                }
                if i < count && chars[i] == quoteChar {
                    i += 1 // skip closing quote
                }
                tokens.append(.literal(phrase))
                continue
            }
            
            // Word or operator
            var word = ""
            while i < count && !chars[i].isWhitespace && chars[i] != "(" && chars[i] != ")" && chars[i] != "\"" && chars[i] != "'" {
                word.append(chars[i])
                i += 1
            }
            
            let upper = word.uppercased()
            if upper == "AND" {
                tokens.append(.andOp)
            } else if upper == "OR" {
                tokens.append(.orOp)
            } else {
                tokens.append(.literal(word))
            }
        }
        
        return tokens
    }
    
    // MARK: - Parser
    private struct Parser {
        let tokens: [Token]
        var index = 0
        
        private var current: Token? {
            index < tokens.count ? tokens[index] : nil
        }
        
        mutating func parse() -> ASTNode? {
            guard !tokens.isEmpty else { return nil }
            return parseOr()
        }
        
        // OR has lowest precedence
        private mutating func parseOr() -> ASTNode? {
            guard var left = parseAnd() else { return nil }
            
            while let tok = current, tok == .orOp {
                index += 1 // consume OR
                guard let right = parseAnd() else {
                    // Dangling OR -> just return left
                    return left
                }
                left = .orNode(left, right)
            }
            
            return left
        }
        
        // AND has higher precedence than OR
        private mutating func parseAnd() -> ASTNode? {
            guard var left = parsePrimary() else { return nil }
            
            while let tok = current {
                if tok == .andOp {
                    index += 1 // consume AND
                    guard let right = parsePrimary() else {
                        return left
                    }
                    left = .andNode(left, right)
                } else if case .literal = tok {
                    // Implicit AND if two literals follow each other without an operator
                    guard let right = parsePrimary() else {
                        return left
                    }
                    left = .andNode(left, right)
                } else if tok == .lparen {
                    guard let right = parsePrimary() else {
                        return left
                    }
                    left = .andNode(left, right)
                } else {
                    break
                }
            }
            
            return left
        }
        
        // Primary: literals or parenthesized expressions
        private mutating func parsePrimary() -> ASTNode? {
            guard let tok = current else { return nil }
            
            switch tok {
            case .literal(let text):
                index += 1
                return .literal(text)
                
            case .lparen:
                index += 1 // consume (
                let expr = parseOr()
                if let curr = current, curr == .rparen {
                    index += 1 // consume )
                }
                return expr
                
            case .orOp, .andOp:
                // Skip stray leading operator
                index += 1
                return parsePrimary()
                
            case .rparen:
                index += 1
                return nil
            }
        }
    }
}
