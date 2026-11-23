part of '../main.dart';

extension _MessagesScreen on _DomusHomeState {
  Widget _buildMessages() {
    if (_token == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _LocalizedText(
            'Messages',
            style: TextStyle(
              color: ink,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          _authCard(),
        ],
      );
    }
    if (_selectedConversation != null) return _buildConversation();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _LocalizedText(
          'VOTRE ESPACE',
          style: TextStyle(
            color: teal,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 5),
        const _LocalizedText(
          'Messages',
          style: TextStyle(
            color: ink,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_conversations.isEmpty)
          _emptyState(
            'Aucune conversation',
            'Contactez un propriétaire depuis une annonce pour démarrer.',
          )
        else
          ..._conversations.map(
            (conversation) => Card(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: mint,
                  foregroundColor: teal,
                  child: _LocalizedText(
                    (conversation['contactName'] as String? ?? '?')
                        .characters
                        .first,
                  ),
                ),
                title: _LocalizedText(
                  conversation['contactName'] as String? ?? 'Propriétaire',
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: _LocalizedText(
                  '${conversation['propertyTitle'] ?? ''}\n${conversation['lastMessage'] ?? 'Démarrer la conversation'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right, color: muted),
                onTap: () async {
                  final id = conversation['id'] as int;
                  await _loadMessages(id);
                  if (mounted) {
                    _update(() => _selectedConversation = conversation);
                    _startMessagePolling(id);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConversation() {
    // Displays the selected thread, offers safety actions, and sends new messages.
    final conversation = _selectedConversation!;
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: teal),
            onPressed: () {
              _messagePoll?.cancel();
              _update(() => _selectedConversation = null);
            },
          ),
          title: _LocalizedText(
            conversation['contactName'] as String? ?? 'Conversation',
            style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          subtitle: _LocalizedText(
            conversation['propertyTitle'] as String? ?? '',
          ),
          trailing: PopupMenuButton<String>(
            tooltip: _t('Actions sur cet utilisateur'),
            onSelected: (action) {
              final userId = conversation['contactUserId'];
              if (userId is! int) return;
              if (action == 'report') unawaited(_reportUser(userId));
              if (action == 'block') {
                unawaited(_blockConversationUser(conversation));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: _LocalizedText('Signaler cet utilisateur'),
              ),
              PopupMenuItem(
                value: 'block',
                child: _LocalizedText('Bloquer cet utilisateur'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: _messages.isEmpty
                ? [
                    const Center(
                      child: _LocalizedText(
                        'Posez une question sur ce bien pour démarrer.',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  ]
                : _messages.map((message) {
                    final own = message['senderId'] == _user?['id'];
                    return Align(
                      alignment: own
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 9),
                        decoration: BoxDecoration(
                          color: own ? teal : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _LocalizedText(
                          message['body'] as String? ?? '',
                          style: TextStyle(color: own ? Colors.white : ink),
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageDraft,
                    enabled: !_sendingMessage,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendingMessage ? null : _sendMessage,
                  icon: _sendingMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_upward),
                  style: IconButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
