import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'BASE_URL', defaultValue: '')
  static const String baseUrl = _Env.baseUrl;

  @EnviedField(varName: 'DATTIO_API_KEY')
  static const String dattioApiKey = _Env.dattioApiKey;

  @EnviedField(varName: 'DATTIO_BASE_URL')
  static const String dattioBaseUrl = _Env.dattioBaseUrl;
}
