import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var currentStep = 0
    @State private var city = ""
    @State private var skills: [String] = []
    @State private var lookingFor: [String] = []
    @State private var availability: Availability = .both
    @State private var isHireable = true
    @State private var newSkill = ""
    @State private var newLookingFor = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let steps = ["Location", "Skills", "Looking For", "Availability", "Ready"]

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: OceannaTheme.Spacing.xs) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStep ? OceannaTheme.Colors.primary : OceannaTheme.Colors.divider)
                        .frame(height: 2)
                }
            }
            .padding(.horizontal, OceannaTheme.Spacing.lg)
            .padding(.top, OceannaTheme.Spacing.md)

            // Content
            TabView(selection: $currentStep) {
                locationStep.tag(0)
                skillsStep.tag(1)
                lookingForStep.tag(2)
                availabilityStep.tag(3)
                readyStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .background(OceannaTheme.Colors.background)
    }

    private var locationStep: some View {
        OnboardingStepView(
            title: "Where are you based?",
            subtitle: "This helps connect you with local talent and opportunities."
        ) {
            TextField("City, State", text: $city)
                .textFieldStyle(OceannaTextFieldStyle())
        } action: {
            if !city.isEmpty { currentStep = 1 }
        }
    }

    private var skillsStep: some View {
        OnboardingStepView(
            title: "What do you do?",
            subtitle: "Add your skills and services."
        ) {
            VStack(spacing: OceannaTheme.Spacing.md) {
                HStack {
                    TextField("Add a skill", text: $newSkill)
                        .textFieldStyle(OceannaTextFieldStyle())

                    Button {
                        if !newSkill.isEmpty {
                            skills.append(newSkill)
                            newSkill = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(OceannaTheme.Colors.primary)
                    }
                }

                FlowLayout(spacing: OceannaTheme.Spacing.xs) {
                    ForEach(skills, id: \.self) { skill in
                        HStack(spacing: OceannaTheme.Spacing.xxs) {
                            Text(skill)
                            Button {
                                skills.removeAll { $0 == skill }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                            }
                        }
                        .monoTag()
                    }
                }
            }
        } action: {
            currentStep = 2
        }
    }

    private var lookingForStep: some View {
        OnboardingStepView(
            title: "What are you looking for?",
            subtitle: "Skills or services you might want to hire."
        ) {
            VStack(spacing: OceannaTheme.Spacing.md) {
                HStack {
                    TextField("Add what you're looking for", text: $newLookingFor)
                        .textFieldStyle(OceannaTextFieldStyle())

                    Button {
                        if !newLookingFor.isEmpty {
                            lookingFor.append(newLookingFor)
                            newLookingFor = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(OceannaTheme.Colors.primary)
                    }
                }

                FlowLayout(spacing: OceannaTheme.Spacing.xs) {
                    ForEach(lookingFor, id: \.self) { item in
                        HStack(spacing: OceannaTheme.Spacing.xxs) {
                            Text(item)
                            Button {
                                lookingFor.removeAll { $0 == item }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                            }
                        }
                        .monoTag()
                    }
                }
            }
        } action: {
            currentStep = 3
        }
    }

    private var availabilityStep: some View {
        OnboardingStepView(
            title: "How do you prefer to work?",
            subtitle: "Let others know your availability."
        ) {
            VStack(spacing: OceannaTheme.Spacing.md) {
                ForEach(Availability.allCases, id: \.self) { option in
                    Button {
                        availability = option
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .font(OceannaTheme.Typography.body)
                                .foregroundColor(OceannaTheme.Colors.primaryText)
                            Spacer()
                            if availability == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(OceannaTheme.Colors.primary)
                            }
                        }
                        .padding(OceannaTheme.Spacing.md)
                        .background(OceannaTheme.Colors.secondaryBackground)
                        .cornerRadius(OceannaTheme.Radius.sm)
                    }
                }

                Divider().padding(.vertical, OceannaTheme.Spacing.sm)

                Toggle(isOn: $isHireable) {
                    VStack(alignment: .leading, spacing: OceannaTheme.Spacing.xxs) {
                        Text("Available for hire")
                            .font(OceannaTheme.Typography.body)
                            .foregroundColor(OceannaTheme.Colors.primaryText)
                        Text("Show up in discovery for people looking to hire")
                            .font(OceannaTheme.Typography.caption)
                            .foregroundColor(OceannaTheme.Colors.secondaryText)
                    }
                }
                .tint(OceannaTheme.Colors.primary)
            }
        } action: {
            currentStep = 4
        }
    }

    private var readyStep: some View {
        OnboardingStepView(
            title: "You're all set!",
            subtitle: "Your profile will be reviewed by our team. We'll notify you once approved."
        ) {
            VStack(spacing: OceannaTheme.Spacing.lg) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(OceannaTheme.Colors.primary)

                if let error = errorMessage {
                    Text(error)
                        .font(OceannaTheme.Typography.caption)
                        .foregroundColor(.red)
                }
            }
        } action: {
            submitOnboarding()
        } actionLabel: {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Submit for Review")
            }
        }
    }

    private func submitOnboarding() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.completeOnboarding(
                    city: city,
                    skills: skills,
                    lookingFor: lookingFor,
                    availability: availability,
                    isHireable: isHireable
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct OnboardingStepView<Content: View, ActionLabel: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content
    let action: () -> Void
    @ViewBuilder let actionLabel: () -> ActionLabel

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: @escaping () -> Content,
        action: @escaping () -> Void,
        @ViewBuilder actionLabel: @escaping () -> ActionLabel = { Text("Continue") }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        VStack(spacing: OceannaTheme.Spacing.xl) {
            Spacer()

            VStack(spacing: OceannaTheme.Spacing.sm) {
                Text(title)
                    .font(OceannaTheme.Typography.title2)
                    .foregroundColor(OceannaTheme.Colors.primaryText)

                Text(subtitle)
                    .font(OceannaTheme.Typography.subheadline)
                    .foregroundColor(OceannaTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, OceannaTheme.Spacing.lg)

            content()
                .padding(.horizontal, OceannaTheme.Spacing.lg)

            Spacer()

            Button(action: action) {
                actionLabel()
                    .frame(maxWidth: .infinity)
            }
            .oceannaButton(isPrimary: true)
            .padding(.horizontal, OceannaTheme.Spacing.lg)

            Spacer().frame(height: OceannaTheme.Spacing.xxl)
        }
    }
}

struct OceannaTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(OceannaTheme.Typography.body)
            .padding(OceannaTheme.Spacing.md)
            .background(OceannaTheme.Colors.secondaryBackground)
            .cornerRadius(OceannaTheme.Radius.sm)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService.shared)
}
