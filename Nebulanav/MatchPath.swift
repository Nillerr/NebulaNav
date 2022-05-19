struct PathMatch: Equatable {
    let pattern: PathPattern
    let pathname: String
    internal let pathnameBase: String
    let parameters: [String : String]
}

func compilePath(path: String, caseSensitive: Bool = false, end: Bool = false) -> (RegExp, [String]) {
    var regexpSource = "^" + path
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

func matchPath(_ pattern: PathPattern, pathname: String) -> PathMatch? {
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
    
    return PathMatch(pattern: pattern, pathname: matchedPathname, pathnameBase: pathnameBase, parameters: parameters)
}
