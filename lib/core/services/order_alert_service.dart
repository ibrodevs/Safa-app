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

    // Гарантированный системный звуковой сигнал
    try {
      unawaited(SystemSound.play(SystemSoundType.alert));
    } catch (_) {}

    try {
      final player = _player ??= AudioPlayer();

      // Настройка аудио контекста для максимальной громкости и воспроизведения
      // даже при включённом беззвучном режиме на iOS / фоне.
      try {
        await player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.notificationEvent,
              audioFocus: AndroidAudioFocus.gainTransient,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {
                AVAudioSessionOptions.mixWithOthers,
                AVAudioSessionOptions.duckOthers,
              },
            ),
          ),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('AudioContext config failed: $e');
      }

      try {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(1.0);
      } catch (_) {}

      try {
        await player.stop();
      } catch (_) {}

      if (_activeKey != key || generation != _generation) return;

      try {
        await player.play(AssetSource(_assetPath), volume: 1.0);
      } catch (e) {
        // Запасной путь к ассету
        if (kDebugMode) debugPrint('AssetSource($_assetPath) failed: $e, trying fallback');
        await player.play(AssetSource('assets/$_assetPath'), volume: 1.0);
      }

      if (_activeKey != key || _generation != generation) {
        await player.stop();
      }
    } catch (error, stackTrace) {
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
