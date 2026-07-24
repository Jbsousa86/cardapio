import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/shared_prefs_helper.dart';

class PrintService {
  final SharedPrefsHelper _prefsHelper = SharedPrefsHelper();

  Future<bool> isEnabled() async {
    final config = await _prefsHelper.getPrintConfig();
    return config['enabled'] ?? false;
  }

  /// Envia um comando ou dado para o servidor de impressão Jbs Print
  /// [endpoint] ex: '/print' ou '/status'
  /// [port] a porta do servidor, ex: 8080 ou 9100
  /// [body] os dados a serem enviados no formato JSON
  Future<http.Response?> sendCommand({
    required String endpoint,
    required int port,
    Map<String, dynamic>? body,
  }) async {
    final config = await _prefsHelper.getPrintConfig();
    
    final bool enabled = config['enabled'] ?? false;
    if (!enabled) {
      print('Servidor de impressão não está habilitado.');
      return null;
    }

    final String serverUrl = config['serverUrl'] ?? '';
    final String appId = config['appId'] ?? '';
    final String appToken = config['appToken'] ?? '';

    if (serverUrl.isEmpty || appId.isEmpty || appToken.isEmpty) {
      throw Exception('Configurações do servidor de impressão estão incompletas.');
    }

    // Monta a URL completa, ex: http://192.168.0.100:8080/print
    // Removendo barra final da URL se houver e ajustando o formato
    final cleanUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    
    // Tratando caso o usuário tenha digitado a porta na URL (simplificação)
    final uri = Uri.parse('$cleanUrl$endpoint');

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'X-App-ID': appId,
      'X-Api-Token': appToken,
    };

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return response;
    } catch (e) {
      print('Erro ao comunicar com o servidor Jbs Print: $e');
      rethrow;
    }
  }

  /// Método específico para imprimir comprovante
  Future<bool> imprimirComprovante(List<Map<String, dynamic>> commands) async {
    try {
      final response = await sendCommand(
        endpoint: '/print',
        port: 8080,
        body: {
          "printer_id": "default",
          "commands": commands
        },
      );
      
      if (response != null && response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Erro em imprimirComprovante: $e');
      return false;
    }
  }
}
