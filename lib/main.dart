import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TheBarColors {
  static const Color beigeClaro = Color(0xFFF5EFE6);
  static const Color cafeOscuro = Color(0xFF3B2E2A);
  static const Color doradoCerveza = Color(0xFFD99A00);
  static const Color naranjaCalido = Color(0xFFD86633);
  static const Color azulOscuro = Color(0xFF0F1A24);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color verdeExito = Color(0xFF2E7D32);
  static const Color rojoError = Color(0xFFC62828);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THE BAR Sistema',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: TheBarColors.beigeClaro,
        // Esto cambia el color morado por defecto a naranja
        primaryColor: TheBarColors.naranjaCalido,
        focusColor: TheBarColors.naranjaCalido,
        colorScheme: const ColorScheme.light(
          primary: TheBarColors.naranjaCalido,
          secondary: TheBarColors.naranjaCalido,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          // Borde cuando está enfocado (naranja)
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: TheBarColors.naranjaCalido, width: 2),
          ),
          // Borde normal
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          // Label flotante (cuando hay texto escrito) - naranja
          floatingLabelStyle: TextStyle(color: TheBarColors.naranjaCalido),
          // Icono del prefix cuando está enfocado
          iconColor: TheBarColors.naranjaCalido,
        ),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ApiConfig {
  static const String baseUrl = 'https://api-stockbar-i93o.onrender.com';
}

String fixTextEncoding(String? text) {
  if (text == null || text.isEmpty) return '';
  final replacements = {
    'Ã¡': 'á', 'Ã©': 'é', 'Ã­': 'í', 'Ã³': 'ó', 'Ãº': 'ú',
    'Ã±': 'ñ', 'Ã¼': 'ü',
  };
  String result = text;
  replacements.forEach((wrong, correct) {
    result = result.replaceAll(wrong, correct);
  });
  return result;
}

String formatCurrency(dynamic value) {
  if (value == null) return '0';
  double parsedValue = 0.0;
  if (value is num) {
    parsedValue = value.toDouble();
  } else if (value is String) {
    parsedValue = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }
  return parsedValue.toStringAsFixed(0);
}

