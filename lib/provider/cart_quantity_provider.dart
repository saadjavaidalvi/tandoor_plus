import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier{
  int quantity;

  void updateCartQuantity(int value){
    quantity = value;
    notifyListeners();
  }

}