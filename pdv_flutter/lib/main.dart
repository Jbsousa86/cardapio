import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:audioplayers/audioplayers.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyABboRzNIklEJN7lwu7bA0JFhTa43QCgbU",
      appId: "1:211578251149:web:6795281b760cedd99dbfc4",
      messagingSenderId: "211578251149",
      projectId: "cardapio-8b24a",
      authDomain: "cardapio-8b24a.firebaseapp.com",
      storageBucket: "cardapio-8b24a.firebasestorage.app",
    ),
  );
  
  runApp(const PDVApp());
}

class PDVApp extends StatelessWidget {
  const PDVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caixa PDV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return const StoresScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = 'Erro (${e.code}): ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Erro desconhecido: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.point_of_sale, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Acesso ao Caixa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Faça login para ver suas lojas', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                obscureText: true,
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Entrar', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  bool hasAccessToStore(Map<String, dynamic> config, String userEmail) {
    final admins = config['admins'];
    if (admins != null && admins is List) {
      for (var admin in admins) {
        if (admin is String) {
          if (admin.toLowerCase() == userEmail) return true;
        } else if (admin is Map) {
          final email = admin['email'] as String?;
          if (email != null && email.toLowerCase() == userEmail) return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email?.toLowerCase() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Loja - Caixa'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stores').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data?.docs ?? [];
          
          final accessibleStores = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final config = data['CONFIG'] as Map<String, dynamic>? ?? {};
            return hasAccessToStore(config, userEmail);
          }).toList();

          if (accessibleStores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Sem acesso a nenhuma loja.', style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: accessibleStores.length,
            itemBuilder: (context, index) {
              final storeData = accessibleStores[index].data() as Map<String, dynamic>;
              final storeId = accessibleStores[index].id;
              
              final config = storeData['CONFIG'] ?? {};
              final baseName = config['name'] ?? storeId;
              final highlight = config['nameHighlight'] ?? '';
              final storeName = '$baseName $highlight'.trim();
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.store, color: Colors.white)),
                  title: Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: const Text('Abrir Terminal PDV desta loja'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StorePDVScreen(storeId: storeId, storeData: storeData)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// PDV / CAIXA DA LOJA COM ABAS
// ----------------------------------------------------------------------
class StorePDVScreen extends StatefulWidget {
  final String storeId;
  final Map<String, dynamic> storeData;

  const StorePDVScreen({super.key, required this.storeId, required this.storeData});

  @override
  State<StorePDVScreen> createState() => _StorePDVScreenState();
}

class _StorePDVScreenState extends State<StorePDVScreen> {
  final List<Map<String, dynamic>> _cartItems = [];
  bool _isSavingSale = false;
  String _storeName = '';

  StreamSubscription? _ordersSubscription;
  int _pendingOnlineCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _alertTimer;

  final TextEditingController _localCustomerNameController = TextEditingController();
  final TextEditingController _localCustomerPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = widget.storeData['CONFIG'] ?? {};
    final baseName = config['name'] ?? widget.storeId;
    final highlight = config['nameHighlight'] ?? '';
    _storeName = '$baseName $highlight'.trim();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Monitora os pedidos online do dia
    _ordersSubscription = FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.storeId)
        .collection('orders')
        .snapshots()
        .listen((snapshot) {
          
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['timestamp'] as Timestamp?;
        final status = data['status'] ?? 'novo';
        
        // Conta pendentes de hoje
        if (ts != null && ts.toDate().isAfter(startOfDay)) {
          if (status != 'concluido') {
            count++;
          }
        }
      }
      
      bool newOrderArrived = false;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'novo';
          if (status == 'novo') {
            newOrderArrived = true;
            Printing.layoutPdf(
              onLayout: (format) => generateReceiptPdf(data, _storeName, widget.storeId),
              name: 'Pedido_Online_${change.doc.id}',
            );
            change.doc.reference.update({'status': 'impresso'});
          }
        }
      }

      if (mounted) {
        setState(() {
          _pendingOnlineCount = count;
        });
      }

      if (newOrderArrived) {
        _playLoudAlert();
      }

