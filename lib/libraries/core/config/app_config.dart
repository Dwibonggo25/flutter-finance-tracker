enum Flavor { dev, uat, prod }

class AppConfig {
  final Flavor flavor;
  final String baseUrl;

  static late AppConfig instance;

  AppConfig._({required this.flavor, required this.baseUrl});

  static void init(Flavor flavor) {
    switch (flavor) {
      case Flavor.dev:
        instance = AppConfig._(flavor: flavor, baseUrl: "https://dev-api.com");
        break;

      case Flavor.uat:
        instance = AppConfig._(flavor: flavor, baseUrl: "https://uat-api.com");
        break;

      case Flavor.prod:
        instance = AppConfig._(flavor: flavor, baseUrl: "https://api.com");
        break;
    }
  }
}
