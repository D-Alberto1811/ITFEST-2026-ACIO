/// Configurare API backend – toată autentificarea se face pe server.
const String apiBaseUrl = 'http://194.102.62.209:8999';

/// Web OAuth Client ID – OBLIGATORIU pe Android pentru id_token.
/// Pe Android, serverClientId trebuie să fie Web client, NU Android client.
///
/// Pași:
/// 1. Google Cloud Console → APIs & Services → Credentials
/// 2. Create Credentials → OAuth client ID → Application type: Web application
/// 3. Copiază Client ID (ex: 209952261016-xxx.apps.googleusercontent.com)
/// 4. Pune aici ȘI în backend .env: GOOGLE_CLIENT_ID=... (include și Web client)
const String? googleServerClientId = '209952261016-mn4ckiecftq0vnsj5nv5lrd60jp2vsd7.apps.googleusercontent.com';
