@testable import Nebulanav
import XCTest

class MatchPath_Tests: XCTestCase {
    func test_matches_the_root_URL() {
        let pattern = PathPattern(path: "/")
        let match = matchPath(pattern, pathname: "/")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/",
            pathnameBase: "/",
            parameters: [:]
        ))
    }
}

class MatchPath_WhenThePatternHasNoLeadingSlash_Tests: XCTestCase {
    func test_fails_to_match_a_pathname_that_does_not_match() {
        let pattern = PathPattern(path: "users")
        let match = matchPath(pattern, pathname: "/usersblash")
        XCTAssertNil(match)
    }
    
    func test_matches_a_pathname() {
        let pattern = PathPattern(path: "users")
        let match = matchPath(pattern, pathname: "/users")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/users",
            pathnameBase: "/users",
            parameters: [:]
        ))
    }
    
    func test_matches_a_pathname_with_multiple_segments() {
        let pattern = PathPattern(path: "users/mj")
        let match = matchPath(pattern, pathname: "/users/mj")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/users/mj",
            pathnameBase: "/users/mj",
            parameters: [:]
        ))
    }
    
    func test_matches_a_pathname_with_a_trailing_slash() {
        let pattern = PathPattern(path: "users")
        let match = matchPath(pattern, pathname: "/users/")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/users/",
            pathnameBase: "/users",
            parameters: [:]
        ))
    }
    
    func test_matches_a_pathname_with_multiple_segments_and_a_trailing_slash() {
        let pattern = PathPattern(path: "users/mj")
        let match = matchPath(pattern, pathname: "/users/mj/")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/users/mj/",
            pathnameBase: "/users/mj",
            parameters: [:]
        ))
    }
}

func when(_ label: String, block: () -> Void) {
    block()
}

class MatchPath_WithEndFalse_Tests: XCTestCase {
    func test_matches_the_beginning_of_a_pathname() {
        when("path has no trailing slash") {
            let pattern = PathPattern(path: "/users", end: false)
            let match = matchPath(pattern, pathname: "/users")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/users",
                parameters: [:]
            ))
        }
        
        when("path has trailing slash") {
            let pattern = PathPattern(path: "/users/", end: false)
            let match = matchPath(pattern, pathname: "/users")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/users",
                parameters: [:]
            ))
        }
    }
    
    func test_matches_the_beginning_of_a_pathname_with_a_trailing_slash() {
        when("path has no trailing slash") {
            let pattern = PathPattern(path: "/users", end: false)
            let match = matchPath(pattern, pathname: "/users/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/users",
                parameters: [:]
            ))
        }
        
        when("path has trailing slash") {
            let pattern = PathPattern(path: "/users/", end: false)
            let match = matchPath(pattern, pathname: "/users/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/users",
                parameters: [:]
            ))
        }
    }
    
    func test_matches_the_beginning_of_a_pathname_with_multiple_segments() {
        when("path has no trailing slash") {
            let pattern = PathPattern(path: "/users", end: false)
            let match = matchPath(pattern, pathname: "/users/mj")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/users",
                parameters: [:]
            ))
        }
        
        when("path has trailing slash") {
            let pattern = PathPattern(path: "/users/", end: false)
            let match = matchPath(pattern, pathname: "/users/mj")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/users",
                parameters: [:]
            ))
        }
    }
    
    func test_matches_the_beginning_of_a_pathname_with_multiple_segments_and_a_trailing_slash() {
        when("path has no trailing slash") {
            let pattern = PathPattern(path: "/users", end: false)
            let match = matchPath(pattern, pathname: "/users/mj/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/users",
                parameters: [:]
            ))
        }
        
        when("path has trailing slash") {
            let pattern = PathPattern(path: "/users/", end: false)
            let match = matchPath(pattern, pathname: "/users/mj/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/users",
                parameters: [:]
            ))
        }
    }
    
    func test_fails_to_match_a_pathname_where_the_segments_do_not_match() {
        when("pathname is root") {
            let pattern = PathPattern(path: "/users", end: false)
            let match = matchPath(pattern, pathname: "/")
            XCTAssertNil(match)
        }
        
        when("pathname is other") {
            let pattern = PathPattern(path: "/users", end: false)
            let match = matchPath(pattern, pathname: "/users2")
            XCTAssertNil(match)
        }
        
        when("multiple segments and pathname is other") {
            let pattern = PathPattern(path: "/users/mj", end: false)
            let match = matchPath(pattern, pathname: "/users/mj2")
            XCTAssertNil(match)
        }
    }
}

