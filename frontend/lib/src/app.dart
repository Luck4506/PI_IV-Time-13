import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'telas_autenticacao.dart';
import 'telas_estudante.dart';
import 'telas_professor.dart';
import 'theme.dart';

class TrilhaApp extends StatefulWidget {
  const TrilhaApp({super.key});
  @override
  State<TrilhaApp> createState() => _TrilhaAppState();
}

class _TrilhaAppState extends State<TrilhaApp> {
  final navigator = GlobalKey<NavigatorState>();
  late final api = ApiService.instance;
  late final requestedRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  bool restoring = true, hadSession = false;
  String? restoreError;
  String get homeRoute =>
      api.user?.role == 'teacher' ? TeacherShell.route : StudentShell.route;

  @override
  void initState() {
    super.initState();
    api.addListener(_sessionChanged);
    _restore();
  }

  @override
  void dispose() {
    api.removeListener(_sessionChanged);
    super.dispose();
  }

  void _sessionChanged() {
    final ended = hadSession && api.user == null;
    hadSession = api.user != null;
    if (ended && !restoring) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && api.user == null) {
          navigator.currentState?.pushNamedAndRemoveUntil(
            LoginScreen.route,
            (_) => false,
          );
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  Future<void> _restore() async {
    setState(() {
      restoring = true;
      restoreError = null;
    });
    try {
      await api.restoreSession();
    } on ApiException catch (e) {
      if (mounted) setState(() => restoreError = e.message);
    } finally {
      if (mounted) {
        setState(() {
          restoring = false;
          hadSession = api.user != null;
        });
      }
    }
  }

  String get initialRoute {
    if (requestedRoute == '/' || requestedRoute.isEmpty) {
      return api.user == null ? LoginScreen.route : homeRoute;
    }
    if (api.user != null &&
        [LoginScreen.route, RegisterScreen.route].contains(requestedRoute)) {
      return homeRoute;
    }
    return requestedRoute;
  }

  Route<void> _route(RouteSettings settings) {
    final name = settings.name ?? LoginScreen.route;
    final public = [LoginScreen.route, RegisterScreen.route].contains(name);
    Widget screen;
    if (!public && api.user == null) {
      screen = const LoginScreen(initialRole: UserRole.student);
    } else if ((name.startsWith('/professor') && api.user?.role != 'teacher') ||
        ((name.startsWith('/aluno') ||
                name.startsWith('/diagnostico') ||
                name == NotificationsScreen.route) &&
            api.user?.role != 'student')) {
      screen = Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sua conta não tem acesso a esta área.'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      homeRoute,
                      (_) => false,
                    ),
                    child: const Text('Ir para minha área'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      screen = switch (name) {
        LoginScreen.route => LoginScreen(
          initialRole: settings.arguments is UserRole
              ? settings.arguments as UserRole
              : UserRole.student,
        ),
        RegisterScreen.route => const RegisterScreen(),
        DiagnosticIntroScreen.route => const DiagnosticIntroScreen(),
        DiagnosticQuizScreen.route => const DiagnosticQuizScreen(),
        DiagnosticResultScreen.route => const DiagnosticResultScreen(),
        StudentShell.route => const StudentShell(),
        TeacherShell.route => const TeacherShell(),
        NotificationsScreen.route => const NotificationsScreen(),
        PracticeScreen.route => const PracticeScreen(),
        MaterialDetailScreen.route => const MaterialDetailScreen(),
        ClassDetailScreen.route => ClassDetailScreen(
          classInfo: settings.arguments is ClassInfo
              ? settings.arguments as ClassInfo
              : ClassInfo.samples.first,
        ),
        StudentDetailScreen.route => StudentDetailScreen(
          student: settings.arguments is StudentProfileData
              ? settings.arguments as StudentProfileData
              : StudentProfiles.marina,
        ),
        _ =>
          api.user == null
              ? const LoginScreen(initialRole: UserRole.student)
              : api.user!.role == 'teacher'
              ? const TeacherShell()
              : const StudentShell(),
      };
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => screen,
      fullscreenDialog: name == PracticeScreen.route,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (restoring || restoreError != null) {
      final bootScreen = Scaffold(
        body: SafeArea(
          child: Center(
            child: restoring
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Não foi possível confirmar sua sessão.'),
                        const SizedBox(height: 12),
                        Text(restoreError!),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _restore,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      );
      return MaterialApp(
        key: ValueKey('boot-${restoreError != null}'),
        title: 'Trilha',
        debugShowCheckedModeBanner: false,
        theme: buildTrilhaTheme(),
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => bootScreen),
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/'),
            builder: (_) => bootScreen,
          ),
        ],
      );
    }
    return MaterialApp(
      key: const ValueKey('ready'),
      navigatorKey: navigator,
      title: 'Trilha',
      debugShowCheckedModeBanner: false,
      theme: buildTrilhaTheme(),
      initialRoute: initialRoute,
      onGenerateInitialRoutes: (name) => [_route(RouteSettings(name: name))],
      onGenerateRoute: _route,
    );
  }
}
