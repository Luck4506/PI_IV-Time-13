import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ExamQuestionSource extends StatelessWidget {
  const ExamQuestionSource({super.key, required this.question});

  final Map<String, dynamic> question;

  static Uri? bookletUrl(Map<String, dynamic> question) {
    final url = Uri.tryParse(question['provaUrl']?.toString() ?? '');
    final page = question['paginaProva'];
    if (url == null ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        page is! int ||
        page < 1) {
      return null;
    }

    return url.replace(fragment: 'page=$page');
  }

  Future<void> _open(BuildContext context, Uri url) async {
    try {
      final opened = await launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView,
        webOnlyWindowName: '_blank',
      );
      if (opened) return;
    } on PlatformException {
      // Se o sistema não abrir o PDF, ainda dá para copiar o endereço.
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Não foi possível abrir o caderno.'),
        action: SnackBarAction(
          label: 'Copiar link',
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: url.toString())),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = bookletUrl(question);
    if (url == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          '${question['banca']} ${question['ano']} · Questão ${question['numero']}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '${question['caderno']} · Página ${question['paginaProva']} do PDF',
        ),
        Text(
          question['nome'].toString(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        OutlinedButton.icon(
          onPressed: () => _open(context, url),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Abrir questão no caderno'),
        ),
        const Text(
          'Leia o enunciado no PDF e marque a letra correspondente aqui.',
        ),
      ],
    );
  }
}
