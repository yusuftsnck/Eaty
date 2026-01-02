//static const String baseUrl = "http://10.255.131.88:8000";

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //Emulator: 10.0.2.2,
  static const String baseUrl = "http://10.60.168.88:8000"; //A24
  //static const String baseUrl =
  //   "https://eaty-api-877604661855.europe-west1.run.app";
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

  // İşletme Email/Şifre Giriş
  Future<Map<String, dynamic>> loginBusiness(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/business/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      String message = "Giriş başarısız";
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['detail']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      print("Login Error: $e");
      rethrow;
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

  //  Müşteri Siparişleri
  Future<List<dynamic>> getCustomerOrders(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/customer/$email'),
      );
      if (response.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("Get Customer Orders Error: $e");
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
    String email, {
    String? address,
    String? phone,
    String? photoUrl,
    double? minOrderAmount,
    int? deliveryTimeMins,
    double? deliveryRadiusKm,
    double? latitude,
    double? longitude,
    String? workingHours,
  }) async {
    final payload = <String, dynamic>{};
    if (address != null) payload['address'] = address;
    if (phone != null) payload['phone'] = phone;
    if (photoUrl != null) payload['photo_url'] = photoUrl;
    if (minOrderAmount != null) payload['min_order_amount'] = minOrderAmount;
    if (deliveryTimeMins != null) {
      payload['delivery_time_mins'] = deliveryTimeMins;
    }
    if (deliveryRadiusKm != null) {
      payload['delivery_radius_km'] = deliveryRadiusKm;
    }
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;
    if (workingHours != null) payload['working_hours'] = workingHours;
    if (payload.isEmpty) return false;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business/$email/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
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

  // Tarif Ekleme
  Future<Map<String, dynamic>?> createRecipe(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      String message = "Tarif kaydedilemedi";
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['detail']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      print("Create Recipe Error: $e");
      return null;
    }
  }

  // Tarifleri Getirme
  Future<List<dynamic>> getRecipes({
    String? authorEmail,
    String? viewerEmail,
  }) async {
    try {
      final params = <String>[];
      if (authorEmail != null && authorEmail.trim().isNotEmpty) {
        params.add('author_email=${Uri.encodeComponent(authorEmail)}');
      }
      if (viewerEmail != null && viewerEmail.trim().isNotEmpty) {
        params.add('viewer_email=${Uri.encodeComponent(viewerEmail)}');
      }
      final uri = params.isEmpty
          ? Uri.parse('$baseUrl/recipes')
          : Uri.parse('$baseUrl/recipes?${params.join('&')}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("Get Recipes Error: $e");
    }
    return [];
  }

  // Tarif Güncelleme
  Future<Map<String, dynamic>?> updateRecipe(
    int recipeId,
    Map<String, dynamic> payload, {
    String? userEmail,
  }) async {
    try {
      final body = Map<String, dynamic>.from(payload);
      if (userEmail != null && userEmail.trim().isNotEmpty) {
        body['user_email'] = userEmail.trim();
      }
      final response = await http.put(
        Uri.parse('$baseUrl/recipes/$recipeId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      String message = "Tarif guncellenemedi";
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['detail']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      print("Update Recipe Error: $e");
      return null;
    }
  }

  // Tarif Silme
  Future<bool> deleteRecipe(int recipeId, {String? userEmail}) async {
    try {
      final uri = userEmail != null && userEmail.trim().isNotEmpty
          ? Uri.parse(
              '$baseUrl/recipes/$recipeId?user_email=${Uri.encodeComponent(userEmail.trim())}',
            )
          : Uri.parse('$baseUrl/recipes/$recipeId');
      final response = await http.delete(uri);
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Recipe Error: $e");
      return false;
    }
  }

  // Tarif Begenme
  Future<Map<String, dynamic>?> toggleRecipeLike(
    int recipeId,
    String userEmail,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/$recipeId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_email": userEmail}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Toggle Like Error: $e");
    }
    return null;
  }

  // Defter Oluşturma
  Future<Map<String, dynamic>?> createRecipeNotebook(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipe-notebooks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Create Notebook Error: $e");
    }
    return null;
  }

  // Defter Listeleme
  Future<List<dynamic>> getRecipeNotebooks({String? ownerEmail}) async {
    try {
      final uri = ownerEmail == null || ownerEmail.trim().isEmpty
          ? Uri.parse('$baseUrl/recipe-notebooks')
          : Uri.parse(
              '$baseUrl/recipe-notebooks?owner_email=${Uri.encodeComponent(ownerEmail)}',
            );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("Get Notebooks Error: $e");
    }
    return [];
  }

  // Defter Güncelleme
  Future<Map<String, dynamic>?> updateRecipeNotebook(
    int notebookId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/recipe-notebooks/$notebookId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Update Notebook Error: $e");
    }
    return null;
  }

  // Defter Silme
  Future<bool> deleteRecipeNotebook(int notebookId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/recipe-notebooks/$notebookId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Notebook Error: $e");
      return false;
    }
  }

  // Deftere Tarif Ekleme
  Future<Map<String, dynamic>?> addRecipeToNotebook(
    int notebookId,
    int recipeId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipe-notebooks/$notebookId/items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"recipe_id": recipeId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Add Recipe To Notebook Error: $e");
    }
    return null;
  }

  // Defterden Tarif Çıkarma
  Future<Map<String, dynamic>?> removeRecipeFromNotebook(
    int notebookId,
    int recipeId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/recipe-notebooks/$notebookId/items/$recipeId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Remove Recipe From Notebook Error: $e");
    }
    return null;
  }
}
