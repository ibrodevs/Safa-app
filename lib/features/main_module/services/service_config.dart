import 'package:flutter/material.dart';

import '../../../core/design/app_design.dart';

/// Описание сервиса приложения.
///
/// Все три раздела — «Доставка», «Тачки» и «Аманат» — используют один и тот же
/// каркас экрана заказа. Отличаются только данные из этого класса:
/// название, описание, иконка, оттенок, число точек маршрута, тексты кнопок
/// и `service_type`.
///
/// [type] уходит на backend в поле `service_type` без изменений — значения
/// `delivery`, `cars`, `amanat` те же, что и раньше.
@immutable
class ServiceConfig {
  const ServiceConfig({
    required this.type,
    required this.title,
    required this.shortDescription,
    required this.orderSubtitle,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.imageAsset,
    required this.allowsIntermediateStops,
    required this.destinationLabel,
    required this.destinationHint,
    required this.primaryActionLabel,
    this.maxIntermediateStops = 0,
    this.supportsDescription = false,
    this.descriptionLabel,
    this.descriptionHint,
  });

  /// Значение `service_type` для backend.
  final String type;

  final String title;

  /// Короткое описание для карточки на главном экране.
  final String shortDescription;

  /// Подзаголовок на экране оформления заказа.
  final String orderSubtitle;

  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String imageAsset;

  /// Можно ли добавлять промежуточные остановки.
  final bool allowsIntermediateStops;

  /// Максимум промежуточных остановок (0 — не ограничено, если разрешены).
  final int maxIntermediateStops;

  final String destinationLabel;
  final String destinationHint;
  final String primaryActionLabel;

  /// Использует ли сервис поле описания. Отправляется в существующее
  /// поле `description` запроса `POST delivery/shipments/` — новых
  /// полей API не появляется.
  final bool supportsDescription;
  final String? descriptionLabel;
  final String? descriptionHint;

  bool get canAddMoreStops => allowsIntermediateStops;

  /// Доставка: две точки, простой сценарий.
  static const ServiceConfig delivery = ServiceConfig(
    type: 'delivery',
    title: 'Доставка',
    shortDescription: 'Быстрая доставка между двумя точками',
    orderSubtitle: 'Укажите, откуда забрать и куда доставить',
    icon: Icons.inventory_2_outlined,
    accent: AppColors.primary,
    accentSoft: AppColors.primarySoft,
    imageAsset: AppImages.serviceDelivery,
    allowsIntermediateStops: false,
    destinationLabel: 'Куда',
    destinationHint: 'Куда доставить',
    primaryActionLabel: 'Оформить доставку',
  );

  /// Тачки: маршрут с несколькими остановками.
  static const ServiceConfig cars = ServiceConfig(
    type: 'cars',
    title: 'Тачки',
    shortDescription: 'Маршрут с несколькими остановками',
    orderSubtitle: 'Соберите маршрут: начало, остановки и конечная точка',
    icon: Icons.local_shipping_outlined,
    accent: AppColors.info,
    accentSoft: AppColors.infoSoft,
    imageAsset: AppImages.serviceCars,
    allowsIntermediateStops: true,
    maxIntermediateStops: 28,
    destinationLabel: 'Куда',
    destinationHint: 'Конечная точка',
    primaryActionLabel: 'Оформить маршрут',
  );

  /// Аманат: передача посылки с описанием вложения.
  static const ServiceConfig amanat = ServiceConfig(
    type: 'amanat',
    title: 'Аманат',
    shortDescription: 'Безопасная передача посылок и вещей',
    orderSubtitle: 'Укажите маршрут и опишите, что нужно передать',
    icon: Icons.card_giftcard_outlined,
    accent: AppColors.success,
    accentSoft: AppColors.successSoft,
    imageAsset: AppImages.serviceAmanat,
    allowsIntermediateStops: false,
    destinationLabel: 'Кому',
    destinationHint: 'Куда передать',
    primaryActionLabel: 'Отправить аманат',
    supportsDescription: true,
    descriptionLabel: 'Что передаём',
    descriptionHint: 'Например: документы в конверте, получатель Азамат',
  );

  static const List<ServiceConfig> all = [delivery, cars, amanat];

  /// Разбор значения query-параметра `/map?service=…`.
  ///
  /// Неизвестное значение трактуется как `delivery` — так же, как раньше
  /// в роутере.
  static ServiceConfig fromType(String? rawType) {
    switch (rawType?.trim().toLowerCase()) {
      case 'cars':
        return cars;
      case 'amanat':
        return amanat;
      case 'delivery':
      default:
        return delivery;
    }
  }
}
