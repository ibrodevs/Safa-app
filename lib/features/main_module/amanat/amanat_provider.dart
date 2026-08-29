import 'dart:async';

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
  AmanatCampaign? _featuredCampaign;

  Timer? _liveTimer;
  int? _activePollingCampaignId;

  List<AmanatCategory> get categories => List.unmodifiable(_categories);
  List<AmanatCampaign> get campaigns => List.unmodifiable(_campaigns);

  String? _selectedCategorySlug;
  String? get selectedCategorySlug => _selectedCategorySlug;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  AmanatCampaign? get featuredCampaign => _featuredCampaign;

  AmanatCampaign? _pickFeatured(List<AmanatCampaign> campaigns) {
    for (final campaign in campaigns) {
      if (_isMedreseCampaign(campaign)) return campaign;
    }
    for (final campaign in campaigns) {
      if (campaign.isFeatured) return campaign;
    }
    return campaigns.isEmpty ? null : campaigns.first;
  }

  bool _isMedreseCampaign(AmanatCampaign campaign) {
    final title = '${campaign.title} ${campaign.shortTitle}'.toLowerCase();
    return campaign.categorySlug == 'education' ||
        title.contains('медрес') ||
        title.contains('medrese') ||
        title.contains('madras');
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final categories = await _repository.loadCategories();
      final allCampaigns = _selectedCategorySlug == null
          ? null
          : await _repository.loadCampaigns();
      final campaigns = await _repository.loadCampaigns(
        categorySlug: _selectedCategorySlug,
      );
      _featuredCampaign = _pickFeatured(allCampaigns ?? campaigns);
      _categories
        ..clear()
        ..addAll(categories);
      _campaigns
        ..clear()
        ..addAll(campaigns);
      if (!silent) {
        _error = null;
      }
    } catch (e) {
      if (!silent) {
        _error = friendlyErrorMessage(
          e,
          fallback: 'Не удалось загрузить Safa Amanat',
        );
      }
    } finally {
      if (!silent) {
        _loading = false;
      }
      notifyListeners();
    }
  }

  Future<void> selectCategory(String? slug) async {
    if (_selectedCategorySlug == slug) return;
    _selectedCategorySlug = slug;
    await load();
  }

  Future<AmanatCampaign?> refreshCampaign(int id, {bool silent = false}) async {
    if (!silent) {
      _error = null;
      notifyListeners();
    }
    try {
      final updated = await _repository.loadCampaign(id);
      final index = _campaigns.indexWhere((campaign) => campaign.id == id);
      if (index >= 0) {
        _campaigns[index] = updated;
      } else {
        _campaigns.add(updated);
      }
      if (_featuredCampaign?.id == updated.id || updated.isFeatured) {
        _featuredCampaign = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      if (!silent) {
        _error = friendlyErrorMessage(e, fallback: 'Не удалось загрузить сбор');
        notifyListeners();
      }
      return null;
    }
  }

  /// Starts periodic background polling for live updates of Amanat stats.
  void startLiveUpdates({
    int? campaignId,
    Duration interval = const Duration(seconds: 8),
  }) {
    _activePollingCampaignId = campaignId;
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(interval, (_) async {
      if (_activePollingCampaignId != null) {
        await refreshCampaign(_activePollingCampaignId!, silent: true);
      } else {
        await load(silent: true);
      }
    });
  }

  /// Stops periodic live updates.
  void stopLiveUpdates() {
    _liveTimer?.cancel();
    _liveTimer = null;
    _activePollingCampaignId = null;
  }

  @override
  void dispose() {
    stopLiveUpdates();
    super.dispose();
  }
}