class MatchPath_WithEndFalse_AndARootPattern_Tests: XCTestCase {
    func test_matches_a_pathname() {
        let pattern = PathPattern(path: "/", end: false)
        let match = matchPath(pattern, pathname: "/users")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/",
            pathnameBase: "/",
            parameters: [:]
        ))
    }
    
    func test_matches_a_pathname_with_multiple_segments() {
        let pattern = PathPattern(path: "/", end: false)
        let match = matchPath(pattern, pathname: "/users/mj")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/",
            pathnameBase: "/",
            parameters: [:]
        ))
    }
    
    func test_matches_a_pathname_with_a_trailing_slash() {
        let pattern = PathPattern(path: "/", end: false)
        let match = matchPath(pattern, pathname: "/users/")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/",
            pathnameBase: "/",
            parameters: [:]
        ))
    }
    
    func test_matches_a_pathname_with_multiple_segments_and_a_trailing_slash() {
        let pattern = PathPattern(path: "/", end: false)
        let match = matchPath(pattern, pathname: "/users/mj/")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/",
            pathnameBase: "/",
            parameters: [:]
        ))
    }
    
    func test_is_not_case_sensitive_by_default() {
        let pattern = PathPattern(path: "/SystemDashboard")
        let match = matchPath(pattern, pathname: "/systemdashboard")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/systemdashboard",
            pathnameBase: "/systemdashboard",
            parameters: [:]
        ))
    }
    
    func test_matches_a_case_sensitive_pathname() {
        let pattern = PathPattern(path: "/SystemDashboard", caseSensitive: true)
        let match = matchPath(pattern, pathname: "/SystemDashboard")
        XCTAssertEqual(match, Match(
            pattern: pattern,
            pathname: "/SystemDashboard",
            pathnameBase: "/SystemDashboard",
            parameters: [:]
        ))
    }
    
    func test_does_not_match_a_case_sensitive_pathname_with_the_wrong_case() {
        let pattern = PathPattern(path: "/SystemDashboard", caseSensitive: true)
        let match = matchPath(pattern, pathname: "/systemdashboard")
        XCTAssertNil(match)
    }
}

class MatchPath_WithEndFalse_AndARootPattern_WhenThePatternHasATrailingSlashStar_Tests: XCTestCase {
    func test_matches_the_remaining_portion_of_the_pathname() {
        when("pathname is jpg file") {
            let pattern = PathPattern(path: "/files/*")
            let match = matchPath(pattern, pathname: "/files/mj.jpg")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/files/mj.jpg",
                pathnameBase: "/files",
                parameters: ["*" : "mj.jpg"]
            ))
        }
        
        when("pathname has trailing slash") {
            let pattern = PathPattern(path: "/files/*")
            let match = matchPath(pattern, pathname: "/files/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/files/",
                pathnameBase: "/files",
                parameters: ["*" : ""]
            ))
        }
        
        when("pathname has no trailing slash") {
            let pattern = PathPattern(path: "/files/*")
            let match = matchPath(pattern, pathname: "/files")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/files",
                pathnameBase: "/files",
                parameters: ["*" : ""]
            ))
        }
    }
}

class MatchPath_Star_Tests: XCTestCase {
    func test_matches_the_root_URL() {
        when("pattern is *") {
            let pattern = PathPattern(path: "*")
            let match = matchPath(pattern, pathname: "/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/",
                pathnameBase: "/",
                parameters: ["*" : ""]
            ))
        }
        
        when("pattern is /*") {
            let pattern = PathPattern(path: "/*")
            let match = matchPath(pattern, pathname: "/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/",
                pathnameBase: "/",
                parameters: ["*" : ""]
            ))
        }
    }
    
    func test_matches_a_URL_with_a_segment() {
        when("pattern is *") {
            let pattern = PathPattern(path: "*")
            let match = matchPath(pattern, pathname: "/users")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/",
                parameters: ["*" : "users"]
            ))
        }
        
        when("pattern is /*") {
            let pattern = PathPattern(path: "/*")
            let match = matchPath(pattern, pathname: "/users")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users",
                pathnameBase: "/",
                parameters: ["*" : "users"]
            ))
        }
    }
    
    func test_matches_a_URL_with_a_segment_and_a_trailing_slash() {
        when("pattern is *") {
            let pattern = PathPattern(path: "*")
            let match = matchPath(pattern, pathname: "/users/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users/",
                pathnameBase: "/",
                parameters: ["*" : "users/"]
            ))
        }
        
        when("pattern is /*") {
            let pattern = PathPattern(path: "/*")
            let match = matchPath(pattern, pathname: "/users/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users/",
                pathnameBase: "/",
                parameters: ["*" : "users/"]
            ))
        }
    }
    
    func test_matches_a_URL_with_multiple_segments() {
        when("pattern is *") {
            let pattern = PathPattern(path: "*")
            let match = matchPath(pattern, pathname: "/users/mj")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users/mj",
                pathnameBase: "/",
                parameters: ["*" : "users/mj"]
            ))
        }
        
        when("pattern is /*") {
            let pattern = PathPattern(path: "/*")
            let match = matchPath(pattern, pathname: "/users/mj")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users/mj",
                pathnameBase: "/",
                parameters: ["*" : "users/mj"]
            ))
        }
    }
    
    func test_matches_a_URL_with_multiple_segments_and_a_trailing_slash() {
        when("pattern is *") {
            let pattern = PathPattern(path: "*")
            let match = matchPath(pattern, pathname: "/users/mj/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users/mj/",
                pathnameBase: "/",
                parameters: ["*" : "users/mj/"]
            ))
        }
        
        when("pattern is /*") {
            let pattern = PathPattern(path: "/*")
            let match = matchPath(pattern, pathname: "/users/mj/")
            XCTAssertEqual(match, Match(
                pattern: pattern,
                pathname: "/users/mj/",
                pathnameBase: "/",
                parameters: ["*" : "users/mj/"]
            ))
        }
    }
}
