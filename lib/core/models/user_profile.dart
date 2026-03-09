class ProfileField {
  ProfileField({required this.label, required this.value});

  String label;
  String value;
}

class UserProfile {
  UserProfile({
    required this.name,
    required this.bio,
    required this.emoji,
    required this.uniqueId,
    required this.additionalNote,
    required this.extraFields,
  });

  String name;
  String bio;
  String emoji;
  String uniqueId;
  String additionalNote;
  List<ProfileField> extraFields;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bio': bio,
      'emoji': emoji,
      'uniqueId': uniqueId,
      'additionalNote': additionalNote,
      'extraFields':
          extraFields
              .map((field) => {'label': field.label, 'value': field.value})
              .toList(),
    };
  }
}