      if (count > 0) {
        if (_alertTimer == null || !_alertTimer!.isActive) {
          _alertTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
            _playBeep();
          });
        }
      } else {
        _alertTimer?.cancel();
      }
    });
  }

  void _playLoudAlert() async {
    try {
      await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg'));
    } catch (e) {
      debugPrint('Erro no audio loud: $e');
    }
  }

  void _playBeep() async {
    try {
      await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/beep_short.ogg'));
    } catch (e) {
      debugPrint('Erro no audio beep: $e');
    }
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _audioPlayer.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> product) {
    final variants = product['variants'] as List<dynamic>?;
    final extras = product['extras'] as List<dynamic>?;

    if ((variants != null && variants.isNotEmpty) || (extras != null && extras.isNotEmpty)) {
      _showOptionsDialog(product, variants, extras);
    } else {
      _finalizeAddToCart(product, null, []);
    }
  }

  void _showOptionsDialog(Map<String, dynamic> product, List<dynamic>? variants, List<dynamic>? extras) {
    Map<String, dynamic>? selectedVariant;
    List<Map<String, dynamic>> selectedExtras = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Opções: ${product['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (variants != null && variants.isNotEmpty) ...[
                      const Text('Tamanho/Opção (Obrigatório):', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...variants.map((v) {
                        final variant = v as Map<String, dynamic>;
                        return RadioListTile<Map<String, dynamic>>(
                          title: Text('${variant['name']} (+ R\$ ${(variant['price'] as num).toStringAsFixed(2)})'),
                          value: variant,
                          groupValue: selectedVariant,
                          onChanged: (val) => setStateDialog(() => selectedVariant = val),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    if (extras != null && extras.isNotEmpty) ...[
                      const Text('Adicionais:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...extras.map((e) {
                        final extra = e as Map<String, dynamic>;
                        final isSelected = selectedExtras.contains(extra);
                        return CheckboxListTile(
                          title: Text('${extra['name']} (+ R\$ ${(extra['price'] as num).toStringAsFixed(2)})'),
                          value: isSelected,
                          onChanged: (val) {
                            setStateDialog(() {
                              if (val == true) selectedExtras.add(extra);
                              else selectedExtras.remove(extra);
                            });
                          },
                        );
                      }),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () {
                    if (variants != null && variants.isNotEmpty && selectedVariant == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma opção obrigatória.')));
                      return;
                    }
                    Navigator.pop(context);
                    _finalizeAddToCart(product, selectedVariant, selectedExtras);
                  },
                  child: const Text('Adicionar'),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _finalizeAddToCart(Map<String, dynamic> product, Map<String, dynamic>? variant, List<Map<String, dynamic>> extras) {
    setState(() {
      int existingIndex = _cartItems.indexWhere((item) {
        bool sameProduct = item['product']['name'] == product['name'];
        bool sameVariant = item['variant']?['name'] == variant?['name'];
        bool sameExtrasCount = (item['extras'] as List).length == extras.length; 
        return sameProduct && sameVariant && sameExtrasCount;
      });

      if (existingIndex >= 0) {
        _cartItems[existingIndex]['quantity'] += 1;
      } else {
        _cartItems.add({'product': product, 'variant': variant, 'extras': extras, 'quantity': 1});
      }
    });
  }

  void _changeQuantity(int index, int delta) {
    setState(() {
      _cartItems[index]['quantity'] += delta;
      if (_cartItems[index]['quantity'] <= 0) _cartItems.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _localCustomerNameController.clear();
      _localCustomerPhoneController.clear();
    });
  }

  double _calculateTotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      final product = item['product'];
      final variant = item['variant'];
      final extras = item['extras'] as List<Map<String, dynamic>>;
      final quantity = item['quantity'] as int;

      double basePrice = (variant != null) ? (variant['price'] as num).toDouble() : (product['price'] as num).toDouble();
      double extrasTotal = extras.fold(0.0, (sum, extra) => sum + (extra['price'] as num).toDouble());
      total += (basePrice + extrasTotal) * quantity;
    }
    return total;
  }

  void _checkout() {
    if (_cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Como o cliente vai pagar?', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _paymentButton('Dinheiro', Icons.money, Colors.green, context),
              _paymentButton('PIX', Icons.qr_code_2, Colors.teal, context),
              _paymentButton('Cartão (Crédito/Débito)', Icons.credit_card, Colors.blue, context),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey)))
          ]
        );
      }
    );
  }

  Widget _paymentButton(String method, IconData icon, Color color, BuildContext dialogContext) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(dialogContext); // fecha modal principal
          if (method == 'Dinheiro') {
            _showCashPaymentDialog();
          } else {
            _confirmAndSaveSale(method);
          }
        },
        icon: Icon(icon, size: 28),
        label: Text(method, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
        ),
      ),
    );
  }

  void _showCashPaymentDialog() {
    final total = _calculateTotal();
    final receivedController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double received = double.tryParse(receivedController.text.replaceAll(',', '.')) ?? 0.0;
            double change = received - total;

            return AlertDialog(
              title: const Text('Pagamento em Dinheiro', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total da Venda: R\$ ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: receivedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor Recebido (R\$)',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    onChanged: (val) {
                      setStateDialog(() {}); // Atualiza interface para mostrar o troco
                    },
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  if (receivedController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: change >= 0 ? Colors.green : Colors.red),
                      ),
                      child: Text(
                        change >= 0 ? 'Troco: R\$ ${change.toStringAsFixed(2)}' : 'Faltando: R\$ ${(change.abs()).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: change >= 0 ? Colors.green.shade800 : Colors.red.shade800),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: change >= 0 ? () {
                    Navigator.pop(context);
                    _confirmAndSaveSale('Dinheiro');
                  } : null, 
                  child: const Text('Confirmar Pagamento'),
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _confirmAndSaveSale(String paymentMethod) async {
    setState(() => _isSavingSale = true);
    final total = _calculateTotal();
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    final saleData = {
      'timestamp': FieldValue.serverTimestamp(),
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'total': total,
      'paymentMethod': paymentMethod,
      'operator': user?.email ?? 'Desconhecido',
      if (_localCustomerNameController.text.trim().isNotEmpty) 'customerName': _localCustomerNameController.text.trim(),
      if (_localCustomerPhoneController.text.trim().isNotEmpty) 'customerPhone': _localCustomerPhoneController.text.trim(),
      'type': 'local',
      'items': _cartItems.map((item) {
        return {
          'name': item['product']['name'],
          'quantity': item['quantity'],
          'variant': item['variant']?['name'],
          'extras': (item['extras'] as List).map((e) => e['name']).toList(),
        };
      }).toList(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('sales')
          .add(saleData);
      
      Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => generateReceiptPdf(saleData, _storeName, widget.storeId),
        name: 'Cupom_Venda',
      );

      _clearCart();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Venda Registrada! O Cupom está sendo gerado...'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao salvar venda: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSale = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = List<dynamic>.from(widget.storeData['PRODUCTS'] ?? []);
    final total = _calculateTotal();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('PDV | $_storeName'),
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            tabs: [
              const Tab(icon: Icon(Icons.point_of_sale), text: 'Terminal Local (Balcão)'),
              Tab(
                icon: Badge(
                  label: Text('$_pendingOnlineCount'),
                  isLabelVisible: _pendingOnlineCount > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delivery_dining),
                ),
                text: 'Pedidos Online (Delivery)',
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => DailyReportScreen(storeId: widget.storeId, storeName: _storeName))
                );
              },
              icon: const Icon(Icons.receipt_long, color: Colors.green),
              label: const Text('Resumo do Dia', style: TextStyle(color: Colors.green)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: TabBarView(
          children: [
            // TAB 1: CAIXA LOCAL
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, 
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index] as Map<String, dynamic>;
                      final price = product['price'] ?? 0.0;
                      final imageUrl = product['image'];
                      
                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _addToCart(product),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: imageUrl != null && imageUrl.toString().startsWith('http')
                                    ? Image.network(
                                        imageUrl, 
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stk) => Container(
                                          color: Colors.grey.shade200, 
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [Icon(Icons.image_not_supported, size: 30, color: Colors.grey), Text('Bloqueado', style: TextStyle(fontSize: 10, color: Colors.grey))]
                                          )
                                        ),
                                      )
                                    : Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 40, color: Colors.grey)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('R\$ ${(price as num).toStringAsFixed(2)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(left: BorderSide(color: Colors.grey.shade300)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(-2, 0))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.shade100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Comanda Atual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (_cartItems.isNotEmpty)
                              IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: _clearCart, tooltip: 'Limpar'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _cartItems.isEmpty 
                          ? const Center(child: Text('Nenhum item adicionado.', style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              itemCount: _cartItems.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _cartItems[index];
                                final product = item['product'];
                                final variant = item['variant'];
                                final extras = item['extras'] as List<Map<String, dynamic>>;
                                final quantity = item['quantity'];

                                double basePrice = (variant != null) ? (variant['price'] as num).toDouble() : (product['price'] as num).toDouble();
                                double extrasTotal = extras.fold(0.0, (sum, extra) => sum + (extra['price'] as num).toDouble());
                                double itemTotal = (basePrice + extrasTotal) * quantity;

                                return Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${product['name']} ${variant != null ? "(${variant['name']})" : ""}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Text('R\$ ${itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      if (extras.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text('+ ${extras.map((e) => e['name']).join(', ')}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                            onPressed: () => _changeQuantity(index, -1),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$quantity', style: const TextStyle(fontSize: 16))),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                            onPressed: () => _changeQuantity(index, 1),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
                        child: Column(
                          children: [
                            TextField(
                              controller: _localCustomerNameController,
                              decoration: const InputDecoration(labelText: 'Nome do Cliente (Opcional)', isDense: true, border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _localCustomerPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Telefone (Opcional)', isDense: true, border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('R\$ ${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cartItems.isEmpty || _isSavingSale ? null : _checkout,
                              icon: _isSavingSale ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.point_of_sale),
                              label: Text(_isSavingSale ? 'Salvando...' : 'Finalizar Venda', style: const TextStyle(fontSize: 18)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // TAB 2: GESTÃO DE PEDIDOS ONLINE
            OnlineOrdersScreen(storeId: widget.storeId, storeName: _storeName),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// TELA DE RECEBIMENTO DE PEDIDOS ONLINE (SIMPLES)
// ----------------------------------------------------------------------
class OnlineOrdersScreen extends StatelessWidget {
  final String storeId;
  final String storeName;

  const OnlineOrdersScreen({super.key, required this.storeId, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro ao carregar pedidos online: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);

        final docs = snapshot.data?.docs ?? [];
        final todayOrders = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['timestamp'] as Timestamp?;
          if (ts == null) return true;
          return ts.toDate().isAfter(startOfDay);
        }).toList();

        if (todayOrders.isEmpty) {
          return const Center(child: Text('Nenhum pedido online recebido hoje.', style: TextStyle(color: Colors.grey, fontSize: 18)));
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Histórico de Pedidos Online (Hoje)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: todayOrders.length,
                itemBuilder: (context, index) {
                  final data = todayOrders[index].data() as Map<String, dynamic>;
                  final orderId = todayOrders[index].id;
                  
                  final customerName = data['customerName'] ?? 'Cliente Online';
                  final customerPhone = data['customerPhone'] ?? '-';
                  final items = data['items'] as List<dynamic>? ?? [];
                  final total = (data['total'] as num?)?.toDouble() ?? 0.0;
                  final status = data['status'] ?? 'novo';
                  final ts = data['timestamp'] as Timestamp?;
                  
                  final timeStr = ts != null 
                      ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}' 
                      : 'Agora';

                  String productsSummary = items.map((item) {
                    final q = item['quantity'] ?? 1;
                    final n = item['name'] ?? 'Produto';
                    return '${q}x $n';
                  }).join(', ');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: status == 'concluido' ? Colors.grey : (status == 'novo' ? Colors.red : Colors.green),
                      child: Icon(status == 'concluido' ? Icons.done_all : Icons.delivery_dining, color: Colors.white),
                    ),
                    title: Text('$customerName ($timeStr)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('Tel: $customerPhone | Total: R\$ ${total.toStringAsFixed(2)}\n$productsSummary', maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.receipt_long, color: Colors.blue),
                          onPressed: () => showReceiptModal(context, data, storeName, storeId),
                          tooltip: 'Visualizar / Reimprimir',
                        ),
                        if (status != 'concluido')
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {
                              FirebaseFirestore.instance
                                .collection('stores')
                                .doc(storeId)
                                .collection('orders')
                                .doc(orderId)
                                .update({'status': 'concluido'});
                            },
                            tooltip: 'Marcar como Concluído',
                          ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// TELA DE RELATÓRIO DO DIA (FECHAMENTO)
// ----------------------------------------------------------------------
class DailyReportScreen extends StatefulWidget {
  final String storeId;
  final String storeName;

  const DailyReportScreen({super.key, required this.storeId, required this.storeName});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  List<QueryDocumentSnapshot> _salesDocs = [];
  List<QueryDocumentSnapshot> _ordersDocs = [];
  StreamSubscription? _salesSub;
  StreamSubscription? _ordersSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final startOfDay = DateTime(now.year, now.month, now.day);

    _salesSub = FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.storeId)
        .collection('sales')
        .where('date', isEqualTo: dateString)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _salesDocs = snapshot.docs;
          _isLoading = false;
        });
      }
    });

    _ordersSub = FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.storeId)
        .collection('orders')
        .snapshots()
        .listen((snapshot) {
      final todayOrders = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['timestamp'] as Timestamp?;
        if (ts == null) return true;
        return ts.toDate().isAfter(startOfDay);
      }).toList();
      
      if (mounted) {
        setState(() {
          _ordersDocs = todayOrders;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _salesSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resumo do Dia - ${widget.storeName}'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildReportBody(),
    );
  }

  Widget _buildReportBody() {
    final docs = [..._salesDocs, ..._ordersDocs];
    docs.sort((a, b) {
      final tsA = (a.data() as Map)['timestamp'] as Timestamp?;
      final tsB = (b.data() as Map)['timestamp'] as Timestamp?;
      if (tsA == null || tsB == null) return 0;
      return tsB.compareTo(tsA); 
    });

    if (docs.isEmpty) {
      return const Center(child: Text('Nenhuma venda registrada hoje. Comece a vender!', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    double totalDinheiro = 0;
    double totalPix = 0;
    double totalCartao = 0;
    double totalGeral = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Apenas soma o valor se for venda local ou pedido online já 'concluido'
      if (data.containsKey('status') && data['status'] != 'concluido') {
        continue;
      }

      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      final method = data['paymentMethod'] as String? ?? '';
      
      totalGeral += total;
      if (method == 'Dinheiro') totalDinheiro += total;
      if (method == 'PIX') totalPix += total;
      if (method == 'Cartão' || method.contains('Cartão')) totalCartao += total;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blueGrey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryCard('Em Dinheiro', totalDinheiro, Colors.green),
              _summaryCard('No PIX', totalPix, Colors.teal),
              _summaryCard('No Cartão', totalCartao, Colors.blue),
              _summaryCard('TOTAL HOJE', totalGeral, Colors.black87),
            ],
          ),
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Histórico de Vendas de Hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final total = (data['total'] as num).toDouble();
              final method = data['paymentMethod'] ?? '-';
              
              final isOnline = data.containsKey('status');
              final status = data['status'] ?? 'novo';
              final operator = data['operator'] ?? (isOnline ? 'Online ($status)' : '-');
              
              final ts = data['timestamp'] as Timestamp?;
              final timeStr = ts != null 
                  ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}' 
                  : 'Agora';

              final items = data['items'] as List<dynamic>? ?? [];
              String productsSummary = items.map((item) {
                final q = item['quantity'] ?? 1;
                final n = item['name'] ?? 'Produto';
                return '${q}x $n';
              }).join(', ');
              
              if (productsSummary.isEmpty) productsSummary = 'Venda Registrada';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOnline ? (status == 'concluido' ? Colors.grey : Colors.red) : _getColorForMethod(method),
                  child: Icon(isOnline ? Icons.delivery_dining : _getIconForMethod(method), color: Colors.white),
                ),
                title: Text(productsSummary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('Total: R\$ ${total.toStringAsFixed(2)} | $method\nOperador: $operator'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.receipt_long, color: Colors.blue),
                      onPressed: () => showReceiptModal(context, data, widget.storeName, widget.storeId),
                      tooltip: 'Visualizar Cupom',
                    ),
                    if (isOnline && status != 'concluido')
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () {
                          final orderId = docs[index].id;
                          FirebaseFirestore.instance
                            .collection('stores')
                            .doc(widget.storeId)
                            .collection('orders')
                            .doc(orderId)
                            .update({'status': 'concluido'});
                        },
                        tooltip: 'Marcar como Concluído',
                      ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          ),
        )
      ],
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        width: 200, 
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 16)),
            const SizedBox(height: 12),
            Text('R\$ ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Color _getColorForMethod(String method) {
    if (method == 'Dinheiro') return Colors.green;
    if (method == 'PIX') return Colors.teal;
    if (method.contains('Cartão')) return Colors.blue;
    return Colors.grey;
  }
  
  IconData _getIconForMethod(String method) {
    if (method == 'Dinheiro') return Icons.money;
    if (method == 'PIX') return Icons.qr_code_2;
    if (method.contains('Cartão')) return Icons.credit_card;
    return Icons.receipt;
  }
}

