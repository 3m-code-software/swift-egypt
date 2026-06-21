enum ServiceType {
  internationalRoad,
  maritime,
  domestic;

  String get apiValue {
    switch (this) {
      case ServiceType.internationalRoad:
        return 'international_road';
      case ServiceType.maritime:
        return 'maritime';
      case ServiceType.domestic:
        return 'domestic';
    }
  }

  static ServiceType fromApi(String value) {
    switch (value) {
      case 'international_road':
        return ServiceType.internationalRoad;
      case 'maritime':
        return ServiceType.maritime;
      case 'domestic':
        return ServiceType.domestic;
      default:
        return ServiceType.domestic;
    }
  }

  String get displayName {
    switch (this) {
      case ServiceType.internationalRoad:
        return 'شحن دولي بري';
      case ServiceType.maritime:
        return 'شحن بحري';
      case ServiceType.domestic:
        return 'شحن داخلي';
    }
  }

  String get displayNameEn {
    switch (this) {
      case ServiceType.internationalRoad:
        return 'International Road';
      case ServiceType.maritime:
        return 'Maritime';
      case ServiceType.domestic:
        return 'Domestic';
    }
  }
}
