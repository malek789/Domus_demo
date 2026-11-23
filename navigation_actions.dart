part of '../main.dart';

extension _NavigationActions on _DomusHomeState {
  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _LocalizedText(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ink,
        ),
      );
  }

  void _requireLogin(String message, {bool closeRoute = false}) {
    if (closeRoute && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (!mounted) return;
    _update(() {
      _tab = 4;
      _section = 'main';
      _registerMode = false;
      _authFlow = 'login';
      _authErrors.clear();
    });
    _showNotice(message);
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    // Normalize decoded JSON arrays into the map type used throughout the screens.
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _changeTab(int value) {
    _messagePoll?.cancel();
    _update(() {
      _tab = value;
      _section = 'main';
      _selectedConversation = null;
    });
  }

  Future<void> _openLegalPage(String path) async {
    final uri = Uri.parse(apiBaseUrl).resolve(path);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _showNotice('Impossible d’ouvrir cette page pour le moment.');
    }
  }

  Future<void> _acceptCurrentTerms() async {
    // Persist consent server-side before enabling account actions that require it.
    final session = _token;
    if (session == null || !_acceptedTerms) return;
    _update(() => _busy = true);
    try {
      final result = await _request(
        '/terms/accept',
        method: 'POST',
        session: session,
      );
      if (!mounted) return;
      _update(() {
        _user = {...?_user, ...result};
        _acceptedTerms = false;
      });
      await _loadUserData(session);
    } catch (error) {
      if (mounted) {
        _showNotice(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) _update(() => _busy = false);
    }
  }
}