// ----------------------------------------------------------------------
// TELA DE VISUALIZAÇÃO PRÉVIA (MODAL PROFISSIONAL)
// ----------------------------------------------------------------------
Future<void> showReceiptModal(BuildContext context, Map<String, dynamic> saleData, String storeName, String storeId) {
  return showDialog(
    context: context,
    builder: (context) => ReceiptDialog(saleData: saleData, storeName: storeName, storeId: storeId),
  );
}

class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> saleData;
  final String storeName;
  final String storeId;

  const ReceiptDialog({super.key, required this.saleData, required this.storeName, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final items = saleData['items'] as List<dynamic>? ?? [];
    final total = (saleData['total'] as num?)?.toDouble() ?? 0.0;
    final method = saleData['paymentMethod'] ?? 'Desconhecido';
    final operator = saleData['operator'] ?? 'Caixa';
    final ts = saleData['timestamp'];
    
    String dateStr = 'Agora';
    if (ts != null && ts is Timestamp) {
      final dt = ts.toDate();
      dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    final isOnline = saleData.containsKey('status');
    final hasCustomer = saleData['customerName'] != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('stores').doc(storeId).get(),
        builder: (context, snapshot) {
          String docStr = '';
          String phoneStr = '';
          String addressStr = '';
          if (snapshot.hasData && snapshot.data!.data() != null) {
            final config = (snapshot.data!.data() as Map<String, dynamic>)['CONFIG'] as Map<String, dynamic>? ?? {};
            docStr = config['document'] ?? '';
            phoneStr = config['phone'] ?? '';
            addressStr = config['address'] ?? '';
          }

          return Container(
            width: 350,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isOnline ? Colors.red.shade100 : Colors.yellow.shade100, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Icon(isOnline ? Icons.delivery_dining : Icons.receipt_long, size: 40, color: Colors.black87),
                      const SizedBox(height: 8),
                      Text(storeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      if (docStr.isNotEmpty) Text('CNPJ/CPF: $docStr', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                      if (phoneStr.isNotEmpty) Text('Tel: $phoneStr', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                      if (addressStr.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(addressStr, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                      const SizedBox(height: 4),
                      Text(isOnline ? 'PEDIDO ONLINE' : 'CUPOM NÃO FISCAL', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data: $dateStr', style: const TextStyle(color: Colors.grey)),
                    if (isOnline) ...[
                      Text('Cliente: ${saleData['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Tel: ${saleData['customerPhone'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                      Text('End: ${saleData['address']}', style: const TextStyle(color: Colors.grey)),
                    ] else ...[
                      Text('Operador: $operator', style: const TextStyle(color: Colors.grey)),
                      if (hasCustomer) ...[
                        Text('Cliente: ${saleData['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Tel: ${saleData['customerPhone'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ],
                    const Divider(height: 24, thickness: 1, color: Colors.grey),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('QTD', style: TextStyle(fontWeight: FontWeight.bold)), Text('ITEM', style: TextStyle(fontWeight: FontWeight.bold))],
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final q = item['quantity'] ?? 1;
                      final n = item['name'] ?? 'Produto';
                      final variant = item['variant'] != null ? ' - ${item['variant']}' : '';
                      final extras = item['extras'] as List<dynamic>? ?? [];
                      String extrasStr = extras.isNotEmpty ? '\n  + ' + extras.join('\n  + ') : '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${q}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Expanded(child: Text('$n$variant$extrasStr')),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 24, thickness: 1, color: Colors.grey),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('R\$ ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('PAGAMENTO:'), Text(method, style: const TextStyle(fontWeight: FontWeight.bold))],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Compartilhar'),
                      onPressed: () async {
                        final bytes = await generateReceiptPdf(saleData, storeName, storeId);
                        await Printing.sharePdf(bytes: bytes, filename: 'Cupom_${dateStr.replaceAll('/', '-')}.pdf');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Imprimir'),
                      onPressed: () => Printing.layoutPdf(onLayout: (PdfPageFormat format) => generateReceiptPdf(saleData, storeName, storeId), name: 'Cupom_$storeName'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
      },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// LÓGICA DE GERAÇÃO DO ARQUIVO PDF (CUPOM TÉRMICO FÍSICO)
// ----------------------------------------------------------------------
Future<Uint8List> generateReceiptPdf(Map<String, dynamic> saleData, String storeName, String storeId) async {
  final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
  final config = storeDoc.data()?['CONFIG'] as Map<String, dynamic>? ?? {};
  
  final storeDocument = config['document'] ?? '';
  final storePhone = config['phone'] ?? '';
  final storeAddress = config['address'] ?? '';

  final doc = pw.Document();

  final items = saleData['items'] as List<dynamic>? ?? [];
  final total = (saleData['total'] as num?)?.toDouble() ?? 0.0;
  final method = saleData['paymentMethod'] ?? 'Desconhecido';
  final operator = saleData['operator'] ?? 'Caixa';
  final ts = saleData['timestamp'];
  
  String dateStr = 'Agora';
  if (ts != null && ts is Timestamp) {
    final dt = ts.toDate();
    dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80, // Formato bobina 80mm
      build: (pw.Context context) {
        final isOnline = saleData.containsKey('status');
        final hasCustomer = saleData['customerName'] != null;
        
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text(storeName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
            if (storeDocument.isNotEmpty) pw.Center(child: pw.Text('CNPJ/CPF: $storeDocument', style: const pw.TextStyle(fontSize: 10))),
            if (storePhone.isNotEmpty) pw.Center(child: pw.Text('Tel: $storePhone', style: const pw.TextStyle(fontSize: 10))),
            if (storeAddress.isNotEmpty) pw.Center(child: pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
            pw.SizedBox(height: 8),
            if (isOnline) ...[
              pw.Center(child: pw.Text('PEDIDO ONLINE (DELIVERY)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text('Cliente: ${saleData['customerName']}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Tel: ${saleData['customerPhone'] ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Endereço/Obs: ${saleData['address']}', style: const pw.TextStyle(fontSize: 10)),
            ] else ...[
              pw.Center(child: pw.Text('CUPOM NÃO FISCAL', style: const pw.TextStyle(fontSize: 10))),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text('Operador: $operator', style: const pw.TextStyle(fontSize: 10)),
              if (hasCustomer) ...[
                pw.Text('Cliente: ${saleData['customerName']}', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Tel: ${saleData['customerPhone'] ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ],
            pw.Text('Data: $dateStr', style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Text('QTD   ITEM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 4),
            ...items.map((item) {
              final q = item['quantity'] ?? 1;
              final n = item['name'] ?? 'Produto';
              final variant = item['variant'] != null ? ' - ${item['variant']}' : '';
              final extras = item['extras'] as List<dynamic>? ?? [];
              String extrasStr = extras.isNotEmpty ? '\n  + ' + extras.join('\n  + ') : '';
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(top: 4, bottom: 4),
                child: pw.Text('${q.toString().padRight(4)}x $n$variant$extrasStr', style: const pw.TextStyle(fontSize: 12)),
              );
            }),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL DA COMPRA:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text('R\$ ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FORMA DE PAGAMENTO:', style: const pw.TextStyle(fontSize: 12)),
                pw.Text(method, style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.Center(child: pw.Text('Obrigado pela preferencia!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
            pw.SizedBox(height: 20),
          ],
        );
      },
    ),
  );

  return doc.save();
}
