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
