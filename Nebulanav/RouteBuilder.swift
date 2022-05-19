import SwiftUI

class Router: ObservableObject {
    func isActive(path: String) -> Binding<Bool> {
        fatalError()
    }
}

struct Location {
    let pathname: String
    let key: String
}

struct LocationEnvironmentKey: EnvironmentKey {
    static var defaultValue = Location(pathname: "/", key: "default")
}

struct MatchEnvironmentKey: EnvironmentKey {
    static var defaultValue = PathMatch(
        pattern: PathPattern(path: "/"),
        pathname: "/",
        pathnameBase: "/",
        parameters: [:]
    )
}

struct ParentPathEnvironmentKey: EnvironmentKey {
    static var defaultValue = "/"
}

extension EnvironmentValues {
    var parentPath: ParentPathEnvironmentKey {
        get { self[ParentPathEnvironmentKey.self] }
        set { self[ParentPathEnvironmentKey.self] = newValue }
    }
    
    var location: Location {
        get { self[LocationEnvironmentKey.self] }
        set { self[LocationEnvironmentKey.self] = newValue }
    }
    
    var match: PathMatch {
        get { self[MatchEnvironmentKey.self] }
        set { self[MatchEnvironmentKey.self] = newValue }
    }
}

func useMatch(from location: Location, pattern: PathPattern) -> PathMatch? {
    matchPath(pattern, pathname: location.pathname)
}

struct Route<Destination: View, Children: View>: View {
    @EnvironmentObject var router: Router
    
    let path: String
    let destination: Destination
    let children: Children
    
    init(path: String, @ViewBuilder destination: () -> Destination, @ViewBuilder children: () -> Children) {
        self.path = path
        self.destination = destination()
        self.children = children()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(isActive: router.isActive(path: path)) {
                destination
            }
            
            children
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension NavigationLink where Label == EmptyView {
    init(isActive: Binding<Bool>, @ViewBuilder destination: () -> Destination) {
        self.init(isActive: isActive, destination: destination, label: { EmptyView() })
    }
}

struct SwiftRouter<Content: View>: View {
    @StateObject var router = Router()
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(router)
    }
}

struct Routes<Root: View, Content: View>: View {
    let root: Root
    let content: Content
    
    init(@ViewBuilder root: () -> Root, @ViewBuilder content: () -> Content) {
        self.root = root()
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                root
                content
            }
        }
    }
}

struct Example2View: View {
    var body: some View {
        Routes(root: { Text("Root") }) {
            Route(path: "cards", destination: { Text("Cards") }) {
                
            }
        }
    }
}

struct RouteNode<Destination: View>: View {
    let path: String
    let destination: (PathMatch) -> Destination
    
    @State var isActive: Bool = false
    
    init(path: String, @ViewBuilder destination: @escaping (PathMatch) -> Destination) {
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
