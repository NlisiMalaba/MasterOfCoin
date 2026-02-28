import 'package:envied/envied.dart';

part 'backup_env.g.dart';

@Envied(path: '.env')
abstract class BackupEnv {
  @EnviedField(varName: 'ENCRYPT_KEY', obfuscate: true)
  static final String encryptKey = _BackupEnv.encryptKey;

  @EnviedField(varName: 'ENCRYPT_IV', obfuscate: true)
  static final String encryptIv = _BackupEnv.encryptIv;
}

