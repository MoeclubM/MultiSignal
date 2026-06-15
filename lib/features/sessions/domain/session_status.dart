enum SessionStatus {
  completed,
  interrupted,
  error;

  static SessionStatus fromJson(String value) =>
      SessionStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => SessionStatus.error,
      );
}
