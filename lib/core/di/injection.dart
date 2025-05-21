import 'package:get_it/get_it.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/reminders/presentation/viewmodels/reminder_viewmodel.dart';

/// GetIt instance para injeção de dependência
final getIt = GetIt.instance;

/// Configura a injeção de dependência para toda a aplicação
void setupInjection() {
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(),
  );
  
  // ViewModels
  getIt.registerFactory(
    () => AuthViewModel(getIt<AuthRepository>()),
  );
  
  getIt.registerFactory(
    () => ReminderViewModel(),
  );
}
