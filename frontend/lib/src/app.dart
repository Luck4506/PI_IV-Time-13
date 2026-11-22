// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/api_service.dart';
import 'telas_autenticacao.dart';
import 'telas_estudante.dart';
import 'telas_professor.dart';
import 'theme.dart';
import 'user_trail_view.dart';

const _portugues = Locale('pt', 'BR');

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
  bool restoring = true;
  bool hadSession = false;
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

  Widget _trailPage(Object? arguments) {
    final trailId = arguments is Map ? arguments['trilhaId'] : arguments;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha trilha')),
      body: UserTrailView(initialTrailId: trailId is String ? trailId : null),
    );
  }

  bool _roleAllows(String route) {
    if (route.startsWith('/professor')) return api.user?.role == 'teacher';

    final studentRoute =
        route.startsWith('/aluno') ||
        route.startsWith('/diagnostico') ||
        route == NotificationsScreen.route ||
        route == PracticeScreen.route;
    return !studentRoute || api.user?.role == 'student';
  }

  Route<void> _route(RouteSettings settings) {
    final name = settings.name ?? LoginScreen.route;
    final public = [LoginScreen.route, RegisterScreen.route].contains(name);
    Widget screen;
    if (!public && api.user == null) {
      screen = const LoginScreen();
    } else if (!_roleAllows(name)) {
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
        LoginScreen.route => const LoginScreen(),
        RegisterScreen.route => const RegisterScreen(),
        DiagnosticIntroScreen.route => const DiagnosticIntroScreen(),
        DiagnosticQuizScreen.route => const DiagnosticQuizScreen(),
        StudentShell.route => const StudentShell(),
        '/aluno/trilha' => _trailPage(settings.arguments),
        TeacherShell.route => const TeacherShell(),
        NotificationsScreen.route => const NotificationsScreen(),
        PracticeScreen.route => const PracticeScreen(),
        _ =>
          api.user == null
              ? const LoginScreen()
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
        title: appName,
        locale: _portugues,
        supportedLocales: const [_portugues],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
      title: appName,
      locale: _portugues,
      supportedLocales: const [_portugues],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: buildTrilhaTheme(),
      initialRoute: initialRoute,
      onGenerateInitialRoutes: (name) => [_route(RouteSettings(name: name))],
      onGenerateRoute: _route,
    );
  }
}
