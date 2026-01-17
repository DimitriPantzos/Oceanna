import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if authService.currentUser == nil {
                AuthenticationView()
            } else if let user = authService.userProfile {
                switch user.approvalStatus {
                case .approved:
                    MainTabView()
                case .pending:
                    PendingApprovalView()
                case .waitlisted:
                    WaitlistView()
                }
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
