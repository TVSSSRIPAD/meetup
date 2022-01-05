import 'dart:io';
import 'dart:math';
// import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:meetup/GoogleCalendar.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/src/material/colors.dart' as colorr;

void main() {
  runApp(const MyApp());
}

class MyStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/invite.ics');
  }

  Future<File> writeMyFile(String invite) async {
    // print('here');
    final file = await _localFile;
    // Write the file
    return file.writeAsString(invite);
  }

  Future<String> readMyFile() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();
      // print(contents);
      return contents;
    } catch (e) {
      // If encountering an error, return 0
      return "";
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeetUp',
      theme: ThemeData(
        primarySwatch: colorr.Colors.blue,
      ),
      home: MyHomePage(
          title: 'MeetUp',
          storage: MyStorage(),
          googleCalendar: GoogleCalendar()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {Key? key,
      required this.title,
      required this.storage,
      required this.googleCalendar})
      : super(key: key);

  final String title;
  final MyStorage storage;
  final GoogleCalendar googleCalendar;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  double duration = 25;

  List<String> days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  List<String> mon = [
    "Dec",
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov"
  ];

  String getFormatedDate(DateTime d) {
    return days[d.weekday % 7] +
        ", " +
        mon[d.month % 12] +
        " ${d.day}, ${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2050));
      // print('Picked date is ${picked}');
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
        });
      }
    }

    void _changeDateToToday() {
      setState(() {
        selectedDate = DateTime.now();
      });
    }

    void _changeDateToTomorrow() {
      setState(() {
        selectedDate = DateTime.now().add(const Duration(days: 1));
      });
    }

    Future<void> _selectTime(BuildContext context) async {
      final TimeOfDay? pickedS = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );

      if (pickedS != null && pickedS != selectedTime) {
        setState(() {
          selectedTime = pickedS;
        });
      }
    }

    void _handleShare() async {
      var mypath = await widget.storage._localPath;
      Share.shareFiles([mypath + '/invite.ics'], text: 'Invite Others');
    }

    String getSliderLabel() {
      int dint = duration.toInt();
      if (duration == 60) {
        return "1 Hr";
      } else if (duration > 60) {
        return "1 Hr ${dint - 60} Mins";
      } else {
        return "$dint Mins";
      }
    }

    String getICSFromEvent(Event? event) {
      if (event == null) {
        return "";
      }
      print('event not null');
      String res = '''
      BEGIN:VCALENDAR
      VERSION:2.0
      CALSCALE:GREGORIAN
      PRODID:MEETUP//GMeet Scheduler
      METHOD:PUBLISH 
      BEGIN:VEVENT
      UID:${event.iCalUID}
      SUMMARY:${event.summary}
      DTSTAMP:${DateTime.now()}
      DTSTART:${event.start!.dateTime}
      DTEND:${event.end!.dateTime}
      DESCRIPTION:${event.description}
        ~:::::::::::::::::::::::::::::::::::::::::::~
        Do not edit this section of the description.
        This event has a video call.
        Join: ${event.hangoutLink}
      URL:${event.htmlLink}
      LOCATION:GMeet
      STATUS:CONFIRMED
      ORGANIZER;CN=${event.creator!.displayName}:mailto:${event.creator!.email}
      CREATED:${event.created}
      LAST-MODIFIED:${event.created}
      END:VEVENT
      END:VCALENDAR''';
      return res;
    }

    void _createEvent() async {
      // selectedDate, selectedTime
      DateTime startTime = selectedDate.add(
          Duration(hours: selectedTime.hour, minutes: selectedTime.minute));
      DateTime endTime = startTime.add(Duration(minutes: duration.toInt()));
      Event? event =
          await widget.googleCalendar.scheduleMeet(startTime, endTime);
      print('here');
      print('${event!.hangoutLink} from main');
      String ics = getICSFromEvent(event);
      print(ics);
      await widget.storage.writeMyFile(ics);
      // widget.storage.readMyFile();
    }

    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                height: 20,
              ),
              Text(
                getFormatedDate(selectedDate),
                // "${selectedDate.toLocal()}",
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => {_changeDateToToday()}, // Refer step 3
                    child: const Text('Today'),
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: () => {_changeDateToTomorrow()}, // Refer step 3
                    child: const Text('Tomorrow'),
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: () => _selectDate(context), // Refer step 3
                    child: const Text('Pick a date'),
                  ),
                ],
              ),
              Text(
                // MaterialLocalizations.of(context).formatTimeOfDay(selectedTime),
                selectedTime.format(context),
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () => _selectTime(context),
                child: const Text('Pick Start Time'),
              ),
              Slider.adaptive(
                  value: duration,
                  onChanged: (newDuration) {
                    setState(() => duration = max(5, newDuration));
                  },
                  min: 0,
                  max: 90,
                  divisions: 18,
                  label: getSliderLabel()),
              ElevatedButton(
                child: const Text('Schedule Meet'),
                onPressed: () => _createEvent(),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share Invite'),
                onPressed: () => _handleShare(),
              )
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
