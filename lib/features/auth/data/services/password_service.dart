import 'package:dbcrypt/dbcrypt.dart';

class PasswordService {
  final _dbcrypt = DBCrypt();

  String hashPassword(String password) {
    return _dbcrypt.hashpw(password, _dbcrypt.gensalt());
  }

  bool verifyPassword(String password, String hashed) {
    return _dbcrypt.checkpw(password, hashed);
  }
}
