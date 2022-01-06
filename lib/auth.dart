import 'dart:developer';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/people/v1.dart' as People;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class Auth {
  static const _scopes = [
    CalendarApi.calendarScope,
    People.PeopleServiceApi.userinfoProfileScope
  ];
  ClientId? _clientId;
  final storage = const FlutterSecureStorage();
  final _newClient = http.Client();

  Auth() {
    if (Platform.isAndroid) {
      _clientId = ClientId(
          "753116283299-6ha4kn8jtgh0sq39vevkdkpomo78ihia.apps.googleusercontent.com",
          "");
    } else if (Platform.isIOS) {
      _clientId = ClientId("secure-key", "");
    }
  }

  Future<String?> getLatestUserName(AuthClient client) async {
    People.Person person = await People.PeopleServiceApi(client)
        .people
        .get("people/me", personFields: "names");
    print(person.names![0].displayName);
    // print(person.names![0].toString());
    // print(person.names![0].displayNameLastFirst);
    List<People.Name>? list = person.names;

    return list![0].displayName;
  }

  Future<String?> getUserNameFromStorage() async {
    return await storage.read(key: "userName");
  }

  void writeUserNameToStorage(String? userName) async {
    await storage.write(key: "userName", value: userName);
  }

  Future<AccessCredentials> getMyAccessCredentialsFromStorage() async {
    String? type = await storage.read(key: "accessTokenType");
    String? data = await storage.read(key: "accessTokenData");
    String? expiry = await storage.read(key: "accessTokenExpiry");
    String? refresh = await storage.read(key: "refreshToken");
    return AccessCredentials(
        AccessToken(type!, data!, DateTime.parse(expiry!)), refresh, _scopes);
  }

  void writeMyCredentials(AccessCredentials credentials) async {
    await storage.write(
        key: "accessTokenType", value: credentials.accessToken.type);
    await storage.write(
        key: "accessTokenData", value: credentials.accessToken.data);
    await storage.write(
        key: "accessTokenExpiry",
        value: credentials.accessToken.expiry.toString());
    await storage.write(key: "idToken", value: credentials.idToken);
    await storage.write(key: "refreshToken", value: credentials.refreshToken);

    await storage.write(key: "tokensExist", value: 'true');
  }

  Future<AuthClient> getClient() async {
    String? tokensExist = await storage.read(key: "tokensExist");
    if (tokensExist != null && tokensExist == 'true') {
      // print('type not null');
      AccessCredentials _credentials =
          await getMyAccessCredentialsFromStorage();

      if (_credentials.accessToken.hasExpired) {
        _credentials =
            await refreshCredentials(_clientId!, _credentials, _newClient);
        writeMyCredentials(_credentials);
      }

      return authenticatedClient(_newClient, _credentials);
    } else {
      AuthClient temp = await clientViaUserConsent(_clientId!, _scopes, prompt);
      String? userName = await getLatestUserName(temp);
      writeMyCredentials(temp.credentials);
      writeUserNameToStorage(userName);
      return temp;
    }
  }

  void signOut() async {
// Delete all
    await storage.deleteAll();
  }

  void prompt(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
