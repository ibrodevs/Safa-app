import 'package:flutter/foundation.dart';

import '../../../core/utils/friendly_error.dart';
import 'amanat_models.dart';
import 'amanat_repository.dart';

class AmanatProvider extends ChangeNotifier {
  AmanatProvider({AmanatRepository? repository})
    : _repository = repository ?? AmanatRepository();

  final AmanatRepository _repository;

  final List<AmanatCategory> _categories = [];
  final List<AmanatCampaign> _campaigns = [];

  List<AmanatCategory> get categories => List.unmodifiable(_categories);
  List<AmanatCampaign> get campaigns => List.unmodifiable(_campaigns);

  String? _selectedCategorySlug;
  String? get selectedCategorySlug => _selectedCategorySlug;

  bool _loading = false;
  bool get loading => _loading;

  bool _donating = false;
  bool get donating => _donating;

  String? _error;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  AmanatCampaign? get featuredCampaign {
    for (final campaign in _campaigns) {
      if (campaign.isFeatured) return campaign;
    }
    return _campaigns.isEmpty ? null : _campaigns.first;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final categories = await _repository.loadCategories();
      final campaigns = await _repository.loadCampaigns(
        categorySlug: _selectedCategorySlug,
      );
      _categories
        ..clear()
        ..addAll(categories);
      _campaigns
        ..clear()
        ..addAll(campaigns);
    } catch (e) {
      _error = friendlyErrorMessage(
        e,
        fallback: 'Не удалось загрузить Safa Amanat',
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(String? slug) async {
    if (_selectedCategorySlug == slug) return;
    _selectedCategorySlug = slug;
    await load();
  }

  Future<AmanatCampaign?> refreshCampaign(int id) async {
    _error = null;
    notifyListeners();
    try {
      final updated = await _repository.loadCampaign(id);
      final index = _campaigns.indexWhere((campaign) => campaign.id == id);
      if (index >= 0) {
        _campaigns[index] = updated;
      } else {
        _campaigns.add(updated);
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: 'Не удалось загрузить сбор');
      notifyListeners();
      return null;
    }
  }

  Future<bool> donate({
    required AmanatCampaign campaign,
    required int amount,
    bool isAnonymous = false,
  }) async {
    _donating = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.donate(
        campaignId: campaign.id,
        amount: amount,
        isAnonymous: isAnonymous,
      );
      await refreshCampaign(campaign.id);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(
        e,
        fallback: 'Не удалось отправить пожертвование',
      );
      return false;
    } finally {
      _donating = false;
      notifyListeners();
    }
  }
}
