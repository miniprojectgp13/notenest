class ProfileField {
  ProfileField({required this.label, required this.value});

  String label;
  String value;

  Map<String, dynamic> toJson() {
    return {'label': label, 'value': value};
  }

  factory ProfileField.fromJson(Map<String, dynamic> json) {
    return ProfileField(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

class UserProfile {
  UserProfile({
    required this.name,
    required this.bio,
    required this.emoji,
    required this.uniqueId,
    required this.additionalNote,
    required this.extraFields,
    this.avatarPath,
  });

  String name;
  String bio;
  String emoji;
  String uniqueId;
  String additionalNote;
  List<ProfileField> extraFields;
  String? avatarPath;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bio': bio,
      'emoji': emoji,
      'uniqueId': uniqueId,
      'additionalNote': additionalNote,
      'extraFields': extraFields.map((field) => field.toJson()).toList(),
      'avatarPath': avatarPath,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawFields = json['extraFields'];
    final fields = <ProfileField>[];
    if (rawFields is List) {
      for (final field in rawFields) {
        if (field is Map<String, dynamic>) {
          fields.add(ProfileField.fromJson(field));
        } else if (field is Map) {
          fields.add(ProfileField.fromJson(Map<String, dynamic>.from(field)));
        }
      }
    }

    return UserProfile(
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🤓',
      uniqueId: json['uniqueId'] as String? ?? '',
      additionalNote: json['additionalNote'] as String? ?? '',
      extraFields: fields,
      avatarPath: json['avatarPath'] as String?,
    );
  }
}
