//static const String baseUrl = "http://10.255.131.88:8000";

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //Emulator: 10.0.2.2,
  //static const String baseUrl = "http://10.255.131.88:8000"; //A24
  static const String baseUrl =
      "https://eaty-backend-877604661855.europe-west3.run.app";
  // İşletme Kaydı
  Future<bool> registerBusiness(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/business'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Register Error: $e");
      return false;
    }
  }

  // İşletme Bilgisi
  Future<Map<String, dynamic>?> getBusiness(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/business/$email'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Get Business Error: $e");
    }
    return null;
  }

  //  Kategori Bazlı ürün ekleme
  Future<List<dynamic>> getBusinessesByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/businesses/$category'),
      );
      if (response.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("List Business Error: $e");
    }
    return [];
  }

  //  Ürün Ekleme
  Future<bool> addProduct(String email, Map<String, dynamic> product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/business/$email/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Add Product Error: $e");
      return false;
    }
  }

  //  Menü Getirme
  Future<List<dynamic>> getMenu(int businessId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/$businessId/menu'),
      );
      if (response.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("Get Menu Error: $e");
    }
    return [];
  }

  // Sipariş Verme
  Future<bool> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Order Error: $e");
      return false;
    }
  }

  //  İşletme Siparişleri
  Future<List<dynamic>> getBusinessOrders(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business/$email/orders'),
      );
      if (response.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("Get Orders Error: $e");
    }
    return [];
  }

  //  Ürün Güncelleme
  Future<bool> updateProduct(
    int productId,
    Map<String, dynamic> product,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Product Error: $e");
      return false;
    }
  }

  //  Ürün Silme
  Future<bool> deleteProduct(int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Product Error: $e");
      return false;
    }
  }

  // Ürün Sıralaması Güncelleme
  Future<bool> reorderProducts(List<Map<String, dynamic>> items) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/reorder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(items),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Reorder Error: $e");
      return false;
    }
  }

  // Sipariş Durumu Güncelleme
  Future<bool> updateOrderStatus(
    int orderId,
    String newStatus, {
    String? reason,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"status": newStatus, "reason": reason}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Status Update Error: $e");
      return false;
    }
  }

  // İşletme Açık/Kapalı Durumu Güncelleme
  Future<bool> updateBusinessStatus(String email, bool isOpen) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/$email/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"is_open": isOpen}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Business Status Update Error: $e");
      return false;
    }
  }

  // Profil Bilgilerini Güncelleme
  Future<bool> updateBusinessProfile(
    String email,
    String address,
    String phone,
    String workingHours,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/$email/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "address": address,
          "phone": phone,
          "working_hours": workingHours,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Profile Update Error: $e");
      return false;
    }
  }

  // Kategori Sıralamasını Güncelleme
  Future<bool> updateCategoryOrder(
    String email,
    List<String> categories,
  ) async {
    try {
      final orderStr = categories.join(",");
      final response = await http.put(
        Uri.parse('$baseUrl/business/$email/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"order": orderStr}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Category Order Error: $e");
      return false;
    }
  }
}
