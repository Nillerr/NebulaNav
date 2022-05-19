import SwiftUI

struct ReactRoute {
    let path: String
    let pathSegments: [String]
    
    init(string: String) {
        let path = string.starts(with: "/") ? string : "/\(string)"
        
        self.path = path
        self.pathSegments = path.split(separator: "/").map(String.init)
    }
    
    static var root: ReactRoute { ReactRoute(string: "/") }
}

struct Match: Equatable {
    let pattern: PathPattern
    let pathname: String
    internal let pathnameBase: String
    let parameters: [String : String]
}

struct RegExp {
    typealias Options = NSRegularExpression.Options
    typealias MatchingOptions = NSRegularExpression.MatchingOptions
    
    internal let regex: NSRegularExpression
    
    var pattern: String { regex.pattern }
    var options: Options { regex.options }
    
    init(pattern: String, options: Options = []) throws {
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
    }
    
    struct SingleMatch {
        let range: Range<String.Index>?
        let value: String
    }
    
    typealias Match = [SingleMatch]
}

extension NSTextCheckingResult {
    internal func toMatch(in string: String) -> RegExp.Match {
        (0..<self.numberOfRanges)
            .map {
                let range = Range(range(at: $0), in: string)
                return RegExp.SingleMatch(range: range, value: range.map { String(string[$0]) } ?? "")
            }
    }
}

extension StringProtocol {
    func matches(_ regex: RegExp, options: RegExp.MatchingOptions = []) -> Bool {
        return firstMatch(regex, options: options) != nil
    }
    
//    func match(_ regex: RegExp, options: RegExp.MatchingOptions = []) -> [RegExp.Match] {
//        let string = String(self)
//
//        let range = NSMakeRange(0, count)
//        return regex.regex.matches(in: string, options: options, range: range)
//            .map { $0.toMatch(in: string) }
//    }
    
    func firstMatch(_ regex: RegExp, options: RegExp.MatchingOptions = []) -> RegExp.Match? {
        let string = String(self)
        
        let range = NSMakeRange(0, count)
        return regex.regex.firstMatch(in: string, options: options, range: range)?
            .toMatch(in: string)
    }
    
    func replacingMatches(of regex: RegExp, with template: String, options: RegExp.MatchingOptions = []) -> String {
        let string = String(self)
        
        let range = NSMakeRange(0, count)
        return regex.regex.stringByReplacingMatches(in: string, options: options, range: range, withTemplate: template)
    }
}

struct CompiledPath {
    let matcher: RegExp
    let parameterNames: [String]
}

func compilePath(path: String, caseSensitive: Bool = false, end: Bool = false) -> (RegExp, [String]) {
    var regexpSource = path
    if !regexpSource.starts(with: "/") {
        regexpSource = "/\(regexpSource)"
    }
    
    regexpSource = "^" + path
        .replacingMatches(of: try! RegExp(pattern: "/*\\*?$"), with: "") // Ignore trailing / and /*, we'll handle it below
        .replacingMatches(of: try! RegExp(pattern: "^/*"), with: "/") // Make sure it has a leading /
//        .replacingMatches(of: try! RegExp(pattern: "[\\\\.*+^$?{}|()[\\]]"), with: "\\$&") // Escape special regex chars
    
    var parameterNames: [String] = []
    let parameterNameExp = try! RegExp(pattern: ":(\\w+)")
    while let match = regexpSource.firstMatch(parameterNameExp) {
        if let range = match[1].range {
            parameterNames.append(match[1].value)
            
            regexpSource.replaceSubrange(range, with: "([^/]+)")
        }
    }
    
    if path.hasSuffix("*") {
        parameterNames.append("*")
        
        regexpSource += path == "*" || path == "/*"
            ? "(.*)$"
            : "(?:/(.+)|/*)$"
    } else {
        regexpSource += end
            ? "/*$"
            : "(?:(?=[.~-]|%[0-9A-F]{2})|\\b|/|$)"
    }
    
    let matcher = try! RegExp(pattern: regexpSource, options: caseSensitive ? [] : [.caseInsensitive])
    return (matcher, parameterNames)
}

struct PathPattern: Equatable {
    let path: String
    let caseSensitive: Bool
    let end: Bool
    
    init(path: String, caseSensitive: Bool = false, end: Bool = true) {
        self.path = path
        self.caseSensitive = caseSensitive
        self.end = end
    }
}

func matchPath(_ pattern: PathPattern, pathname: String) -> Match? {
    let (matcher, parameterNames) = compilePath(path: pattern.path, caseSensitive: pattern.caseSensitive, end: pattern.end)
    
    guard let match = pathname.firstMatch(matcher) else {
        return nil
    }
    
    let matchedPathname = match[0].value
    let splatRegex = try! RegExp(pattern: "(.)/+$")
    var pathnameBase = matchedPathname.replacingMatches(of: splatRegex, with: "$1")
    let captureGroups = match.suffix(from: 1)
    let parameters = parameterNames.indices.reduce([:] as [String : String]) { memo, index in
        let captureGroupIndex = captureGroups.startIndex.advanced(by: index)
        let splatValue = captureGroups[safe: captureGroupIndex]?.value ?? ""
        
        let parameterName = parameterNames[index]
        if parameterName == "*" {
            let start = matchedPathname.startIndex
            let end = matchedPathname.index(start, offsetBy: matchedPathname.count - splatValue.count)
            pathnameBase = matchedPathname[start..<end]
                .replacingMatches(of: splatRegex, with: "$1")
        }
        
        var memo = memo
        memo[parameterName] = String(splatValue)
        return memo
    }
    
    return Match(pattern: pattern, pathname: matchedPathname, pathnameBase: pathnameBase, parameters: parameters)
}

class ReactRouter: ObservableObject {
    @Published var route: ReactRoute = .root
    
    func navigate(to path: String) {
        
    }
}

struct RouteContext {
    let router: ReactRouter
    let match: Match
}

struct RouteNode<Destination: View>: View {
    let path: String
    let destination: (Match) -> Destination
    
    @State var isActive: Bool = false
    
    init(path: String, @ViewBuilder destination: @escaping (Match) -> Destination) {
        self.path = path
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink(isActive: $isActive) {
            VStack(spacing: 0) {
                EmptyView()
//                destination(Match(path: "", parameters: [:]))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } label: { EmptyView() }
    }
}

struct RouteTree<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct UsageView: View {
    var body: some View {
        RouteTree {
            Text("Home")
            
            RouteNode(path: "cards/:cardId") { card in
                Text("Card")
                
                RouteNode(path: "transactions/:transactionId") { transaction in
                    Text("Transaction")
                }
            }
            
            RouteNode(path: "account") { account in
                Text("Account")
                
                RouteNode(path: "terminated-cards") { terminatedCards in
                    Text("Terminated Cards")
                    
                    RouteNode(path: ":cardId") { terminatedCard in
                        Text("Terminated Card")
                        
                        RouteNode(path: "tranasctions/:transactionId") { transaction in
                            Text("Transactions")
                        }
                    }
                }
                
                RouteNode(path: "profile") { profile in
                    Text("Profile")
                }
            }
        }
    }
}
