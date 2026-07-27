/// Пути к SVG-ассетам. Раньше строки ассетов были размазаны по коду,
/// из-за чего опечатка в пути обнаруживалась только в рантайме.
class AppIcons {
  const AppIcons._();

  static const String _base = 'assets/icons';

  static const String box = '$_base/ic_box.svg';
  static const String map = '$_base/ic_map.svg';
  static const String history = '$_base/ic_history.svg';
  static const String home = '$_base/ic_home.svg';
  static const String homeFilled = '$_base/ic_home_grey.svg';
  static const String profile = '$_base/ic_profile.svg';
  static const String human = '$_base/ic_human.svg';
  static const String notification = '$_base/ic_notification.svg';
  static const String phone = '$_base/ic_phone.svg';
  static const String clock = '$_base/ic_clock.svg';
  static const String wallet = '$_base/ic_wallet.svg';
  static const String warning = '$_base/ic_warning.svg';
  static const String weight = '$_base/ic_weight.svg';
  static const String arrow = '$_base/ic_arrow.svg';
  static const String arrowLong = '$_base/ic_arrow_long.svg';
  static const String logo = '$_base/ic_logo.svg';
  static const String rating = '$_base/ic_rait.svg';
}

/// Пути к растровым ассетам.
class AppImages {
  const AppImages._();

  static const String _base = 'assets/images';

  static const String avatarPlaceholder = '$_base/img_placeholder.png';
  static const String serviceDelivery = '$_base/boxes2.png';
  static const String serviceCars = '$_base/img_home_car2.png';
  static const String serviceAmanat = '$_base/img_home_amanat.png';
  static const String roleClient = '$_base/img_client.jpg';
  static const String roleCarrier = '$_base/img_spec.jpg';
  static const String pattern = '$_base/img_tunduk.png';
}
