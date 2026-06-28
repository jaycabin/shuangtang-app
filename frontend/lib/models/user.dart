class User {
  final String id;
  final String email;
  final String nickname;
  final String avatarUrl;
  final String preferredLanguage;

  User({
    required this.id,
    required this.email,
    this.nickname = '',
    this.avatarUrl = '',
    this.preferredLanguage = 'zh',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      preferredLanguage: json['preferred_language'] ?? 'zh',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nickname': nickname,
    'avatar_url': avatarUrl,
    'preferred_language': preferredLanguage,
  };
}

class Moment {
  final String id;
  final String type;
  final String content;
  final List<String> imageUrls;
  final String moodTag;
  final String createdAt;

  Moment({
    required this.id,
    this.type = 'moment',
    this.content = '',
    this.imageUrls = const [],
    this.moodTag = '',
    required this.createdAt,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'] ?? '',
      type: json['type'] ?? 'moment',
      content: json['content'] ?? '',
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? [],
      moodTag: json['mood_tag'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Couple {
  final String id;
  final String invitationCode;
  final String status;

  Couple({
    required this.id,
    required this.invitationCode,
    this.status = 'pending',
  });

  factory Couple.fromJson(Map<String, dynamic> json) {
    return Couple(
      id: json['id'] ?? '',
      invitationCode: json['invitation_code'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}
