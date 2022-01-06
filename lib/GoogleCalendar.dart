import 'dart:developer';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/people/v1.dart' as People;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class GoogleCalendar {
  static const _scopes = [
    CalendarApi.calendarScope,
    People.PeopleServiceApi.userinfoProfileScope
  ];
  ClientId? _credentials;
  final storage = const FlutterSecureStorage();

  Future<Event> scheduleMeet(DateTime startTime, DateTime endTime) async {
    log('scheduleMeet is called');

    if (Platform.isAndroid) {
      _credentials = ClientId(
          "753116283299-6ha4kn8jtgh0sq39vevkdkpomo78ihia.apps.googleusercontent.com",
          "");
    } else if (Platform.isIOS) {
      _credentials = ClientId("secure-key");
    }

    Event event = Event(); // Create object of event
    event.summary = "GMeet by MeetUp"; //Setting summary of object

    EventDateTime start = EventDateTime(); //Setting start time
    start.dateTime = startTime;
    start.timeZone = "GMT+05:30";
    event.start = start;

    EventDateTime end = EventDateTime(); //setting end time
    end.timeZone = "GMT+05:30";
    end.dateTime = endTime;
    event.end = end;
    event.conferenceData = ConferenceData(
        createRequest: CreateConferenceRequest(
            requestId: "zzz",
            conferenceSolutionKey:
                ConferenceSolutionKey(type: "hangoutsMeet")));
    event.description = "Default MeetUp description";
    event.attendeesOmitted = true;
    Event eve = await insertEvent(event);
    //.then((eve) {
    //   print('hh');
    print(eve);
    return eve;
    // }
    // );
  }

  Future<Event> insertEvent(event) async {
    log('insertEvent called');
    // Read value
    String? type = await storage.read(key: "accessTokenType");
    String? data = await storage.read(key: "accessTokenData");
    String? expiry = await storage.read(key: "accessTokenExpiry");
    String? refresh = await storage.read(key: "refreshToken");
    AuthClient client;
    print(data);
    print(expiry);
    if (type != null) {
      print('type not null');
      AccessCredentials _newCredentials = AccessCredentials(
          AccessToken(type, data!, DateTime.parse(expiry!)), refresh, _scopes);

      var _newClient = http.Client();
      AccessCredentials _accessCredentials =
          await refreshCredentials(_credentials!, _newCredentials, _newClient);
      client = authenticatedClient(_newClient, _accessCredentials);
      try {
        // client = await clientViaUserConsent(_credentials!, _scopes, prompt);

        // .then((AuthClient client) {
        var calendar = CalendarApi(client);
        await storage.write(
            key: "accessTokenType", value: client.credentials.accessToken.type);
        await storage.write(
            key: "accessTokenData", value: client.credentials.accessToken.data);
        await storage.write(
            key: "accessTokenExpiry",
            value: client.credentials.accessToken.expiry.toString());
        await storage.write(key: "idToken", value: client.credentials.idToken);
        await storage.write(
            key: "refreshToken", value: client.credentials.refreshToken);
        String calendarId = "primary";
        print('ss');
        People.Person details = await People.PeopleServiceApi(client)
            .people
            .get("me", personFields: "person.names");
        // // details.people.get("me",personFields: "person.names");
        // print(details.names);
        Event eve = await calendar.events
            .insert(event, calendarId, conferenceDataVersion: 1);
        print(eve.status);
        print(eve.hangoutLink);
        return eve;
      } catch (e) {
        throw ('Error creating event $e');
      }
    } else {
      try {
        print(_credentials);
        client = await clientViaUserConsent(_credentials!, _scopes, prompt);

        // .then((AuthClient client) {
        var calendar = CalendarApi(client);
        await storage.write(
            key: "accessTokenType", value: client.credentials.accessToken.type);
        await storage.write(
            key: "accessTokenData", value: client.credentials.accessToken.data);
        await storage.write(
            key: "accessTokenExpiry",
            value: client.credentials.accessToken.expiry.toString());
        await storage.write(key: "idToken", value: client.credentials.idToken);
        await storage.write(
            key: "refreshToken", value: client.credentials.refreshToken);
        String calendarId = "primary";

        // People.Person details = await People.PeopleServiceApi(client)
        //     .people
        //     .get("me", personFields: "person.names");
        // // details.people.get("me",personFields: "person.names");
        // print(details.names);
        Event eve = await calendar.events
            .insert(event, calendarId, conferenceDataVersion: 1);
        print(eve.status);
        print(eve.hangoutLink);
        return eve;
      } catch (e) {
        throw ('Error creating event $e');
      }
    }
  }

  void prompt(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
