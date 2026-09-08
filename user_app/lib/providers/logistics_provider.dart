import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../services/auth_service.dart';

class TypeGood {
  final String id;
  final String name;
  final String icon;

  TypeGood({required this.id, required this.name, required this.icon});

  factory TypeGood.fromJson(Map<String, dynamic> json) {
    return TypeGood(
      id: json['_id'],
      name: json['name'],
      icon: json['icon'] ?? 'inventory',
    );
  }
}

final typeGoodsProvider = FutureProvider<List<TypeGood>>((ref) async {
  final authService = ref.read(authServiceProvider);
  final response = await http.get(
    Uri.parse('${AppConfig.apiBaseUrl}/typegood'),
    headers: await authService.buildAuthHeaders(),
  );
  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    return data.map((item) => TypeGood.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load type goods');
  }
});
