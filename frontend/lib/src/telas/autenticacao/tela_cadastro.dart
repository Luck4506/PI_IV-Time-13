// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_autenticacao.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const route = '/cadastro';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  UserRole role = UserRole.student;
  bool accepted = false;
  bool educational = false;
  bool get isEducational => role == UserRole.teacher || educational;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final classCodeController = TextEditingController();
  final birthDateController = TextEditingController();
  final teacherCodeController = TextEditingController();
  String? schoolCode;
  Map<String, String> schools = {};
  bool loadingSchools = false;
  bool schoolsFailed = false;
  String? schoolYear;
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() {
      loadingSchools = true;
      schoolsFailed = false;
    });

    try {
      final options = await ApiService.instance.schoolOptions();
      if (!mounted) return;

      setState(() {
        schools = options;
        if (!options.containsKey(schoolCode)) schoolCode = null;
      });
    } on ApiException {
      if (mounted) setState(() => schoolsFailed = true);
    } finally {
      if (mounted) setState(() => loadingSchools = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      nameController,
      emailController,
      passwordController,
      classCodeController,
      birthDateController,
      teacherCodeController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (loading || !accepted || !formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final enrollmentCode = classCodeController.text.trim();
    final student = role == UserRole.student;

    setState(() {
      loading = true;
      error = null;
    });
    try {
      final registration = await ApiService.instance.register(
        name: nameController.text.trim(),
        email: email,
        password: passwordController.text,
        role: role.name,
        schoolField: student ? schoolYear! : '',
        educational: isEducational,
        schoolCode: isEducational ? schoolCode : null,
        birthDate: birthDateController.text.trim(),
        teacherCode: student ? null : teacherCodeController.text.trim(),
        classCode: student && isEducational && enrollmentCode.isNotEmpty
            ? enrollmentCode
            : null,
      );
      if (!mounted) return;

      if (registration.needsVerification) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(
            builder: (_) => EmailVerificationScreen(
              email: email.toLowerCase(),
              emailSent: registration.emailSent,
              afterSignup: true,
            ),
          ),
          (_) => false,
        );
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        registration.user!.role == 'student'
            ? DiagnosticIntroScreen.route
            : TeacherShell.route,
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialRole = ModalRoute.of(context)?.settings.arguments;
    if (!_initialized && initialRole is UserRole) role = initialRole;
    _initialized = true;
  }

  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: 540,
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crie sua conta',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leva menos de dois minutos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.student,
                        label: Text('Estudante'),
                      ),
                      ButtonSegment(
                        value: UserRole.teacher,
                        label: Text('Professor'),
                      ),
                    ],
                    selected: {role},
                    showSelectedIcon: false,
                    onSelectionChanged: loading
                        ? null
                        : (value) => setState(() => role = value.first),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: nameController,
                    enabled: !loading,
                    validator: validateRequired,
                    decoration: InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailController,
                    enabled: !loading,
                    validator: validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: birthDateController,
                    enabled: !loading,
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      final data = value?.trim() ?? '';
                      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data)) {
                        return null;
                      }
                      return 'Informe a data no formato AAAA-MM-DD.';
                    },
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      hintText: 'AAAA-MM-DD',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (role == UserRole.student)
                    DropdownButtonFormField<String>(
                      key: const Key('school-year-select'),
                      initialValue: schoolYear,
                      isExpanded: true,
                      items: ApiService.schoolYears
                          .map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text(
                                year,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: loading
                          ? null
                          : (value) => setState(() => schoolYear = value),
                      validator: (value) =>
                          value == null ? 'Selecione seu ano escolar.' : null,
                      decoration: const InputDecoration(
                        labelText: 'Ano escolar',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (role == UserRole.student)
                    SwitchListTile.adaptive(
                      key: const Key('educational-registration'),
                      value: educational,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cadastro educacional'),
                      subtitle: const Text(
                        'Vou usar o $appName com a minha escola.',
                      ),
                      onChanged: loading
                          ? null
                          : (value) => setState(() {
                              educational = value;
                              if (!value) schoolCode = null;
                            }),
                    )
                  else
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.school_outlined),
                      title: Text('Cadastro educacional'),
                      subtitle: Text(
                        'Professores sempre usam uma conta educacional.',
                      ),
                    ),
                  if (isEducational) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      key: ValueKey('school-select-${role.name}-$educational'),
                      initialValue: schoolCode,
                      isExpanded: true,
                      items: schools.entries
                          .map(
                            (school) => DropdownMenuItem(
                              value: school.key,
                              child: Text(
                                school.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: loading
                          ? null
                          : (value) => setState(() => schoolCode = value),
                      validator: (value) =>
                          value == null ? 'Selecione sua escola.' : null,
                      decoration: InputDecoration(
                        labelText: 'Escola',
                        prefixIcon: const Icon(Icons.school_outlined),
                        helperText: loadingSchools
                            ? 'Carregando escolas…'
                            : schoolsFailed
                            ? 'Não foi possível carregar as escolas.'
                            : schools.isEmpty
                            ? 'Nenhuma escola disponível.'
                            : null,
                      ),
                    ),
                  ],
                  if (schoolsFailed)
                    TextButton(
                      onPressed: _loadSchools,
                      child: const Text('Recarregar escolas'),
                    ),
                  if (role == UserRole.teacher) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: teacherCodeController,
                      enabled: !loading,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          RegExp(r'^[0-9]{4}$').hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Informe o código de professor com 4 dígitos.',
                      decoration: const InputDecoration(
                        labelText: 'Código de professor',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ],
                  if (role == UserRole.student && isEducational) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('class-code-register'),
                      controller: classCodeController,
                      enabled: !loading,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? null
                          : validateClassCode(value),
                      decoration: const InputDecoration(
                        labelText: 'Código da turma (opcional)',
                        helperText: 'Use o código fornecido pela sua turma.',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    enabled: !loading,
                    validator: validatePassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Crie uma senha',
                      helperText: 'Use 8 caracteres ou mais, com 1 letra, 2 números e 1 símbolo.',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    value: accepted,
                    onChanged: loading
                        ? null
                        : (value) => setState(() => accepted = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Li e aceito os termos de uso e a política de privacidade.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: accepted && !loading ? _register : null,
                    child: Text(
                      loading
                          ? 'Criando conta…'
                          : role == UserRole.student
                          ? 'Continuar e personalizar'
                          : 'Continuar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
