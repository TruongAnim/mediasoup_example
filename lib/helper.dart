import 'package:flutter/foundation.dart';

appPrint(dynamic v) {
  if (kDebugMode) {
    print('AppLog: $v');
  }
}
