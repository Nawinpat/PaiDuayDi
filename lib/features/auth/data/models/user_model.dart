class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String provider; // 'google', 'facebook', 'phone'

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
  });
}
