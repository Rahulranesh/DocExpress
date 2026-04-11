/// Notification settings model
class NotificationSettings {
  final bool enabled;
  final bool jobCompletionEnabled;
  final bool jobFailureEnabled;
  final bool progressEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool showInForeground;

  const NotificationSettings({
    this.enabled = true,
    this.jobCompletionEnabled = true,
    this.jobFailureEnabled = true,
    this.progressEnabled = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.showInForeground = true,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? jobCompletionEnabled,
    bool? jobFailureEnabled,
    bool? progressEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? showInForeground,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      jobCompletionEnabled: jobCompletionEnabled ?? this.jobCompletionEnabled,
      jobFailureEnabled: jobFailureEnabled ?? this.jobFailureEnabled,
      progressEnabled: progressEnabled ?? this.progressEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      showInForeground: showInForeground ?? this.showInForeground,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'jobCompletionEnabled': jobCompletionEnabled,
      'jobFailureEnabled': jobFailureEnabled,
      'progressEnabled': progressEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'showInForeground': showInForeground,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      jobCompletionEnabled: json['jobCompletionEnabled'] ?? true,
      jobFailureEnabled: json['jobFailureEnabled'] ?? true,
      progressEnabled: json['progressEnabled'] ?? false,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      showInForeground: json['showInForeground'] ?? true,
    );
  }
}
