import 'package:flutter/material.dart';
import 'custom_game_settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHIPS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'SHIPS'),
      routes: {'/game_setup': (context) => GameSetupPage()},
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[500]!,

        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white, fontSize: 50),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 250, left: 50, right: 50),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => print('TODO: implement campain'),
                icon: Icon(Icons.auto_stories_sharp, color: Colors.white),
                label: Text(
                  '    Campaign   ',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(width: 2, color: Colors.blueGrey),
                  ),
                  backgroundColor: Colors.blueGrey,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/game_setup');
                },
                icon: Icon(Icons.play_circle_rounded, color: Colors.white),
                label: Text(
                  'Custom Game',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(width: 2, color: Colors.blueGrey),
                  ),
                  backgroundColor: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
