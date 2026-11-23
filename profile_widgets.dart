part of '../main.dart';

extension _ProfileWidgets on _DomusHomeState {
  Widget _privacyItem(String title, String body) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LocalizedText(
            title,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          _LocalizedText(body, style: const TextStyle(color: muted)),
        ],
      ),
    ),
  );

  Future<void> _openSupportEmail() async {
    final gmailUri = Uri.parse(
      'googlegmail://co?to=chihieya59%40gmail.com&subject=Domus%20support',
    );
    if (await launchUrl(gmailUri, mode: LaunchMode.externalApplication)) return;
    final mailUri = Uri(
      scheme: 'mailto',
      path: 'chihieya59@gmail.com',
      queryParameters: {'subject': 'Domus support'},
    );
    if (!await launchUrl(mailUri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _showNotice('Aucune application de messagerie n’est disponible.');
    }
  }

  Widget _subPage(String title, List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _update(() => _section = 'main'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const _LocalizedText('Mon profil'),
          ),
        ),
        _LocalizedText(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