class AlertService {
  static void showSuccessAlert(BuildContext context, String titulo, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(mensaje, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: TheBarColors.verdeExito,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showErrorAlert(BuildContext context, String titulo, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(mensaje, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: TheBarColors.rojoError,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static Future<bool> showConfirmDialog(BuildContext context, String titulo, String mensaje) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: TheBarColors.rojoError),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ==============================================
// PANTALLA DE LOGIN
// ==============================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailRecuperacionController = TextEditingController();
  final _codigoController = TextEditingController();
  final _nuevaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _cargando = false;
  bool _mostrarRecuperar = false;
  bool _mostrarVerificarCodigo = false;
  bool _mostrarNuevaPassword = false;
  String _emailRecuperacion = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailRecuperacionController.dispose();
    _codigoController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AlertService.showErrorAlert(context, 'Error', 'Completa todos los campos');
      return;
    }
    setState(() => _cargando = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 15));

      setState(() => _cargando = false);
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && responseData['success'] == true) {
        final token = responseData['token'] as String;
        final userData = responseData['user'] as Map<String, dynamic>;
        AlertService.showSuccessAlert(context, 'Bienvenido', 'Sesión iniciada');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                usuarioEmail: userData['email'] ?? '',
                token: token,
                userData: userData,
              ),
            ),
          );
        }
      } else {
        AlertService.showErrorAlert(context, 'Error', responseData['message'] ?? 'Credenciales incorrectas');
      }
    } on TimeoutException {
      setState(() => _cargando = false);
      AlertService.showErrorAlert(context, 'Error', 'Tiempo de espera agotado. Verifica tu conexión.');
    } catch (e) {
      setState(() => _cargando = false);
      AlertService.showErrorAlert(context, 'Error de conexión', 'No se pudo conectar al servidor.');
    }
  }

  Future<void> _solicitarRecuperacion() async {
    final email = _emailRecuperacionController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      AlertService.showErrorAlert(context, 'Error', 'Ingresa un email válido');
      return;
    }
    setState(() => _cargando = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      setState(() => _cargando = false);
      final result = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        _emailRecuperacion = email;
        AlertService.showSuccessAlert(context, 'Código enviado', 'Revisa tu correo: $email');
        setState(() {
          _mostrarRecuperar = false;
          _mostrarVerificarCodigo = true;
          _codigoController.clear();
        });
      } else {
        AlertService.showErrorAlert(context, 'Error', result['message'] ?? 'No se pudo enviar el código');
      }
    } catch (e) {
      setState(() => _cargando = false);
      AlertService.showErrorAlert(context, 'Error', 'Error de conexión');
    }
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      AlertService.showErrorAlert(context, 'Error', 'Ingresa el código de 6 dígitos');
      return;
    }
    setState(() => _cargando = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailRecuperacion, 'code': codigo}),
      ).timeout(const Duration(seconds: 15));

      setState(() => _cargando = false);
      final result = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && result['success'] == true) {
        setState(() { _mostrarVerificarCodigo = false; _mostrarNuevaPassword = true; });
        AlertService.showSuccessAlert(context, 'Código válido', 'Ahora crea tu nueva contraseña');
      } else {
        AlertService.showErrorAlert(context, 'Error', result['message'] ?? 'Código inválido o expirado');
        _codigoController.clear();
      }
    } catch (e) {
      setState(() => _cargando = false);
      AlertService.showErrorAlert(context, 'Error', 'Error de conexión');
    }
  }

  Future<void> _cambiarPassword() async {
    final nueva = _nuevaPasswordController.text.trim();
    final confirmar = _confirmarPasswordController.text.trim();
    if (nueva.isEmpty || confirmar.isEmpty) {
      AlertService.showErrorAlert(context, 'Error', 'Completa ambos campos');
      return;
    }
    if (nueva != confirmar) {
      AlertService.showErrorAlert(context, 'Error', 'Las contraseñas no coinciden');
      return;
    }
    if (nueva.length < 6) {
      AlertService.showErrorAlert(context, 'Error', 'Mínimo 6 caracteres');
      return;
    }
    setState(() => _cargando = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailRecuperacion, 'newPassword': nueva}),
      ).timeout(const Duration(seconds: 15));

      setState(() => _cargando = false);
      final result = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && result['success'] == true) {
        AlertService.showSuccessAlert(context, 'Contraseña cambiada', 'Inicia sesión con tu nueva contraseña');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        AlertService.showErrorAlert(context, 'Error', result['message'] ?? 'Error al cambiar contraseña');
      }
    } catch (e) {
      setState(() => _cargando = false);
      AlertService.showErrorAlert(context, 'Error', 'Error de conexión');
    }
  }

  void _resetearFlujo() {
    setState(() {
      _mostrarRecuperar = false;
      _mostrarVerificarCodigo = false;
      _mostrarNuevaPassword = false;
      _emailRecuperacionController.clear();
      _codigoController.clear();
      _nuevaPasswordController.clear();
      _confirmarPasswordController.clear();
      _emailRecuperacion = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TheBarColors.beigeClaro,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  color: TheBarColors.doradoCerveza,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
                ),
                child: const Icon(Icons.liquor, size: 80, color: TheBarColors.cafeOscuro),
              ),
              const SizedBox(height: 30),
              const Text('THE BAR', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: TheBarColors.cafeOscuro)),
              const SizedBox(height: 8),
              const Text('Sistema de Gestión', style: TextStyle(fontSize: 16, color: TheBarColors.azulOscuro)),
              const SizedBox(height: 40),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildFormActivo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormActivo() {
    if (_mostrarRecuperar) return _buildRecuperarForm();
    if (_mostrarVerificarCodigo) return _buildVerificarCodigoForm();
    if (_mostrarNuevaPassword) return _buildNuevaPasswordForm();
    return _buildLoginForm();
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Contraseña', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _iniciarSesion(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() { _mostrarRecuperar = true; _emailRecuperacionController.clear(); }),
            child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: TheBarColors.doradoCerveza)),
          ),
        ),
        const SizedBox(height: 16),
        _cargando
            ? const CircularProgressIndicator(color: TheBarColors.doradoCerveza)
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TheBarColors.doradoCerveza,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('INGRESAR', style: TextStyle(color: TheBarColors.cafeOscuro, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
      ],
    );
  }

  Widget _buildRecuperarForm() {
    return Column(
      children: [
        const Text('Recuperar Contraseña', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Ingresa tu email para recibir un código de 6 dígitos', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(
          controller: _emailRecuperacionController,
          decoration: const InputDecoration(
            labelText: 'Email registrado', prefixIcon: Icon(Icons.email), border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _cargando
            ? const CircularProgressIndicator(color: TheBarColors.doradoCerveza)
            : Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _resetearFlujo, child: const Text('CANCELAR'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _solicitarRecuperacion,
                      style: ElevatedButton.styleFrom(backgroundColor: TheBarColors.doradoCerveza),
                      child: const Text('ENVIAR', style: TextStyle(color: TheBarColors.cafeOscuro)),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildVerificarCodigoForm() {
    return Column(
      children: [
        const Text('Verificar Código', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('Código enviado a: $_emailRecuperacion', textAlign: TextAlign.center, style: const TextStyle(color: Colors.blue)),
        const SizedBox(height: 20),
        TextField(
          controller: _codigoController,
          decoration: const InputDecoration(
            labelText: 'Código de 6 dígitos', prefixIcon: Icon(Icons.vpn_key), border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 10),
        ),
        const SizedBox(height: 20),
        _cargando
            ? const CircularProgressIndicator(color: TheBarColors.doradoCerveza)
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() { _mostrarVerificarCodigo = false; _mostrarRecuperar = true; }),
                      child: const Text('VOLVER'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _verificarCodigo,
                      style: ElevatedButton.styleFrom(backgroundColor: TheBarColors.doradoCerveza),
                      child: const Text('VERIFICAR', style: TextStyle(color: TheBarColors.cafeOscuro)),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildNuevaPasswordForm() {
    return Column(
      children: [
        const Text('Nueva Contraseña', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _nuevaPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nueva contraseña', hintText: 'Mínimo 6 caracteres',
            prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmarPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        _cargando
            ? const CircularProgressIndicator(color: TheBarColors.doradoCerveza)
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() { _mostrarNuevaPassword = false; _mostrarVerificarCodigo = true; }),
                      child: const Text('VOLVER'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cambiarPassword,
                      style: ElevatedButton.styleFrom(backgroundColor: TheBarColors.doradoCerveza),
                      child: const Text('CAMBIAR', style: TextStyle(color: TheBarColors.cafeOscuro)),
                    ),
                  ),
                ],
              ),
      ],
    );
  }
}

// ==============================================
// PANTALLA PRINCIPAL (HOME) - CORREGIDA
// ==============================================
class HomeScreen extends StatefulWidget {
  final String usuarioEmail;
  final String token;
  final Map<String, dynamic> userData;

  const HomeScreen({
    super.key,
    required this.usuarioEmail,
    required this.token,
    required this.userData,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _paginaActual = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    // Inicializar con valores temporales
    _paginas = [
      const Center(child: CircularProgressIndicator()),
      const Center(child: CircularProgressIndicator()),
      const Center(child: CircularProgressIndicator()),
      const Center(child: CircularProgressIndicator()),
    ];
    
    // Cargar las páginas reales después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _paginas = [
          PaginaHome(usuarioEmail: widget.usuarioEmail, userData: widget.userData),
          DashboardScreen(token: widget.token, userData: widget.userData),
          VentasScreen(token: widget.token, userData: widget.userData),
          ComprasScreen(token: widget.token, userData: widget.userData),
        ];
        setState(() {});
      }
    });
  }

  void _cambiarPagina(int index) {
    setState(() => _paginaActual = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _cerrarSesion() async {
    final confirm = await AlertService.showConfirmDialog(context, 'Cerrar Sesión', '¿Estás seguro?');
    if (confirm && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Inicio', 'Dashboard', 'Ventas', 'Compras'];
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: TheBarColors.beigeClaro,
      appBar: AppBar(
        backgroundColor: TheBarColors.cafeOscuro,
        title: Row(
          children: [
            const Icon(Icons.liquor, color: TheBarColors.doradoCerveza),
            const SizedBox(width: 10),
            Text('${titles[_paginaActual]} - THE BAR', style: const TextStyle(color: TheBarColors.blanco)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: TheBarColors.doradoCerveza),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildDrawer(),
      body: _paginas[_paginaActual],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: TheBarColors.cafeOscuro,
        child: Column(
          children: [
            Container(
              height: 180, color: TheBarColors.cafeOscuro,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(color: TheBarColors.doradoCerveza, shape: BoxShape.circle),
                      child: const Icon(Icons.liquor, size: 50, color: TheBarColors.cafeOscuro),
                    ),
                    const SizedBox(height: 15),
                    const Text('THE BAR', style: TextStyle(color: Colors.white, fontSize: 24)),
                    const SizedBox(height: 5),
                    Text(
                      fixTextEncoding(widget.userData['nombre_completo'] ?? 'Usuario'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(Icons.home, 'Inicio', 0),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 1),
            _buildDrawerItem(Icons.shopping_cart, 'Ventas', 2),
            _buildDrawerItem(Icons.inventory, 'Compras', 3),
            const Spacer(),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: _cerrarSesion,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String titulo, int index) {
    final selected = _paginaActual == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? TheBarColors.doradoCerveza.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: TheBarColors.doradoCerveza) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? TheBarColors.doradoCerveza : TheBarColors.blanco),
        title: Text(titulo, style: TextStyle(color: selected ? TheBarColors.doradoCerveza : TheBarColors.blanco)),
        onTap: () => _cambiarPagina(index),
      ),
    );
  }
}

// ==============================================
// PÁGINA DE INICIO
// ==============================================
class PaginaHome extends StatelessWidget {
  final String usuarioEmail;
  final Map<String, dynamic> userData;

  const PaginaHome({super.key, required this.usuarioEmail, required this.userData});

  @override
  Widget build(BuildContext context) {
    final nombre = fixTextEncoding(userData['nombre_completo'] ?? 'Administrador');
    return Scaffold(
      backgroundColor: TheBarColors.beigeClaro,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: TheBarColors.cafeOscuro,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: TheBarColors.doradoCerveza, width: 3),
                        color: TheBarColors.doradoCerveza,
                      ),
                      child: const Icon(Icons.liquor, size: 50, color: TheBarColors.cafeOscuro),
                    ),
                    const SizedBox(height: 20),
                    const Text('THE BAR', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: TheBarColors.blanco, letterSpacing: 3)),
                    const SizedBox(height: 6),
                    const Text('Sistema de Gestión', style: TextStyle(fontSize: 15, color: Colors.white70, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Icon(Icons.waving_hand, size: 40, color: TheBarColors.doradoCerveza),
                  const SizedBox(height: 16),
                  const Text('¡Bienvenido!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TheBarColors.cafeOscuro)),
                  const SizedBox(height: 8),
                  Text(nombre, style: const TextStyle(fontSize: 18, color: TheBarColors.azulOscuro)),
                  const SizedBox(height: 8),
                  Text(usuarioEmail, style: TextStyle(fontSize: 14, color: TheBarColors.azulOscuro.withOpacity(0.6))),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: TheBarColors.cafeOscuro.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Text(
                  'Sistema móvil para la gestión de ventas en un bar, permitiendo controlar productos, clientes y registrar la venta de licores, cigarrillos y confitería de manera rápida y sencilla.',
                  style: TextStyle(fontSize: 15, color: TheBarColors.azulOscuro, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                '© THE BAR — Sistema de Gestión v1.0',
                style: TextStyle(fontSize: 12, color: TheBarColors.cafeOscuro.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================
// DASHBOARD CON GRÁFICOS - CORREGIDO
// ==============================================
class DashboardScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.token, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _ventas = [];
  List<dynamic> _compras = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return {'success': false, 'data': []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final ventasData = await _get('/api/ventas');
      final comprasData = await _get('/api/compras');
      
      if (ventasData['success'] == true) {
        setState(() => _ventas = ventasData['data'] ?? []);
      }
      if (comprasData['success'] == true) {
        setState(() => _compras = comprasData['data'] ?? []);
      }
    } catch (e) {
      if (mounted) AlertService.showErrorAlert(context, 'Error', 'Error cargando datos del dashboard');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Función auxiliar para convertir a double
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remover comillas y convertir
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  double _calcularTotalVentas() {
    double total = 0;
    for (var venta in _ventas) {
      if (venta['estado'] == 1 || venta['estado'] == '1') {
        total += _parseToDouble(venta['total']);
      }
    }
    return total;
  }

  double _calcularTotalCompras() {
    double total = 0;
    for (var compra in _compras) {
      if (compra['estado'] == 2 || compra['estado'] == '2') {
        total += _parseToDouble(compra['total']);
      }
    }
    return total;
  }

  int _calcularCantidadVentas() {
    return _ventas.where((v) => v['estado'] == 1 || v['estado'] == '1').length;
  }

  int _calcularCantidadCompras() {
    return _compras.where((c) => c['estado'] == 2 || c['estado'] == '2').length;
  }

  Map<String, double> _getVentasPorMes() {
    Map<String, double> ventasPorMes = {};
    for (var venta in _ventas) {
      if (venta['estado'] == 1 || venta['estado'] == '1') {
        try {
          DateTime fecha = DateTime.parse(venta['fecha']);
          String mes = DateFormat('MMM yyyy').format(fecha);
          ventasPorMes[mes] = (ventasPorMes[mes] ?? 0) + _parseToDouble(venta['total']);
        } catch (_) {}
      }
    }
    return ventasPorMes;
  }

  Map<String, double> _getComprasPorMes() {
    Map<String, double> comprasPorMes = {};
    for (var compra in _compras) {
      if (compra['estado'] == 2 || compra['estado'] == '2') {
        try {
          DateTime fecha = DateTime.parse(compra['fecha']);
          String mes = DateFormat('MMM yyyy').format(fecha);
          comprasPorMes[mes] = (comprasPorMes[mes] ?? 0) + _parseToDouble(compra['total']);
        } catch (_) {}
      }
    }
    return comprasPorMes;
  }

  @override
  Widget build(BuildContext context) {
    final totalVentas = _calcularTotalVentas();
    final totalCompras = _calcularTotalCompras();
    final gananciaBruta = totalVentas - totalCompras;
    final ventasPorMes = _getVentasPorMes();
    final comprasPorMes = _getComprasPorMes();

    return Scaffold(
      backgroundColor: TheBarColors.beigeClaro,
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: TheBarColors.doradoCerveza))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Ventas',
                            '\$${formatCurrency(totalVentas)}',
                            Icons.shopping_cart,
                            TheBarColors.verdeExito,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Total Compras',
                            '\$${formatCurrency(totalCompras)}',
                            Icons.inventory,
                            TheBarColors.naranjaCalido,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      'Ganancia Bruta',
                      '\$${formatCurrency(gananciaBruta)}',
                      Icons.trending_up,
                      gananciaBruta >= 0 ? TheBarColors.verdeExito : TheBarColors.rojoError,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumen General',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        _calcularCantidadVentas().toString(),
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TheBarColors.verdeExito),
                                      ),
                                      const Text('Ventas', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(height: 40, width: 1, color: Colors.grey.shade300),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        _calcularCantidadCompras().toString(),
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TheBarColors.naranjaCalido),
                                      ),
                                      const Text('Compras', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(height: 40, width: 1, color: Colors.grey.shade300),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        (_calcularCantidadVentas() - _calcularCantidadCompras()).toString(),
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TheBarColors.doradoCerveza),
                                      ),
                                      const Text('Diferencia', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (ventasPorMes.isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shopping_cart, color: TheBarColors.verdeExito),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ventas por Mes',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildBarChart(ventasPorMes, TheBarColors.verdeExito),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (comprasPorMes.isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.inventory, color: TheBarColors.naranjaCalido),
                                  SizedBox(width: 8),
                                  Text(
                                    'Compras por Mes',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildBarChart(comprasPorMes, TheBarColors.naranjaCalido),
                            ],
                          ),
                        ),
                      ),
                    if (ventasPorMes.isEmpty && comprasPorMes.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart, size: 80, color: TheBarColors.cafeOscuro.withOpacity(0.4)),
                            const SizedBox(height: 20),
                            const Text('No hay datos para mostrar', style: TextStyle(color: TheBarColors.cafeOscuro, fontSize: 16)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _cargarDatos,
                              style: ElevatedButton.styleFrom(backgroundColor: TheBarColors.doradoCerveza),
                              child: const Text('REINTENTAR', style: TextStyle(color: TheBarColors.cafeOscuro)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricCard(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Icon(icono, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> datos, Color color) {
    if (datos.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Sin datos disponibles')));
    }

    final meses = datos.keys.toList();
    meses.sort((a, b) {
      try {
        final dateA = DateFormat('MMM yyyy').parse(a);
        final dateB = DateFormat('MMM yyyy').parse(b);
        return dateA.compareTo(dateB);
      } catch (_) {
        return 0;
      }
    });
    
    final ultimosMeses = meses.length > 6 ? meses.sublist(meses.length - 6) : meses;
    final maxValor = datos.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ultimosMeses.map((mes) {
              final valor = datos[mes] ?? 0.0;
              final double altura = maxValor > 0 ? (valor / maxValor) * 150 : 0.0;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: altura,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Transform.rotate(
                      angle: -0.5,
                      child: Text(mes, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0', style: TextStyle(fontSize: 10)),
            Text(formatCurrency(maxValor), style: const TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ==============================================
// VENTAS
// ==============================================
class VentasScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userData;

  const VentasScreen({super.key, required this.token, required this.userData});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  List<dynamic> _ventas = [];
  List<dynamic> _clientes = [];
  bool _cargando = true;
  String _filtroBusqueda = '';
  String _filtroEstado = 'Todos';
  int _paginaActual = 1;
  final int _registrosPorPagina = 4;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return {'success': false, 'data': []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final ventasData = await _get('/api/ventas');
      final clientesData = await _get('/api/clientes');
      if (ventasData['success'] == true) {
        setState(() => _ventas = ventasData['data'] ?? []);
      }
      if (clientesData['success'] == true) {
        final clientes = clientesData['data'] ?? [];
        for (var c in clientes) {
          if (c['nombre'] is String) c['nombre'] = fixTextEncoding(c['nombre']);
        }
        setState(() => _clientes = clientes);
      }
    } catch (e) {
      if (mounted) AlertService.showErrorAlert(context, 'Error', 'Error cargando ventas');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _nombreCliente(dynamic id) {
    if (id == null) return 'Sin cliente';
    try {
      final c = _clientes.firstWhere((c) => c['id_cliente'] == id, orElse: () => null);
      return c?['nombre'] ?? 'Cliente #$id';
    } catch (_) {
      return 'Cliente #$id';
    }
  }

  String _nombreEstado(dynamic estado) {
    switch (estado.toString()) {
      case '1': return 'Completado';
      case '0':
      case '3': return 'Anulado';
      default: return estado.toString();
    }
  }

  String _formatFecha(String fecha) {
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha)); }
    catch (_) { return fecha; }
  }

  Future<void> _verDetalle(dynamic venta) async {
    final data = await _get('/api/ventas/${venta['id_venta']}');
    final ventaCompleta = data['success'] == true ? data['data'] : null;
    final detalles = ventaCompleta?['detalles'] ?? [];
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => _DetalleDialog(
        titulo: 'Detalle de Venta',
        icono: Icons.receipt_long,
        infoLineas: [
          'Cliente: ${_nombreCliente(venta['id_cliente'])}',
          'Fecha: ${_formatFecha(venta['fecha'])}',
          'Estado: ${_nombreEstado(venta['estado'])}',
        ],
        detalles: detalles,
        total: venta['total'],
      ),
    );
  }

  List<dynamic> _ventasFiltradas() {
    var lista = _ventas.where((v) {
      if (_filtroEstado != 'Todos' && _nombreEstado(v['estado']) != _filtroEstado) return false;
      if (_filtroBusqueda.isNotEmpty) {
        final nombre = _nombreCliente(v['id_cliente']).toLowerCase();
        final id = v['id_venta'].toString();
        if (!nombre.contains(_filtroBusqueda.toLowerCase()) && !id.contains(_filtroBusqueda)) return false;
      }
      return true;
    }).toList();
    lista.sort((a, b) {
      try { return DateTime.parse(b['fecha']).compareTo(DateTime.parse(a['fecha'])); }
      catch (_) { return 0; }
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _ventasFiltradas();
    final totalRegistros = filtradas.length;
    final totalPaginas = totalRegistros == 0 ? 1 : (totalRegistros / _registrosPorPagina).ceil();
    final start = (_paginaActual - 1) * _registrosPorPagina;
    final end = (start + _registrosPorPagina).clamp(0, totalRegistros);
    final pagina = totalRegistros > start ? filtradas.sublist(start, end) : <dynamic>[];

    return Scaffold(
      backgroundColor: TheBarColors.beigeClaro,
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: TheBarColors.doradoCerveza))
                : filtradas.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: pagina.length,
                              itemBuilder: (_, i) => _buildVentaCard(pagina[i]),
                            ),
                          ),
                          _buildPaginacion(_paginaActual, totalPaginas, totalRegistros: totalRegistros,
                            onAnterior: () => setState(() => _paginaActual--),
                            onSiguiente: () => setState(() => _paginaActual++),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentaCard(dynamic venta) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(_nombreCliente(venta['id_cliente']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                _badgeEstado(venta['estado']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fecha: ${_formatFecha(venta['fecha'])}'),
                Text('Total: \$${formatCurrency(venta['total'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _verDetalle(venta),
                icon: const Icon(Icons.remove_red_eye, size: 16),
                label: const Text('Ver Detalles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TheBarColors.cafeOscuro,
                  foregroundColor: TheBarColors.beigeClaro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeEstado(dynamic estado) {
    Color color;
    switch (estado.toString()) {
      case '1': color = TheBarColors.verdeExito; break;
      case '0':
      case '3': color = TheBarColors.rojoError; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(_nombreEstado(estado), style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: TheBarColors.cafeOscuro,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: TheBarColors.beigeClaro, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por cliente o ID...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: TheBarColors.cafeOscuro),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() { _filtroBusqueda = v; _paginaActual = 1; }),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'Completado', 'Anulado'].map((estado) =>
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(estado),
                    selected: _filtroEstado == estado,
                    onSelected: (sel) => setState(() { _filtroEstado = sel ? estado : 'Todos'; _paginaActual = 1; }),
                    selectedColor: TheBarColors.doradoCerveza,
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: TheBarColors.cafeOscuro.withOpacity(0.4)),
          const SizedBox(height: 20),
          const Text('No hay ventas', style: TextStyle(color: TheBarColors.cafeOscuro, fontSize: 16)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _cargarDatos,
            style: ElevatedButton.styleFrom(backgroundColor: TheBarColors.doradoCerveza),
            child: const Text('REINTENTAR', style: TextStyle(color: TheBarColors.cafeOscuro)),
          ),
        ],
      ),
    );
  }
}

// ==============================================
// COMPRAS
// ==============================================
class ComprasScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> userData;

  const ComprasScreen({super.key, required this.token, required this.userData});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  List<dynamic> _compras = [];
  List<dynamic> _proveedores = [];
  bool _cargando = true;
  String _filtroBusqueda = '';
  String _filtroEstado = 'Todos';
  int _paginaActual = 1;
  final int _registrosPorPagina = 4;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Authorization': 'Bearer ${widget.token}', 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return {'success': false, 'data': []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final comprasData = await _get('/api/compras');
      final proveedoresData = await _get('/api/proveedores');
      if (comprasData['success'] == true) {
        setState(() => _compras = comprasData['data'] ?? []);
      }
      if (proveedoresData['success'] == true) {
        final proveedores = proveedoresData['data'] ?? [];
        for (var p in proveedores) {
          if (p['nombre_razon_social'] is String) {
            p['nombre_razon_social'] = fixTextEncoding(p['nombre_razon_social']);
          }
        }
        setState(() => _proveedores = proveedores);
      }
    } catch (e) {
      if (mounted) AlertService.showErrorAlert(context, 'Error', 'Error cargando compras');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _nombreProveedor(dynamic compra) {
    final nombreJoin = compra['nombre_proveedor'];
    if (nombreJoin != null && nombreJoin.toString().isNotEmpty) {
      return fixTextEncoding(nombreJoin.toString());
    }
    final id = compra['id_proveedor'];
    if (id == null) return 'Sin proveedor';
    try {
      final p = _proveedores.firstWhere((p) => p['id_proveedor'] == id, orElse: () => null);
      return p?['nombre_razon_social'] ?? 'Proveedor #$id';
    } catch (_) {
      return 'Proveedor #$id';
    }
  }

  String _nombreEstado(dynamic estado) {
    switch (estado.toString()) {
      case '1': return 'Pendiente';
      case '2': return 'Completado';
      case '0': return 'Anulado';
      default: return estado.toString();
    }
  }

  String _formatFecha(String fecha) {
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha)); }
    catch (_) { return fecha; }
  }

  Future<void> _verDetalle(dynamic compra) async {
    final data = await _get('/api/compras/${compra['id_compra']}');
    final compraCompleta = data['success'] == true ? data['data'] : null;
    final detalles = compraCompleta?['detalles'] ?? [];
    final nombreProv = compraCompleta?['nombre_razon_social'] ?? _nombreProveedor(compra);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => _DetalleDialog(
        titulo: 'Detalle de Compra',
        icono: Icons.receipt,
        infoLineas: [
          'Proveedor: ${fixTextEncoding(nombreProv.toString())}',
          'Factura: ${compraCompleta?['numero_factura'] ?? 'N/A'}',
          'Fecha: ${_formatFecha(compra['fecha'])}',
          'Estado: ${_nombreEstado(compra['estado'])}',
        ],
        detalles: detalles,
        total: compra['total'],
      ),
    );
  }

  List<dynamic> _comprasFiltradas() {
    var lista = _compras.where((c) {
      if (_filtroEstado != 'Todos' && _nombreEstado(c['estado']) != _filtroEstado) return false;
      if (_filtroBusqueda.isNotEmpty) {
        final nombre = _nombreProveedor(c).toLowerCase();
        final id = c['id_compra'].toString();
        if (!nombre.contains(_filtroBusqueda.toLowerCase()) && !id.contains(_filtroBusqueda)) return false;
      }
      return true;
    }).toList();
    lista.sort((a, b) {
      try { return DateTime.parse(b['fecha']).compareTo(DateTime.parse(a['fecha'])); }
      catch (_) { return 0; }
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _comprasFiltradas();
    final totalRegistros = filtradas.length;
    final totalPaginas = totalRegistros == 0 ? 1 : (totalRegistros / _registrosPorPagina).ceil();
    final start = (_paginaActual - 1) * _registrosPorPagina;
    final end = (start + _registrosPorPagina).clamp(0, totalRegistros);
    final pagina = totalRegistros > start ? filtradas.sublist(start, end) : <dynamic>[];

    return Scaffold(
      backgroundColor: TheBarColors.beigeClaro,
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: TheBarColors.doradoCerveza))
                : filtradas.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: pagina.length,
                              itemBuilder: (_, i) => _buildCompraCard(pagina[i]),
                            ),
                          ),
                          _buildPaginacion(_paginaActual, totalPaginas, totalRegistros: totalRegistros,
                            onAnterior: () => setState(() => _paginaActual--),
                            onSiguiente: () => setState(() => _paginaActual++),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompraCard(dynamic compra) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(_nombreProveedor(compra), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                _badgeEstado(compra['estado']),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fecha: ${_formatFecha(compra['fecha'])}'),
                Text('Total: \$${formatCurrency(compra['total'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _verDetalle(compra),
                icon: const Icon(Icons.remove_red_eye, size: 16),
                label: const Text('Ver Detalles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TheBarColors.cafeOscuro,
                  foregroundColor: TheBarColors.beigeClaro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeEstado(dynamic estado) {
    Color color;
    switch (estado.toString()) {
      case '1': color = TheBarColors.naranjaCalido; break;
      case '2': color = TheBarColors.verdeExito; break;
      case '0': color = TheBarColors.rojoError; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(_nombreEstado(estado), style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: TheBarColors.cafeOscuro,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: TheBarColors.beigeClaro, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por proveedor o ID...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: TheBarColors.cafeOscuro),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() { _filtroBusqueda = v; _paginaActual = 1; }),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'Completado', 'Pendiente', 'Anulado'].map((estado) =>
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(estado),
                    selected: _filtroEstado == estado,
                    onSelected: (sel) => setState(() { _filtroEstado = sel ? estado : 'Todos'; _paginaActual = 1; }),
                    selectedColor: TheBarColors.doradoCerveza,
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_outlined, size: 80, color: TheBarColors.cafeOscuro.withOpacity(0.4)),
          const SizedBox(height: 20),
          const Text('No hay compras', style: TextStyle(color: TheBarColors.cafeOscuro, fontSize: 16)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _cargarDatos,
            style: ElevatedButton.styleFrom(backgroundColor: TheBarColors.doradoCerveza),
            child: const Text('REINTENTAR', style: TextStyle(color: TheBarColors.cafeOscuro)),
          ),
        ],
      ),
    );
  }
}

// ==============================================
// DIALOGO DE DETALLE REUTILIZABLE
// ==============================================
class _DetalleDialog extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<String> infoLineas;
  final List<dynamic> detalles;
  final dynamic total;

  const _DetalleDialog({
    required this.titulo,
    required this.icono,
    required this.infoLineas,
    required this.detalles,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: TheBarColors.cafeOscuro,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(icono, color: TheBarColors.doradoCerveza, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Icons.close, color: Colors.white70)),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: TheBarColors.beigeClaro, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: infoLineas.map((linea) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(linea, style: const TextStyle(fontSize: 14)))).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (detalles.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Sin productos', style: TextStyle(color: Colors.grey))))
                  else
                    ...detalles.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fixTextEncoding(d['nombre_producto'] ?? 'Producto'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('${d['cantidad']} x \$${formatCurrency(d['precio'])}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Text('\$${formatCurrency(d['subtotal'])}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    )),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: TheBarColors.doradoCerveza.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: TheBarColors.doradoCerveza)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('\$${formatCurrency(total)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================
// WIDGETS HELPERS GLOBALES
// ==============================================
Widget _buildPaginacion(
  int paginaActual,
  int totalPaginas, {
  required VoidCallback onAnterior,
  required VoidCallback onSiguiente,
  required int totalRegistros,
}) {
  if (totalRegistros <= 4) return const SizedBox.shrink();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade200)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: paginaActual > 1 ? onAnterior : null,
          icon: Icon(Icons.arrow_back_ios, size: 18, color: paginaActual > 1 ? TheBarColors.cafeOscuro : Colors.grey.shade300),
        ),
        Text('Página $paginaActual de $totalPaginas', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        IconButton(
          onPressed: paginaActual < totalPaginas ? onSiguiente : null,
          icon: Icon(Icons.arrow_forward_ios, size: 18, color: paginaActual < totalPaginas ? TheBarColors.cafeOscuro : Colors.grey.shade300),
        ),
      ],
    ),
  );
}