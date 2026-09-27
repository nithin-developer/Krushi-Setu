class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String provider;
  final String preferredLanguage;
  final String? profileImage;
  final bool profileCompleted;
  final String status;
  final Map<String, dynamic>? digitalTwin;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.provider,
    required this.preferredLanguage,
    this.profileImage,
    required this.profileCompleted,
    required this.status,
    this.digitalTwin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? 'Farmer',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'],
      provider: json['provider'] ?? 'email',
      preferredLanguage: json['preferred_language'] ?? 'en',
      profileImage: json['profile_image'],
      profileCompleted: json['profile_completed'] ?? false,
      status: json['status'] ?? 'active',
      digitalTwin: json['digital_twin'] is Map<String, dynamic> ? json['digital_twin'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'provider': provider,
      'preferred_language': preferredLanguage,
      'profile_image': profileImage,
      'profile_completed': profileCompleted,
      'status': status,
      'digital_twin': digitalTwin,
    };
  }
}
