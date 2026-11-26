class AdminSecurityPolicy {
  final bool biometricsEnabled;
  final bool enforce2FA;
  final int sessionTimeoutMinutes;
  final int maxConcurrentSessions;

  const AdminSecurityPolicy({
    this.biometricsEnabled = true,
    this.enforce2FA = false,
    this.sessionTimeoutMinutes = 15,
    this.maxConcurrentSessions = 2,
  });

  AdminSecurityPolicy copyWith({
    bool? biometricsEnabled,
    bool? enforce2FA,
    int? sessionTimeoutMinutes,
    int? maxConcurrentSessions,
  }) {
    return AdminSecurityPolicy(
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      enforce2FA: enforce2FA ?? this.enforce2FA,
      sessionTimeoutMinutes:
      sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      maxConcurrentSessions:
      maxConcurrentSessions ?? this.maxConcurrentSessions,
    );
  }
}

class SecurityAuditLog {
  final String id;
  final String actor;
  final String action;
  final String target;
  final DateTime timestamp;

  const SecurityAuditLog({
    required this.id,
    required this.actor,
    required this.action,
    required this.target,
    required this.timestamp,
  });
}