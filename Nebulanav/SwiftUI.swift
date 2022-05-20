import SwiftUI

extension NavigationLink where Label == EmptyView {
    init<Item, Content: View>(item: Binding<Item?>, @ViewBuilder destination: (Item) -> Content) where Destination == Content? {
        self.init(isActive: Binding(get: { item.wrappedValue != nil }, set: { newValue in
            if !newValue {
                item.wrappedValue = nil
            }
        })) {
            if let item = item.wrappedValue {
                destination(item)
            }
        } label: { EmptyView() }
    }
    
    init(isActive: Binding<Bool>, @ViewBuilder destination: () -> Destination) {
        self.init(isActive: isActive, destination: destination) { EmptyView() }
    }
}
