import Foundation

struct RegExp {
    typealias Options = NSRegularExpression.Options
    typealias MatchingOptions = NSRegularExpression.MatchingOptions
    typealias Match = [SingleMatch]
    
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
