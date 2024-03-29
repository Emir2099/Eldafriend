import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:math';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:medtrack/Medicins/newMed.dart';
import 'package:medtrack/graphs.dart';
import 'package:medtrack/newCard.dart';
import 'package:medtrack/pages/dash.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;
bool showSpinner = false;
Map<String, dynamic> dataOfUser = {};
Map<String, dynamic> dataOfMed = {};
List<Map<String, dynamic>> meds = [];

List<Map<String, dynamic>> medInDate = [];
List<dynamic> timeEvents = [];
Map<String, Color> _Colors = {
    "orange": Color.fromARGB(255, 241, 135, 128),
    "blue": Color.fromARGB(255, 165, 238, 171)
};

class _HomePageState extends State<HomePage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  User? user = _auth.currentUser;
  @override
  void initState() {
    // TODO: implement initState
    getDataOfUser();
    getTheMedicines();
    getTheMedicinesData(); //////////////test
    super.initState();
  }

  void getDataOfUser() async {
    setState(() {
      showSpinner = true;
    });
    print(user?.uid);
    final events =
        await _firestore.collection('users').doc(user?.uid).get();
    if (events != null) {
      print("full name is$events['fullName']");
      dataOfUser['email'] = events['email'];
      dataOfUser['name'] = events['fullName'];
    }
    setState(() {
      showSpinner = false;
    });
  }

  Future<void> getTheMedicines() async {
    setState(() {
      showSpinner = true;
    });

    await FirebaseFirestore.instance
        .collection('medicines')
        .doc(user!.email)
        .collection('dates')
        .doc(DateFormat("dd.MM.yy").format(selectedDay))
        .collection('medicinesList')
        .get()
        .then((querySnapshot) {
      List<Map<String, dynamic>> dataList = [];
      List<String> Events = [];
      Events.add(DateFormat("dd.MM.yy").format(selectedDay));
      querySnapshot.docs.forEach((doc) {
        dataList.add(doc.data());
        Events.add(doc.data()['medTime'].toString());
      });
      dataList.sort((a, b) => a["medTime"].compareTo(b["medTime"]));
      print(dataList);
      print(timeEvents);
      medInDate = dataList;
      timeEvents = Events;

      setState(() {
        showSpinner = false;
      });
    }).catchError((error) {
      print("Error getting documents: $error");
      setState(() {
        showSpinner = false;
      });
    });
  }

  Future<void> getTheMedicinesData() async {
    setState(() {
      showSpinner = true;
    });
    DateTime today = DateTime.now();
    DateTime twoWeeksAfterToday = today.add(Duration(days: 14));
    for (DateTime date = today;
        date.isBefore(twoWeeksAfterToday);
        date = date.add(Duration(days: 1))) {
      await FirebaseFirestore.instance
          .collection('medicines')
          .doc(user!.email)
          .collection('dates')
          .doc(DateFormat("dd.MM.yy").format(selectedDay))
          .collection('medicinesList')
          .get()
          .then((querySnapshot) {
        setState(() {
          meds = [];
          querySnapshot.docs.forEach((element) {
            print(element.data());
            meds.add(element.data());
          });
          showSpinner = false;
        });
      }).catchError((error) {
        print("Error getting documents: $error");
        setState(() {
          showSpinner = false;
        });
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
    appBar: PreferredSize(
  preferredSize: Size.fromHeight(70),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.blue[600],
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: AppBar(
      leading: BackButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => DashPage()),
            (Route<dynamic> route) => false,
          );
        },
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        (dataOfUser['name']).toString(),
        style: TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
          actions: [
            Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(), 
                primary: Colors.white, 
              ),
              onPressed: () async {
                await getTheMedicines();
              },
              child: Icon(Icons.notifications, color: Colors.blue),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(), 
                primary: Colors.white, 
              ),
              onPressed: () {
                Navigator.pushNamed(context, 'history');
              },
              child: Icon(Icons.history, color: Colors.blue),
            ),
          ],
        ),

          ],
          centerTitle: false,
        ),
      ),
    ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SizedBox(
            height: 1000,
            child: Column(
              children: [
                TableCalendar(
                  rowHeight: 40,
                  firstDay: DateTime.utc(2010, 10, 20),
                  lastDay: DateTime.utc(2040, 10, 20),
                  focusedDay: focusedDay,
                  headerVisible: true,
                  daysOfWeekVisible: true,
                  sixWeekMonthsEnforced: true,
                  shouldFillViewport: false,
                  onDaySelected: _onDaySelected,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                          fontSize: 20,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w800)),
                  availableGestures: AvailableGestures.all,
                  calendarStyle: CalendarStyle(
                      todayTextStyle: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  calendarFormat: CalendarFormat.week,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Selected Day, ${selectedDay.day} ${DateFormat.MMM().format(selectedDay)} ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Today, ${focusedDay.day} ${DateFormat.MMM().format(focusedDay)} ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                
                medInDate.length == 0
                    ? noPill(context)
                    : Expanded(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: medInDate.length,
                          itemBuilder: (BuildContext context, int index) {
                            Future<void> isDelete(String isDelete) async {
                              print(isDelete);
                              if (isDelete == 'refresh') {
                                await getTheMedicines();
                              }
                              
                            }

                            Map<String, dynamic> medicineData =
                                medInDate[index];
                                print("this is lengthhhhhhhhh${medInDate.length}");
                            return newCard(selectedDay,
                                dataOfUser, medInDate[index], isDelete);
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(),
                        ),
                      ),
              ],
            )),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async {
          showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => NewMedicine())
              .then((result) async {
            if (result != null && result == 'refresh') {
              // The dialog returned a 'refresh' result, call the function to get the medicines.
              await getTheMedicines();
            }
          });
        },
        child: Icon(
          Icons.add,
          size: 30,
        ),
      ),

    );
  }

  Widget noPill(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              width: MediaQuery.of(context).size.width * 0.99,
              height: MediaQuery.of(context).size.height * 0.47,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/noPill.png'),
                ),
              ),
            ),
          ),
          Column(
            children: const [
              Text(
                'Monitor your med scedule',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'View your daily schedule and mark \n your meds when taken',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime _selectedDay, DateTime focusedDay) async {
    setState(() {
      selectedDay = _selectedDay;
      print("this the dayyy${selectedDay.day}");
    });
    await getTheMedicines();
  }

  void startTimerFromMinute(Function() callback) {
    DateTime now = DateTime.now();
    int secondsUntilNextMinute = 60 -
        now.second; // Calculate the remaining seconds until the next minute
    Timer(Duration(seconds: secondsUntilNextMinute), () {
      // This code will run exactly on the next minute
      callback();
      Timer.periodic(Duration(seconds: 60), (_) {
        // This code will run every 60 seconds, starting from the next minute
        callback();
      });
    });
  }

  void scheduleReminder() {
  DateTime now = DateTime.now();
  print(timeEvents.length);
  if (DateFormat("dd.MM.yy").format(now).toString() == timeEvents[0]) {
    for (int i = 1; i < timeEvents.length; i++) {
      String eventTime = timeEvents[i];
      List<String> timeParts = eventTime.split(':');

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      DateTime eventDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (now.isAfter(eventDateTime) && (i == timeEvents.length - 1 || now.isBefore(DateTime(now.year, now.month, now.day, int.parse(timeEvents[i + 1].split(':')[0]), int.parse(timeEvents[i + 1].split(':')[1]))))) {
        String notificationTitle = "Reminder";
        String notificationBody = "Don't forget the medicines event!";
        DateTime scheduledTime = eventDateTime.add(Duration(seconds: 3));
        print(scheduledTime);
        scheduleNotification(scheduledTime, notificationTitle, notificationBody);
      }
    }
  }
}

  void scheduleNotification(DateTime scheduledTime, String notificationTitle,
      String notificationBody) async {
    try {
      final int notificationId = 0; // Unique ID for the notification
      tz.initializeTimeZones(); // Initialize time zone data
      tz.setLocalLocation(tz.getLocation(
          'India/Kolkata')); 
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'reminder_channel_id',
        'Reminder Channel',
        channelDescription: 'Channel for Reminder Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      tz.TZDateTime scheduledDateTime =
          tz.TZDateTime.from(scheduledTime, tz.local);
      print("Scheduled DateTime: $scheduledDateTime");
      await FlutterLocalNotificationsPlugin().zonedSchedule(
        notificationId,
        notificationTitle,
        notificationBody,
        scheduledDateTime,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print("Notification Scheduled successfully!");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }
}
