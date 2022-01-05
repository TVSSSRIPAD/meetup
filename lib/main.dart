import 'dart:io';
// import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    print('here');
    final file = await _localFile;
    // Write the file
    return file.writeAsString(invite);
  }

  Future<String> readMyFile() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();
      print(contents);
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
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'MeetUp', storage: MyStorage()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.storage})
      : super(key: key);

  final String title;
  final MyStorage storage;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  String ics = '''BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:MEETUP//GMeet Scheduler
METHOD:PUBLISH
X-PUBLISHED-TTL:PT1H
BEGIN:VEVENT
UID:2pjn5opt7buus9q2kmc1h9c99k@google.com
SUMMARY:Summary
DTSTAMP:20220105T090800Z
DTSTART:20220105T090800Z
DTEND:20220105T093300Z
DESCRIPTION:Lorem ipsum dolor sit amet consectetur adipisicing elit. Veniam, alias?drfs 
  Do not edit this section of the description. This event has a video call.
  Join at https://meet.google.com/nnk-unhb-kug
URL:https://meet.google.com/nnk-unhb-kug
LOCATION:GMeet
STATUS:CONFIRMED
ORGANIZER;CN=Kishorereddy Kancherla:mailto:kishorereddykancherla@gmail.com
CREATED:20220105T090800Z
LAST-MODIFIED:20220105T090800Z
END:VEVENT
END:VCALENDAR''';

  List<String> days = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"];
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

    void handleShare() async {
      await widget.storage.writeMyFile(ics);
      widget.storage.readMyFile();
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
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share Invite'),
                onPressed: () => handleShare(),
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
