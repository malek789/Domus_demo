part of '../main.dart';

extension _NotificationsActions on _DomusHomeState {
  Future<void> _setLocalNotifications(bool enabled) async {
    // These are device-local alerts; the OS permission is requested only when enabling.
    if (enabled &&
        (kIsWeb ||
            (defaultTargetPlatform != TargetPlatform.android &&
                defaultTargetPlatform != TargetPlatform.iOS))) {
      _showNotice(
        'Les notifications locales sont disponibles sur Android et iOS.',
      );
      return;
    }
    if (mounted) _update(() => _localNotificationsBusy = true);
    try {
      if (enabled) {
        final granted = switch (defaultTargetPlatform) {
          TargetPlatform.android =>
            await _localNotifications
                    .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin
                    >()
                    ?.requestNotificationsPermission() ??
                false,
          TargetPlatform.iOS =>
            await _localNotifications
                    .resolvePlatformSpecificImplementation<
                      IOSFlutterLocalNotificationsPlugin
                    >()
                    ?.requestPermissions(
                      alert: true,
                      badge: true,
                      sound: true,
                    ) ??
                false,
          _ => false,
        };
        if (!granted) {
          _showNotice(
            'Autorisez les notifications dans les réglages de votre appareil.',
          );
          return;
        }
      }
      await _storage.write(
        key: 'domus.localNotifications.enabled',
        value: enabled.toString(),
      );
      if (!mounted) return;
      _update(() => _localNotificationsEnabled = enabled);
      _showNotice(
        enabled
            ? 'Les notifications locales sont activées sur cet appareil.'
            : 'Les notifications locales sont désactivées.',
      );
    } catch (error) {
      if (mounted) {
        _showNotice(
          'Impossible de modifier les notifications locales : $error',
        );
      }
    } finally {
      if (mounted) _update(() => _localNotificationsBusy = false);
    }
  }

  Future<void> _notifyLocally(String title, String body) async {
    if (!_localNotificationsEnabled || kIsWeb) return;
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'domus_local',
          'Domus',
          channelDescription: 'Notifications locales Domus',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
