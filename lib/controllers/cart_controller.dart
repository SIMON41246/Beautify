import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:e_commerce_app/models/cart_item.dart';
import 'package:e_commerce_app/models/product.dart';

class CartController extends GetxController {
  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool isAddingToCart = false.obs;

  RxList<CartItem> get itemsList => items;
  RxBool get isAdding => isAddingToCart;

  RxDouble get totalAmount => items.fold(0.0, (sum, item) => sum + item.totalPrice).obs;

  RxInt get totalItems => items.fold(0, (sum, item) => sum + item.quantity).obs;

  void addItem(Product product) async {
    isAddingToCart.value = true;
    
    // Simulate loading animation
    await Future.delayed(const Duration(milliseconds: 800));
    
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      items[existingIndex].quantity++;
      // Trigger reactive update by reassigning the list
      items.refresh();
      _showSnackBar(
        'Quantity updated!',
        '${product.title} quantity increased to ${items[existingIndex].quantity}',
        Icons.add_shopping_cart,
        Colors.orange,
      );
    } else {
      items.add(CartItem(product: product));
      _showSnackBar(
        'Added to cart!',
        '${product.title} has been added to your cart',
        Icons.check_circle,
        Colors.green,
      );
    }
    
    isAddingToCart.value = false;
  }

  void removeItem(int productId) {
    final item = items.firstWhere((item) => item.product.id == productId);
    items.removeWhere((item) => item.product.id == productId);
    
    _showSnackBar(
      'Removed from cart',
      '${item.product.title} has been removed from your cart',
      Icons.remove_shopping_cart,
      Colors.red,
    );
  }

  void decreaseQuantity(int productId) {
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0 && items[index].quantity > 1) {
      items[index].quantity--;
      // Trigger reactive update by reassigning the list
      items.refresh();
    } else if (index >= 0 && items[index].quantity == 1) {
      removeItem(productId);
    }
  }

  void increaseQuantity(int productId) {
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      items[index].quantity++;
      // Trigger reactive update by reassigning the list
      items.refresh();
    }
  }

  void clearCart() {
    items.clear();
    _showSnackBar(
      'Cart cleared',
      'All items have been removed from your cart',
      Icons.clear_all,
      Colors.blue,
    );
  }

  void _showSnackBar(String title, String message, IconData icon, Color color) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color.withOpacity(0.1),
      colorText: color,
      icon: Icon(icon, color: color),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      borderColor: color.withOpacity(0.3),
      borderWidth: 1,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      snackStyle: SnackStyle.FLOATING,
    );
  }
}