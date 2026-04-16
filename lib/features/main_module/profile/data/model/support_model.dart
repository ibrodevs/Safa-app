class SupportModel {
  final String phone;
  final String telegram;
  final String workingHours;
  final String message;

  SupportModel({
    required this.phone,
    required this.telegram,
    required this.workingHours,
    required this.message,
  });

  factory SupportModel.fromJson(Map<String, dynamic> json) {
    return SupportModel(
      phone: json['phone']?.toString() ?? '',
      telegram: json['telegram']?.toString() ?? '',
      workingHours: json['working_hours']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'telegram': telegram,
      'working_hours': workingHours,
      'message': message,
    };
  }
}
