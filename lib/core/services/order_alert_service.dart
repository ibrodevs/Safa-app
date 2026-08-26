import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Звуковое и тактильное оповещение специалиста о найденном заказе.
///
/// Сигнал повторяется до тех пор, пока заказ не принят или не отклонён:
/// специалист может держать телефон в кармане и всё равно услышать заявку.
class OrderAlertService {
  OrderAlertService._();

  static final OrderAlertService instance = OrderAlertService._();

  static const String _assetPath = 'songs/safa-not.mp3';
  static const Duration _hapticPeriod = Duration(seconds: 2);

  AudioPlayer? _player;
  Timer? _hapticTimer;

  /// Заказ, по которому сейчас звучит сигнал. Повторный `start` с тем же id
  /// ничего не делает — иначе каждый опрос ленты начинал бы трек заново.
  Object? _activeKey;
  int _generation = 0;

  bool get isPlaying => _activeKey != null;

  Object? get activeKey => _activeKey;

  Future<void> _vibrate(Object key, int generation) async {
    try {
      if (await Vibration.hasVibrator()) {
        if (_activeKey != key || _generation != generation) return;
        await Vibration.vibrate(duration: 180, amplitude: 160);
        return;
      }
    } catch (_) {
      // На неподдерживаемой платформе используем Flutter haptic ниже.
    }
    if (_activeKey != key || _generation != generation) return;
    await HapticFeedback.mediumImpact();
  }

  /// Запускает сигнал для заказа [key]. Для нового заказа сигнал
  /// перезапускается, для того же — продолжает играть без прерывания.
  Future<void> start(Object key) async {
    if (_activeKey == key) return;
    _activeKey = key;
    final generation = ++_generation;

    _hapticTimer?.cancel();
    unawaited(_vibrate(key, generation));
    _hapticTimer = Timer.periodic(
      _hapticPeriod,
      (_) => unawaited(_vibrate(key, generation)),
    );

    try {
      final player = _player ??= AudioPlayer();
      await player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationEvent,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
        ),
      );
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1);
      await player.stop();
      if (_activeKey != key || generation != _generation) return;
      await player.play(AssetSource(_assetPath));
      if (_activeKey != key || generation != _generation) {
        await player.stop();
      }
    } catch (error, stackTrace) {
      // Тишина не должна ломать приём заказа: вибрация уже идёт, а карточка
      // заказа видна на экране.
      if (kDebugMode) {
        debugPrint('OrderAlertService.start failed: $error\n$stackTrace');
      }
    }
  }

  /// Останавливает сигнал. Безопасно вызывать повторно.
  Future<void> stop() async {
    if (_activeKey == null && _hapticTimer == null) return;
    _activeKey = null;
    _generation += 1;

    _hapticTimer?.cancel();
    _hapticTimer = null;
    try {
      await Vibration.cancel();
    } catch (_) {
      // Платформа без vibration API.
    }

    try {
      await _player?.stop();
    } catch (error) {
      if (kDebugMode) debugPrint('OrderAlertService.stop failed: $error');
    }
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {
      // Плеер уже освобождён платформой.
    }
    _player = null;
  }
}
