part of '../main.dart';

extension _MessagingActions on _DomusHomeState {
  Future<void> _openConversation(Map<String, dynamic> property) async {
    // Ask the server for the buyer/listing conversation, reusing it if it exists.
    if (_token == null) {
      _requireLogin(
        'Connectez-vous pour contacter le propriétaire.',
        closeRoute: true,
      );
      return;
    }
    try {
      final result = await _request(
        '/conversations',
        method: 'POST',
        session: _token,
        body: {'propertyId': property['id']},
      );
      final id = result['id'] as int;
      final entry = <String, dynamic>{
        'id': id,
        'propertyId': property['id'],
        'propertyTitle': property['title'],
        'contactName': property['ownerName'],
        'contactUserId': property['ownerId'],
        'lastMessage': null,
      };
      await _loadMessages(id);
      if (!mounted) return;
      Navigator.pop(context);
      _update(() {
        _selectedConversation = entry;
        _tab = 3;
      });
      _startMessagePolling(id);
    } catch (error) {
      if (mounted) {
        _showNotice(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _loadMessages(int id) async {
    if (_token == null) return;
    final result = await _request(
      '/conversations/$id/messages',
      session: _token,
    );
    if (mounted) _update(() => _messages = _mapList(result['items']));
    await _loadUserData(_token!);
  }

  void _startMessagePolling(int id) {
    // Poll only the open conversation and stop applying results after navigation.
    _messagePoll?.cancel();
    _messagePoll = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final result = await _request(
          '/conversations/$id/messages',
          session: _token,
        );
        if (mounted && _selectedConversation?['id'] == id) {
          _update(() => _messages = _mapList(result['items']));
        }
      } catch (error) {
        if (mounted) {
          _showNotice(error.toString().replaceFirst('Exception: ', ''));
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final conversation = _selectedConversation;
    final session = _token;
    final body = _messageDraft.text.trim();
    if (_sendingMessage ||
        session == null ||
        conversation == null ||
        body.isEmpty) {
      return;
    }
    _update(() => _sendingMessage = true);
    try {
      await _request(
        '/conversations/${conversation['id']}/messages',
        method: 'POST',
        session: session,
        body: {'body': body},
      );
      if (mounted &&
          _selectedConversation?['id'] == conversation['id'] &&
          _messageDraft.text.trim() == body) {
        _messageDraft.clear();
      }
      await _loadMessages(conversation['id'] as int);
    } catch (error) {
      if (mounted) {
        if (error is DomusApiException &&
            error.code == 'terms_acceptance_required') {
          _update(() {
            _user = {...?_user, 'termsAcceptedAt': null};
            _acceptedTerms = false;
          });
        } else {
          _showNotice(error.toString().replaceFirst('Exception: ', ''));
        }
      }
    } finally {
      if (mounted) _update(() => _sendingMessage = false);
    }
  }
}
