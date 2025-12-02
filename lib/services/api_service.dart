import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    final symbols = 'USD,EUR,JPY,IDR';
    final url = Uri.parse(
      'https://api.frankfurter.app/latest?from=$baseCurrency&to=$symbols',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic>? ratesData = data['rates'] is Map
            ? data['rates']
            : null;

        if (ratesData != null) {
          return {
            'IDR': ratesData['IDR']?.toDouble() ?? 1.0,
            'USD': ratesData['USD']?.toDouble() ?? 1.0,
            'EUR': ratesData['EUR']?.toDouble() ?? 1.0,
            'JPY': ratesData['JPY']?.toDouble() ?? 1.0,
          };
        }
      }

      print(
        'API Error: Status ${response.statusCode} atau data rates kosong/invalid.',
      );
    } catch (e) {
      print('Error fetching exchange rates: $e');
    }

    // Nilai default/fallback
    return {'IDR': 1.0, 'USD': 0.000064, 'EUR': 0.000059, 'JPY': 0.0096};
  }

  Future<Map<String, int>> getTimeZoneOffsets() async {
    return {'WIB': 7, 'WITA': 8, 'WIT': 9, 'London': 0};
  }
}
