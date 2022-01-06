import 'dart:io';
import 'dart:math';
// import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:meetup/google_calendar.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/src/material/colors.dart' as colorr;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
        primarySwatch: colorr.Colors.teal,
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
  DateTime lastDate = DateTime.now();
  TimeOfDay lastTime = TimeOfDay.now();
  bool isLoading = false;
  // bool isSignedIn = false;

  int lastSelectedButton = 1;
  double duration = 25;
  double lastDuration = 25;
  String meetLink = '';
  String myICSFilePath = '';
  String error = '';

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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown
    ]);
    super.dispose();
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

    if (picked != null) {
      int diff = picked.difference(DateTime.now()).inHours;
      print(diff);
      int newButton;
      if (diff <= 0) {
        newButton = 1;
      } else if (diff <= 24) {
        newButton = 2;
      } else {
        newButton = 3;
      }
      setState(() {
        lastSelectedButton = newButton;
      });
      if (picked != selectedDate) {
        setState(() {
          selectedDate = picked;
        });
      }
    }
  }

  void _changeDateToToday() {
    setState(() {
      selectedDate = DateTime.now();
      lastSelectedButton = 1;
    });
  }

  void _changeDateToTomorrow() {
    setState(() {
      selectedDate = DateTime.now().add(const Duration(days: 1));
      lastSelectedButton = 2;
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

  String getSliderLabel(double duration) {
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
DESCRIPTION: This event has a video call. Join: ${event.hangoutLink}
URL:${event.hangoutLink}
LOCATION:GMeet
STATUS:CONFIRMED
ORGANIZER;CN=${event.creator!.displayName}:MAILTO:${event.creator!.email}
CREATED:${formatUTCDateForICS(event.created)}
LAST-MODIFIED:${formatUTCDateForICS(event.created)}
END:VEVENT
END:VCALENDAR''';
    return res;
  }

  void _createEvent() async {
    setState(() {
      isLoading = true;
    });
    // selectedDate, selectedTime
    int hour = selectedDate.hour,
        min = selectedDate.minute,
        sec = selectedDate.second;
    DateTime startTime = selectedDate
        .subtract(Duration(hours: hour, minutes: min, seconds: sec));
    startTime = startTime
        .add(Duration(hours: selectedTime.hour, minutes: selectedTime.minute));
    try {
      DateTime endTime = startTime.add(Duration(minutes: duration.toInt()));
      print(startTime);
      print(endTime);
      Event event =
          await widget.googleCalendar.scheduleMeet(startTime, endTime);
      // print('here');
      print('${event.hangoutLink} from main');

      setState(() {
        meetLink = event.hangoutLink!;
        lastDate = selectedDate;
        lastTime = selectedTime;
        lastDuration = duration;
      });

      String ics = getICSFromEvent(event);
      print(ics);

      await widget.storage.writeMyFile(ics);
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
    setState(() {
      isLoading = false;
    });
    // widget.storage.readMyFile();
  }

  Widget getMeetInfoWidget(BuildContext context) {
    void _handleShare() async {
      print(myICSFilePath);
      await Share.shareFiles([myICSFilePath], text: 'Invite Others');
    }

    if (meetLink != null && meetLink != '') {
      return Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 15),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
          color: Color(0xff9DF3C4),
        ),
        child: Column(
          children: [
            const Text(
              'Last Scheduled Meeting:\n ',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            Text(
              getFormatedDate(lastDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              lastTime.format(context) + '  |  ' + getSliderLabel(lastDuration),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              meetLink,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('GMeet Link'),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: meetLink),
                    );
                    final snackBar = SnackBar(
                      content: const Text('Copied'),
                      action: SnackBarAction(
                        label: '',
                        onPressed: () {},
                      ),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                ),
                const SizedBox(
                  width: 5,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share ICS'),
                  onPressed: () => _handleShare(),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        // width: ,
        margin: const EdgeInsets.fromLTRB(0, 25, 0, 0),
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
          color: Color(0xff9DF3C4),
        ),
        child: Column(
          children: const [
            SizedBox(
              height: 10,
            ),
            Text(
              'Schedule a meeting to see details here',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
  }

  Widget _getFAB() {
    print(widget.googleCalendar.auth.signInStatus);
    if (widget.googleCalendar.auth.signInStatus == 'true') {
      return FloatingActionButton(
        onPressed: () {
          final snackBar = SnackBar(
            content: const Text('Tap on Yes to SignOut'),
            action: SnackBarAction(
              label: 'Yes',
              onPressed: () {
                widget.googleCalendar.signOut();
                setState(() {
                  isLoading = false;
                });
              },
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        child: const Icon(Icons.login_rounded),
      );
    } else {
      return Container();
    }
  }

  ButtonStyle getButtonStyle(int buttonId) {
    ButtonStyle b = ButtonStyle(
      elevation: MaterialStateProperty.all(0),
      backgroundColor: MaterialStateProperty.all(colorr.Colors.white38),
      foregroundColor: MaterialStateProperty.all(colorr.Colors.teal),
      animationDuration: const Duration(milliseconds: 100),
      side: MaterialStateProperty.all(
        const BorderSide(color: colorr.Colors.teal, width: 1),
      ),
    );
    const bb = ButtonStyle();
    if (lastSelectedButton == buttonId) {
      return bb;
    } else {
      return b;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              child: const Icon(Icons.info_outline),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'MeetUp',
                  applicationVersion: 'Alpha Release',
                  // applicationIcon: Icon(),
                  children: <Widget>[
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'This app is developed by ',
                            style: TextStyle(
                                color: colorr.Colors.black, fontSize: 20),
                          ),
                          TextSpan(
                            text: 'T.V.S.S.Sripad',
                            style: const TextStyle(
                                color: colorr.Colors.blue, fontSize: 20),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch('https://github.com/TVSSSRIPAD');
                              },
                          ),
                          const TextSpan(
                            text: ' and ',
                            style: TextStyle(
                                color: colorr.Colors.black, fontSize: 20),
                          ),
                          TextSpan(
                            text: 'K.Kishorereddy. ',
                            style: const TextStyle(
                                color: colorr.Colors.blue, fontSize: 20),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch(
                                    'https://github.com/kancherlakishorereddy');
                              },
                          ),
                          const TextSpan(
                            text: ' \n\nAll CopyRights Reserved 2022 \u00a9',
                            style: TextStyle(
                                color: colorr.Colors.black, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(
                height: 25,
              ),
              Text(
                getFormatedDate(selectedDate),
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => {_changeDateToToday()}, // Refer step 3
                    child: const Text('Today'),
                    style: getButtonStyle(1),
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: () => {_changeDateToTomorrow()}, // Refer step 3
                    child: const Text('Tomorrow'),
                    style: getButtonStyle(2),
                  ),
                  const SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: () => _selectDate(context), // Refer step 3
                    child: const Text('Pick a date'),
                    style: getButtonStyle(3),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
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
                height: 20,
              ),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Duration: ',
                      style: TextStyle(
                        fontSize: 25,
                        color: colorr.Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: getSliderLabel(duration),
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: colorr.Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Slider.adaptive(
                value: duration,
                onChanged: (newDuration) {
                  setState(() => duration = max(5, newDuration));
                },
                min: 0,
                max: 60,
                divisions: 12,
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  child: Text(isLoading ? "Scheduling..." : 'Schedule Meeting'),
                  onPressed: () {
                    if (isLoading) {
                      final snackBar = SnackBar(
                        content:
                            const Text('Wait for scheduling to complete...'),
                        action: SnackBarAction(
                          label: 'Ok',
                          onPressed: () {},
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    } else if (error != '') {
                      final snackBar = SnackBar(
                        content: Text(error),
                        action: SnackBarAction(
                          label: 'Ok',
                          onPressed: () {
                            setState(() {
                              error = '';
                            });
                          },
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    } else if (selectedDate != lastDate ||
                        selectedTime != lastTime ||
                        duration != lastDuration) {
                      _createEvent();
                    } else if (widget.googleCalendar.auth.signInStatus ==
                        'true') {
                      final snackBar = SnackBar(
                        content: const Text(
                            'You have already scheduled a meeting with those options.'),
                        action: SnackBarAction(
                          label: 'Ok',
                          onPressed: () {},
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    } else {
                      _createEvent();
                    }
                  }),
              const SizedBox(
                height: 25,
              ),
              getMeetInfoWidget(context),
              const SizedBox(
                height: 25,
              ),
              // error != '' ? Text(error) : Container()
            ],
          ),
        ],
      ),
      floatingActionButton: _getFAB(),
    );
  }
}
