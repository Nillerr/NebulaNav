# Nebula Navigation

This repository contains a proof-of-concept of rich routing in SwiftUI using [Nillerr/Detour](https://github.com/Nillerr/Detour).

It is composed of Flows, Routes, Presentations and Flows as concepts of SwiftUI views, and assumes a rule of no more than one modal presentation at a time.

## Presentations

Presentations presents Flows and Views presented as modals from a root view. Both `sheet` and `fullScreenCover` is supported, and changing the presented view between either of these awaits the dismissal of the other to provide seamless support.

```swift
import Detour

enum TodoPresentations {
  case edit
}

typealias TodoPresenter = Presenter<TodoPresentations>

struct ContentView: View {
  @StateObject var presenter = TodoPresenter()
  
  var body: some View {
    Presentations(presenter: presenter) {
      RootView(edit: { presenter.present(.edit) })
    } content: { presentation in
      switch presentation.presentable {
      case .edit:
        EditView(dismiss: { presenter.dismiss() })
      }
    }
  }
}

```

## Routes

Routes navigates to Views through a `NavigationView`.

```swift
import Detour

enum TodoRoutes: Routeable {
  case todo(TodoDetailViewModel)

  var path: [TodoRoutes] {
    switch self {
    case .todo(let todo):
      return [.todo(todo)]
    }
  }
}

typealias TodoRouter = Router<TodoRoutes>

struct ContentView: View {
  @StateObject var router = TodoRouter()

  var body: some View {
    Routes(router: router) {
      TodoListView(selectTodo: { todo in router.navigate(to: .todo(todo)) })
    } content: { destination in
      switch destination {
      case .todo(let todo):
        TodoDetailView(viewModel: todo, dismiss: { router.navigate(to: nil) })
      }
    }
  }
}
```

## Flows

Flows are navigation flows either using `Routes` or `NavigationView` itself.
