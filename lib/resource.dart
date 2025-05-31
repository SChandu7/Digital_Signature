import 'dart:typed_data';

import 'package:flutter/material.dart';

class resource with ChangeNotifier {
  String PresentWorkingUser = 'defaultUser';
  Uint8List? pdfBytes;

  void setLoginDetails(String user) {
    PresentWorkingUser = user;
    notifyListeners(); // Notify widgets listening to this model
  }

  void setpdfdetails(Uint8List? user) {
    pdfBytes = user;
    notifyListeners(); // Notify widgets listening to this model
  }
}
