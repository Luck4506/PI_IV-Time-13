[1mdiff --git a/frontend/lib/src/telas/autenticacao/tela_cadastro.dart b/frontend/lib/src/telas/autenticacao/tela_cadastro.dart[m
[1mindex 9318c5c..cc5c68a 100755[m
[1m--- a/frontend/lib/src/telas/autenticacao/tela_cadastro.dart[m
[1m+++ b/frontend/lib/src/telas/autenticacao/tela_cadastro.dart[m
[36m@@ -1,6 +1,7 @@[m
 // Autoria de Lucas Soares Gonçalves RA 25009467[m
 part of '../../telas_autenticacao.dart';[m
 [m
[32m+[m
 class RegisterScreen extends StatefulWidget {[m
   const RegisterScreen({super.key});[m
 [m
[36m@@ -204,14 +205,9 @@[m [mclass _RegisterScreenState extends State<RegisterScreen> {[m
                   TextFormField([m
                     controller: birthDateController,[m
                     enabled: !loading,[m
[31m-                    keyboardType: TextInputType.datetime,[m
[31m-                    validator: (value) {[m
[31m-                      final data = value?.trim() ?? '';[m
[31m-                      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data)) {[m
[31m-                        return null;[m
[31m-                      }[m
[31m-                      return 'Informe a data no formato AAAA-MM-DD.';[m
[31m-                    },[m
[32m+[m[32m                    keyboardType: TextInputType.number,[m
[32m+[m[32m                    inputFormatters: [DateInputFormatter()],[m
[32m+[m[32m                    validator: validateBirthDate,[m
                     decoration: const InputDecoration([m
                       labelText: 'Data de nascimento',[m
                       hintText: 'AAAA-MM-DD',[m
[36m@@ -403,3 +399,42 @@[m [mclass _RegisterScreenState extends State<RegisterScreen> {[m
     );[m
   }[m
 }[m
[32m+[m
[32m+[m[32mclass DateInputFormatter extends TextInputFormatter {[m
[32m+[m[32m  @override[m
[32m+[m[32m  TextEditingValue formatEditUpdate([m
[32m+[m[32m    TextEditingValue oldValue,[m
[32m+[m[32m    TextEditingValue newValue,[m
[32m+[m[32m  ) {[m
[32m+[m[32m    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');[m
[32m+[m[32m    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;[m
[32m+[m
[32m+[m[32m    final buffer = StringBuffer();[m
[32m+[m[32m    for (var i = 0; i < limited.length; i++) {[m
[32m+[m[32m      if (i == 4 || i == 6) buffer.write('-');[m
[32m+[m[32m      buffer.write(limited[i]);[m
[32m+[m[32m    }[m
[32m+[m
[32m+[m[32m    final text = buffer.toString();[m
[32m+[m[32m    return TextEditingValue([m
[32m+[m[32m      text: text,[m
[32m+[m[32m      selection: TextSelection.collapsed(offset: text.length),[m
[32m+[m[32m    );[m
[32m+[m[32m  }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m[32mString? validateBirthDate(String? value) {[m
[32m+[m[32m  final text = value?.trim() ?? '';[m
[32m+[m[32m  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {[m
[32m+[m[32m    return 'Informe a data no formato AAAA-MM-DD.';[m
[32m+[m[32m  }[m
[32m+[m[32m  final parts = text.split('-').map(int.parse).toList();[m
[32m+[m[32m  final date = DateTime(parts[0], parts[1], parts[2]);[m
[32m+[m[32m  if (date.year != parts[0] || date.month != parts[1] || date.day != parts[2]) {[m
[32m+[m[32m    return 'Data inválida.';[m
[32m+[m[32m  }[m
[32m+[m[32m  if (date.isAfter(DateTime.now()) || parts[0] < 1900) {[m
[32m+[m[32m    return 'Data fora do intervalo permitido.';[m
[32m+[m[32m  }[m
[32m+[m[32m  return null;[m
[32m+[m[32m}[m
\ No newline at end of file[m
