import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, double>> getExchangeRates() async {
    const urlString = 'https://open.er-api.com/v6/latest/USD';

    try {
      final url = Uri.parse(urlString);
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] == 'success') {
          final ratesData = data['rates'];
          if (ratesData is Map<String, dynamic> && ratesData.isNotEmpty) {
            return {
              'USD': (ratesData['USD'] ?? 1.0).toDouble(),
              'EUR': (ratesData['EUR'] ?? 1.0).toDouble(),
              'JPY': (ratesData['JPY'] ?? 1.0).toDouble(),
              'KRW': (ratesData['KRW'] ?? 1.0).toDouble(),
              'GBP': (ratesData['GBP'] ?? 1.0).toDouble(),
              'IDR': (ratesData['IDR'] ?? 1.0).toDouble(),
            };
          }
        } else {
          print('API Error: ${data['error-type']}');
        }
      } else {
        print('API Error: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
    }

    return {
      'USD': 1.0,
      'EUR': 0.9,
      'JPY': 150.0,
      'KRW': 1300.0,
      'GBP': 0.8,
      'IDR': 16000.0,
    };
  }
  Future<Map<String, int>> getTimeZoneOffsets() async {
    return {'WIB': 7, 'WITA': 8, 'WIT': 9, 'London': 0};
  }
}
