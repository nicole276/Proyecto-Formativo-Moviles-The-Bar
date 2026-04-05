import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto2/main.dart';
import 'package:intl/intl.dart';

void main() {
  // ==============================================
  // PRUEBAS BÁSICAS DE CONSTRUCCIÓN
  // ==============================================
  testWidgets('MyApp builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsAtLeast(1));
  });

  testWidgets('LoginScreen is the initial screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('THE BAR'), findsOneWidget);
  });

  // ==============================================
  // PRUEBAS DE LoginScreen
  // ==============================================
  testWidgets('LoginScreen has all required elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
    
    expect(find.text('THE BAR'), findsOneWidget);
    expect(find.text('Sistema de Gestión'), findsOneWidget);
    expect(find.text('INGRESAR'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.textContaining('thebar752@gmail.com'), findsOneWidget);
  });

  testWidgets('Login form fields can accept input', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
    
    final emailFields = find.byType(TextField);
    expect(emailFields, findsNWidgets(2));
    
    await tester.enterText(emailFields.at(0), 'test@example.com');
    await tester.enterText(emailFields.at(1), 'password123');
    
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('password123'), findsOneWidget);
  });

  // ==============================================
  // PRUEBAS DE HomeScreen
  // ==============================================
  testWidgets('HomeScreen builds correctly', (WidgetTester tester) async {
    final testUserData = {
      'id': 1,
      'nombre_completo': 'Usuario Test',
      'email': 'test@example.com'
    };
    
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          usuarioEmail: 'test@example.com',
          token: 'test_token',
          userData: testUserData,
        ),
      ),
    );
    await tester.pumpAndSettle();
    
    expect(find.text('¡Bienvenido al Sistema!'), findsOneWidget);
    expect(find.text('Usuario Test'), findsOneWidget);
  });

  // ==============================================
  // PRUEBAS DE VentasScreen (ACTUALIZADA)
  // ==============================================
  testWidgets('VentasScreen builds correctly', (WidgetTester tester) async {
    final testUserData = {
      'id': 1,
      'nombre_completo': 'Usuario Test'
    };
    
    await tester.pumpWidget(
      MaterialApp(
        home: VentasScreen(
          token: 'test_token',
          userData: testUserData,
        ),
      ),
    );
    
    await tester.pump();
    
    expect(find.text('Ventas - THE BAR'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Completado'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Anulado'), findsOneWidget);
  });

  // ==============================================
  // PRUEBAS DE ComprasScreen (NUEVA)
  // ==============================================
  testWidgets('ComprasScreen builds correctly', (WidgetTester tester) async {
    final testUserData = {
      'id': 1,
      'nombre_completo': 'Usuario Test'
    };
    
    await tester.pumpWidget(
      MaterialApp(
        home: ComprasScreen(
          token: 'test_token',
          userData: testUserData,
        ),
      ),
    );
    
    await tester.pump();
    
    expect(find.text('Compras - THE BAR'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Completado'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Anulado'), findsOneWidget);
  });

  // ==============================================
  // PRUEBAS DE COLORES
  // ==============================================
  test('TheBarColors are defined correctly', () {
    expect(TheBarColors.beigeClaro, isNotNull);
    expect(TheBarColors.cafeOscuro, isNotNull);
    expect(TheBarColors.doradoCerveza, isNotNull);
    expect(TheBarColors.naranjaCalido, isNotNull);
    expect(TheBarColors.azulOscuro, isNotNull);
    expect(TheBarColors.blanco, isNotNull);
    expect(TheBarColors.verdeExito, isNotNull);
    expect(TheBarColors.rojoError, isNotNull);
  });

  test('TheBarColors have correct hex values', () {
    expect(TheBarColors.beigeClaro, const Color(0xFFF5EFE6));
    expect(TheBarColors.cafeOscuro, const Color(0xFF3B2E2A));
    expect(TheBarColors.doradoCerveza, const Color(0xFFD99A00));
    expect(TheBarColors.naranjaCalido, const Color(0xFFD86633));
    expect(TheBarColors.azulOscuro, const Color(0xFF0F1A24));
    expect(TheBarColors.blanco, const Color(0xFFFFFFFF));
    expect(TheBarColors.verdeExito, const Color(0xFF2E7D32));
    expect(TheBarColors.rojoError, const Color(0xFFC62828));
  });

  // ==============================================
  // PRUEBAS DE UTILIDADES
  // ==============================================
  test('DateFormat utility works correctly', () {
    final date = DateTime(2024, 1, 15, 14, 30);
    final formatted = DateFormat('dd/MM/yyyy HH:mm').format(date);
    expect(formatted, '15/01/2024 14:30');
  });

  test('Widget classes exist', () {
    expect(MyApp, isNotNull);
    expect(LoginScreen, isNotNull);
    expect(HomeScreen, isNotNull);
    expect(VentasScreen, isNotNull);
    expect(ComprasScreen, isNotNull); // Cambiado de FormularioVentaScreen a ComprasScreen
    expect(PaginaHome, isNotNull);
    expect(AlertService, isNotNull);
  });

  // ==============================================
  // PRUEBAS DE ESTRUCTURA DE WIDGETS
  // ==============================================
  testWidgets('App uses correct theme colors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = materialApp.theme;
    
    expect(theme, isNotNull);
    expect(theme!.scaffoldBackgroundColor, TheBarColors.beigeClaro);
  });

  testWidgets('Login button is an ElevatedButton', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    
    final loginButton = find.widgetWithText(ElevatedButton, 'INGRESAR');
    expect(loginButton, findsOneWidget);
  });

  // ==============================================
  // PRUEBA FINAL - INTEGRACIÓN BÁSICA
  // ==============================================
  testWidgets('Complete app builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}