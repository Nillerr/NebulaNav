import SwiftUI

struct RoutesView<Routes: LevelRouter, Content: View, Detail: View>: View {
    @EnvironmentObject var router: Router
    
    @ObservedObject var routes: Routes
    
    @ViewBuilder let content: (Routes.Screen) -> Content
    @ViewBuilder let detail: (Routes.DetailRouter) -> Detail
    
    var body: some View {
        VStack(spacing: 0) {
            content(routes.screen)
                .environmentObject(router)
            
            BetterNavigationLink(item: $routes.detail) {
                detail($0)
                    .environmentObject(router)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LevelOneRoutes: View {
    @EnvironmentObject var router: Router
    
    @ObservedObject var routes: LevelOneRouter
    
    var body: some View {
        RoutesView(routes: routes) { screen in
            switch screen {
            case .cardDetails(let card):
                CardDetailsView(card: card) { transaction in
                    router.navigate(to: .transactionDetails(card, transaction))
                }
            case .account:
                AccountView()
            }
        } detail: { detail in
            LevelTwoRoutes(routes: detail)
        }
    }
}

struct LevelTwoRoutes: View {
    @EnvironmentObject var router: Router
    
    @ObservedObject var routes: LevelTwoRouter
    
    var body: some View {
        RoutesView(routes: routes) { screen in
            switch screen {
            case .transactionDetails(let transaction):
                TransactionDetailsView(transaction: transaction)
            case .terminatedCards:
                TerminatedCardsView()
            case .contact:
                ProfileView()
            }
        } detail: { detail in
            LevelThreeRoutes(routes: detail)
        }
    }
}

struct LevelThreeRoutes: View {
    @EnvironmentObject var router: Router
    
    @ObservedObject var routes: LevelThreeRouter
    
    var body: some View {
        RoutesView(routes: routes) { screen in
            switch screen {
            case .terminatedCardDetails(let card):
                TerminatedCardDetailsView(card: card)
            }
        } detail: { detail in
            LevelFourRoutes(routes: detail)
        }
    }
}

struct LevelFourRoutes: View {
    @EnvironmentObject var router: Router
    
    @ObservedObject var routes: LevelFourRouter
    
    var body: some View {
        VStack(spacing: 0) {
            switch routes.screen {
            case .transactionDetails(let transaction):
                TransactionDetailsView(transaction: transaction)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
