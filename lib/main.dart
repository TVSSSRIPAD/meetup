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

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  String meetLink = '';
  String myICSFilePath = '';
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

  @override
  void initState() {
    super.initState();
    widget.storage._localPath
        .then((value) => {myICSFilePath = value + '/invite.ics'});
  }

  String getFormatedDate(DateTime d) {
    return days[d.weekday % 7] +
        ", " +
        mon[d.month % 12] +
        " ${d.day}, ${d.year}";
  }

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

  String formatUTCDateForICS(DateTime? d) {
    if (d == null) return "";
    print("received ${d}");
    print(d.toIso8601String());
    // String formattedDate = d
    //         .toIso8601String()
    //         .substring(0, 19)
    //         .replaceAll('-', '')
    //         .replaceAll(':', '') +
    //     'Z';
    String formattedDate = d.year.toString() +
        d.month.toString().padLeft(2, '0') +
        d.day.toString().padLeft(2, '0');
    String formattedTime = d.hour.toString().padLeft(2, '0') +
        d.minute.toString().padLeft(2, '0') +
        d.second.toString().padLeft(2, '0');
    String formattedDateTime = formattedDate + 'T' + formattedTime + 'Z';
    print('returning $formattedDateTime');
    return formattedDateTime;
  }

  String getICSFromEvent(Event? event) {
    if (event == null) {
      return "";
    }
    print(event.creator);
    print(event.creator!.displayName);
    print('event not null');
    // 20220105T090800Z
    // print(event.start!.dateTime!.hour);

    String res = '''
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:MEETUP//GMeet Scheduler
METHOD:PUBLISH 
BEGIN:VEVENT
UID:${event.iCalUID}
SUMMARY:${event.summary}
DTSTAMP:${formatUTCDateForICS(DateTime.now().toUtc())}
DTSTART:${formatUTCDateForICS(event.start!.dateTime)}
DTEND:${formatUTCDateForICS(event.end!.dateTime)}
DESCRIPTION:${event.description}~:::::::::::::::::::::::::::::::::::::::::::~
 Do not edit this section of the description.
 This event has a video call. Join: ${event.hangoutLink}
URL:${event.hangoutLink}
LOCATION:GMeet
STATUS:CONFIRMED
ORGANIZER;CN=${event.creator!.displayName}:mailto:${event.creator!.email}
CREATED:${formatUTCDateForICS(event.created)}
LAST-MODIFIED:${formatUTCDateForICS(event.created)}
END:VEVENT
END:VCALENDAR''';
    return res;
  }

  void _createEvent() async {
    // selectedDate, selectedTime
    int hour = selectedDate.hour,
        min = selectedDate.minute,
        sec = selectedDate.second;
    DateTime startTime = selectedDate
        .subtract(Duration(hours: hour, minutes: min, seconds: sec));
    startTime = startTime
        .add(Duration(hours: selectedTime.hour, minutes: selectedTime.minute));
    DateTime endTime = startTime.add(Duration(minutes: duration.toInt()));
    print(startTime);
    print(endTime);
    Event event = await widget.googleCalendar.scheduleMeet(startTime, endTime);
    // print('here');
    print('${event.hangoutLink} from main');
    setState(() {
      meetLink = event.hangoutLink!;
    });
    String ics = getICSFromEvent(event);
    print(ics);

    await widget.storage.writeMyFile(ics);

    // widget.storage.readMyFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: GestureDetector(
          onTap: () {/* Write listener code here */},
          child: const Icon(
            Icons.menu, // add custom icons also
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: colorr.Colors.white,
            ),
            onPressed: () {
              // do something
            },
          )
        ],
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
                // formatUTCDateForICS(selectedDate),
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
              const SizedBox(
                height: 10,
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
              const SizedBox(
                height: 10,
              ),
              Text(
                'Duration : ${getSliderLabel()}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              const SizedBox(
                height: 10,
              ),
              getWidget(myICSFilePath, meetLink),
            ],
          ),
        ],
      ),
    );
  }
}

Widget getWidget(String myPath, String meetLink) {
  void _handleShare() async {
    print(myPath);
    await Share.shareFiles([myPath], text: 'Invite Others');
  }

  if (meetLink != null && meetLink != '') {
    return Container(
      child: Column(
        children: [
          Text(
            ' $meetLink',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Share Invite'),
            onPressed: () => _handleShare(),
          )
        ],
      ),
    );
  } else {
    return Container(
      child: Column(
        children: const [
          SizedBox(
            height: 10,
          ),
          Text(
            'Schedule a Meeting to See the details Here!',
            style: TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
