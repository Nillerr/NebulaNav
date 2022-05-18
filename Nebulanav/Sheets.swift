enum Sheet: Identifiable {
    case login
    case mfaEnrollment(MFAEnrollmentRequirement)
    case mfaChallenge(MFAChallengeRequirement)
    case personalDetails
    case biometricPrompt
    
    case requestCard(success: () -> Void)
    case comment(success: (String) -> Void)
    case attachment(success: () -> Void)
    case addAttachment(success: () -> Void)
    
    var id: String {
        switch self {
        case .login:
            return "login"
        case .mfaEnrollment(_):
            return "mfa_enrollment"
        case .mfaChallenge(_):
            return "mfa_challenge"
        case .personalDetails:
            return "personal_details"
        case .biometricPrompt:
            return "biometric_prompt"
        case .requestCard(_):
            return "request_card"
        case .comment(_):
            return "comment"
        case .attachment(_):
            return "attachment"
        case .addAttachment(_):
            return "add_attachment"
        }
    }
}
