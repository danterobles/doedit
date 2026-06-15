import TUIkit

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, TUIkit!")
                .foregroundStyle(.palette.accent)
                .bold()

            Text("Welcome to your new terminal app")
                .foregroundStyle(.palette.foregroundSecondary)
        }
        .padding()
    }
}
