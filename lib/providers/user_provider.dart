import 'package:flutter/material.dart';
import '../models/user_data.dart';

class UserProvider extends ChangeNotifier {
  UserData? _user;

  UserData? get user => _user;

  void setUser(UserData user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
