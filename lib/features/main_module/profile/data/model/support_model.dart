class FaqItemModel {
  final int id;
  final String question;
  final String answer;
  final int sortOrder;

  const FaqItemModel({
    required this.id,
    required this.question,
    required this.answer,
    this.sortOrder = 0,
  });

  factory FaqItemModel.fromJson(Map<String, dynamic> json) {
    return FaqItemModel(
      id: json['id'] is int ? json['id'] as int : 0,
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      sortOrder: json['sort_order'] is int ? json['sort_order'] as int : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'sort_order': sortOrder,
      };
}

class SupportModel {
  final String phone;
  final String telegram;
  final String whatsapp;
  final String workingHours;
  final String message;
  final bool isActive;
  final List<FaqItemModel> faqs;

  SupportModel({
    required this.phone,
    required this.telegram,
    required this.whatsapp,
    required this.workingHours,
    required this.message,
    this.isActive = true,
    this.faqs = const [],
  });

  factory SupportModel.fromJson(Map<String, dynamic> json) {
    final phoneVal = json['phone']?.toString() ?? '';
    final faqsRaw = json['faqs'];
    final faqsList = <FaqItemModel>[];
    if (faqsRaw is List) {
      for (final item in faqsRaw) {
        if (item is Map<String, dynamic>) {
          faqsList.add(FaqItemModel.fromJson(item));
        }
      }
    }

    return SupportModel(
      phone: phoneVal,
      telegram: json['telegram']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? phoneVal,
      workingHours: json['working_hours']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isActive: json['is_active'] != false,
      faqs: faqsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'telegram': telegram,
      'whatsapp': whatsapp,
      'working_hours': workingHours,
      'message': message,
      'is_active': isActive,
      'faqs': faqs.map((f) => f.toJson()).toList(),
    };
  }
}
