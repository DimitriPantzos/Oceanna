import SwiftUI

struct AuthenticationView: View {
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)

                    Text("Oceanna")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Connect with local creative talent")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                // Content
                if isShowingSignUp {
                    SignUpView(isShowingSignUp: $isShowingSignUp)
                } else {
                    SignInView(isShowingSignUp: $isShowingSignUp)
                }

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    AuthenticationView()
}
