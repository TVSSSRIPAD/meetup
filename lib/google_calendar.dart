import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:meetup/auth.dart';

class GoogleCalendar {
  Auth auth = Auth();

  Future<Event> scheduleMeet(DateTime startTime, DateTime endTime) async {
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
    event.description = "";
    event.attendeesOmitted = true;
    Event insertedEvent = await insertEvent(event);
    print(insertedEvent);
    return insertedEvent;
  }

  Future<Event> insertEvent(Event event) async {
    AuthClient client = await auth.getClient();

    var calendar = CalendarApi(client);
    String calendarId = "primary";

    Event insertedEvent = await calendar.events
        .insert(event, calendarId, conferenceDataVersion: 1);
    print(insertedEvent.status);
    print(insertedEvent.hangoutLink);
    insertedEvent.creator!.displayName = await auth.getUserNameFromStorage();
    print(insertedEvent.creator!.displayName);
    return insertedEvent;
  }

  void signOut() {
    auth.signOut();
  }
}
