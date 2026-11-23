part of '../main.dart';

extension _AuthScreen on _DomusHomeState {
  Widget _authCard() {
    if (_authFlow == 'verify') {
      return Card(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 16, bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LocalizedText(
                'Vérifier votre adresse e-mail',
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const _LocalizedText(
                'Saisissez le code de vérification à 6 chiffres reçu par e-mail.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              _textField(
                'Code de vérification',
                _authToken,
                hint: 'Code à 6 chiffres',
                keyboard: TextInputType.number,
                maxLength: 6,
                digitsOnly: true,
              ),
              const SizedBox(height: 12),
              _primaryButton(
                _busy ? 'Veuillez patienter…' : 'Vérifier mon adresse',
                _busy ? null : _verifyEmail,
              ),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _resendVerificationEmail,
                  child: const _LocalizedText(
                    'Renvoyer le courriel de vérification',
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _update(() => _authFlow = 'login'),
                  child: const _LocalizedText('Retour à la connexion'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LocalizedText(
                      'DOMUS',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    _LocalizedText(
                      'VOTRE PROCHAIN CHEZ-VOUS',
                      style: TextStyle(
                        color: teal,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _LocalizedText(
              _registerMode ? 'Créer un compte' : 'Ravi de vous revoir',
              style: const TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const _LocalizedText(
              'Connectez-vous pour garder vos favoris et contacter les propriétaires.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            if (_registerMode)
              _textField(
                'Nom complet',
                _authName,
                hint: 'Votre nom',
                errorText: _authErrors['name'],
                onChanged: (_) => _update(() => _authErrors.remove('name')),
              ),
            _textField(
              'Adresse e-mail',
              _authEmail,
              hint: 'vous@exemple.tn',
              keyboard: TextInputType.emailAddress,
              errorText: _registerMode ? _authErrors['email'] : null,
              onChanged: (_) => _update(() => _authErrors.remove('email')),
            ),
            _textField(
              'Mot de passe',
              _authPassword,
              hint: '8 caractères minimum',
              obscure: true,
              errorText: _registerMode ? _authErrors['password'] : null,
              onChanged: (_) => _update(() => _authErrors.remove('password')),
            ),
            if (_registerMode)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedTerms,
                activeColor: teal,
                onChanged: (value) => _update(() {
                  _acceptedTerms = value ?? false;
                  _authErrors.remove('terms');
                }),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LocalizedText(
                      'J’accepte les conditions d’utilisation et la politique de confidentialité.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: () => _openLegalPage('/terms-of-use'),
                          child: const _LocalizedText(
                            'Conditions d’utilisation',
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openLegalPage('/privacy-policy'),
                          child: const _LocalizedText(
                            'Politique de confidentialité',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            if (_registerMode && _authErrors['terms'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _LocalizedText(
                  _authErrors['terms']!,
                  style: const TextStyle(color: danger, fontSize: 12),
                ),
              ),
            const SizedBox(height: 13),
            _primaryButton(
              _busy
                  ? 'Veuillez patienter…'
                  : (_registerMode ? 'Créer mon compte' : 'Se connecter'),
              _busy ? null : _signIn,
            ),
            Center(
              child: TextButton(
                onPressed: () => _update(() {
                  _registerMode = !_registerMode;
                  _authFlow = _registerMode ? 'register' : 'login';
                  _acceptedTerms = false;
                  _authErrors.clear();
                }),
                child: _LocalizedText(
                  _registerMode
                      ? 'Déjà un compte ? Se connecter'
                      : 'Nouveau sur Domus ? Créer un compte',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
