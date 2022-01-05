import 'dart:developer';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleCalendar {
  static const _scopes = [CalendarApi.calendarScope];
  var _credentials;

  void scheduleMeet(DateTime startTime, DateTime endTime) {
    if (Platform.isAndroid) {
      _credentials = ClientId(
          "753116283299-6ha4kn8jtgh0sq39vevkdkpomo78ihia.apps.googleusercontent.com");
    } else if (Platform.isIOS) {
      _credentials = ClientId("secure-key");
    }

    Event event = Event(); // Create object of event
    event.summary = "GMeet by MeetUp"; //Setting summary of object

    EventDateTime start = EventDateTime(); //Setting start time
    start.dateTime = startTime;
    start.timeZone = "GMT+05:00";
    event.start = start;

    EventDateTime end = EventDateTime(); //setting end time
    end.timeZone = "GMT+05:00";
    end.dateTime = endTime;
    event.end = end;

    event.conferenceData = 1 as ConferenceData?;
    event.description = "Default MeetUp description";
  }

  void insertEvent(event) {
    try {
      clientViaUserConsent(_credentials, _scopes, prompt)
          .then((AuthClient client) {
        var calendar = CalendarApi(client);
        String calendarId = "primary";
        calendar.events.insert(event, calendarId).then((value) {
          print("ADDEDDD_________________${value.status}");
          if (value.status == "confirmed") {
            log('Event added in google calendar');
            log(value.toString());
          } else {
            log("Unable to add event in google calendar");
          }
        });
      });
    } catch (e) {
      log('Error creating event $e');
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
