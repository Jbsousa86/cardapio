import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/shared_prefs_helper.dart';

class PrintConfigPage extends StatefulWidget {
  const PrintConfigPage({super.key});

  @override
  State<PrintConfigPage> createState() => _PrintConfigPageState();
}

class _PrintConfigPageState extends State<PrintConfigPage> {
  final _helper = SharedPrefsHelper();
  
  final _urlController = TextEditingController();
  final _appIdController = TextEditingController();
  final _tokenController = TextEditingController();
  
  bool _enabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _helper.getPrintConfig();
    setState(() {
      _urlController.text = config['serverUrl'] ?? '';
      _appIdController.text = config['appId'] ?? '';
      _tokenController.text = config['appToken'] ?? '';
      _enabled = config['enabled'] ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    FocusScope.of(context).unfocus();
    
    await _helper.savePrintConfig(
      serverUrl: _urlController.text.trim(),
      appId: _appIdController.text.trim(),
      appToken: _tokenController.text.trim(),
      enabled: _enabled,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _testPrint() async {
    if (!_enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habilite o servidor primeiro.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A URL do servidor não pode estar vazia.'), backgroundColor: Colors.red),
      );
      return;
    }

    final endpoint = url.endsWith('/') ? '${url}print' : '$url/print';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-App-ID': _appIdController.text.trim(),
          'X-Api-Token': _tokenController.text.trim(),
        },
        body: jsonEncode({
          "printer_id": "default", 
          "commands": [
            {"type": "text", "text": "TESTE DE IMPRESSAO\n"},
            {"type": "cut", "partial": false}
          ]
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviado para o Jbs Print com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: ${response.statusCode} - ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração Jbs Print'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Habilitar Servidor de Impressão', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Switch(
                      value: _enabled,
                      onChanged: (val) => setState(() => _enabled = val),
                      activeColor: Colors.cyan,
                    ),
                  ],
                ),
                const Divider(height: 32),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL Base do Servidor (ex: http://192.168.0.100)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  enabled: _enabled,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _appIdController,
                  decoration: const InputDecoration(
                    labelText: 'App ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  enabled: _enabled,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Token',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  enabled: _enabled,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SALVAR CONFIGURAÇÕES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _testPrint,
                  icon: const Icon(Icons.print),
                  label: const Text('TESTAR IMPRESSÃO'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.cyan,
                    side: const BorderSide(color: Colors.cyan),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
