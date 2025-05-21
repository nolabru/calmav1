import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:calma_flutter/core/theme/app_theme.dart';
import 'package:calma_flutter/presentation/navigation/app_router.dart';
import 'package:calma_flutter/core/services/supabase_service.dart';
import 'package:calma_flutter/core/di/injection.dart';

/// Ponto de entrada principal do aplicativo C'Alma
/// 
/// Inicializa o aplicativo configurando orientação, tema, e rotas.
/// Estruturado seguindo os princípios de Clean Architecture e SOLID.
void main() async {
  // Garante que o binding do Flutter seja inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variáveis de ambiente
  await dotenv.load(fileName: ".env");
  
  // Inicializa o Supabase
  await SupabaseService.initialize();
  
  // Configura a injeção de dependência
  setupInjection();

  // Configura a aplicação para funcionar apenas na orientação vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializa o aplicativo
  runApp(const CalmaApp());
}

/// CalmaApp - Widget raiz do aplicativo C'Alma
/// 
/// Configura a aplicação com tema e sistema de navegação.
class CalmaApp extends StatelessWidget {
  const CalmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "C'Alma",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // Inicialmente igual ao tema claro
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
