import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_commerce_app/models/product.dart';

class ApiService {
  static const String _baseUrl = 'https://dummyjson.com';

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$_baseUrl/products'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> productsJson = data['products'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
}