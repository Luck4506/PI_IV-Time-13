// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'widgets.dart';

class RemoteContent<T> extends StatefulWidget {
  const RemoteContent({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, VoidCallback refresh)
  builder;

  @override
  State<RemoteContent<T>> createState() => _RemoteContentState<T>();
}

class _RemoteContentState<T> extends State<RemoteContent<T>> {
  late Future<T> result = widget.load();

  void _refresh() {
    final next = widget.load();
    setState(() {
      result = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException
                        ? error.message
                        : 'Não foi possível carregar os dados.',
                  ),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        return widget.builder(context, snapshot.data as T, _refresh);
      },
    );
  }
}

class ScrollPage extends StatelessWidget {
  const ScrollPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageFrame(
          maxWidth: 760,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: children,
          ),
        ),
      ),
    );
  }
}
