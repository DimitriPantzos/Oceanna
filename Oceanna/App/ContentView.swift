import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.currentUser == nil {
                AuthenticationView()
            } else if let user = authViewModel.userProfile {
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
        .environmentObject(AuthViewModel())
}
