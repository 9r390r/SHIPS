import 'package:flutter/material.dart';

import 'custom_player_introduction.dart';

class GameSetupPage extends StatefulWidget {
  const GameSetupPage({super.key});

  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}

class GameSettings {
  int gameMode; // 0 = not-stated, 1 = PVP, 2 = VS computer
  int computerDifficulty; // 0 = not stated, 1 = easy, 2 = normal, 3 = hard
  double mapsize;
  List<Player> players;

  GameSettings({
    required this.gameMode,
    required this.computerDifficulty,
    required this.mapsize,
    required this.players,
  });
}

GameSettings myCustomGameSettings = GameSettings(
  gameMode: 0,
  computerDifficulty: 0,
  mapsize: 4,
  players: [],
);

class _GameSetupPageState extends State<GameSetupPage> {
  bool ready =
      false; //is the game setup ready to go to the next page? => players introduction
  // int gameMode = 0; // 0 = not-stated, 1 = PVP, 2 = VS computer
  // int computerDifficulty = 0; // 0 = not stated, 1 = easy, 2 = normal, 3 = hard

  void setGameMode(int mode) {
    if (mode == 1) {
      myCustomGameSettings.gameMode = 1;
    } else if (mode == 2) {
      myCustomGameSettings.gameMode = 2;
      if (myCustomGameSettings.computerDifficulty == 0) {
        ready = false;
      }
    }
    setState(() {});
  }

  String getGamemodeLabel() {
    String gamemodeLabel = '';
    if (myCustomGameSettings.gameMode == 0) {
      gamemodeLabel = '';
    } else if (myCustomGameSettings.gameMode == 1) {
      gamemodeLabel = 'Play against your friend.';
    } else if (myCustomGameSettings.gameMode == 2) {
      gamemodeLabel = 'Play against the computer.';
    }
    setState(() {});

    return gamemodeLabel;
  }

  void setDifficulty(String difficuty) {
    if (difficuty == 'easy') {
      myCustomGameSettings.computerDifficulty = 1;
    } else if (difficuty == 'normal') {
      myCustomGameSettings.computerDifficulty = 2;
    } else if (difficuty == 'hard') {
      myCustomGameSettings.computerDifficulty = 3;
    }
    setState(() {});
  }

  String getDifficultyLabel() {
    String difficutyLabel = '';
    if (myCustomGameSettings.computerDifficulty == 0) {
      difficutyLabel = '';
    } else if (myCustomGameSettings.computerDifficulty == 1) {
      difficutyLabel = "Computer's moves are only random.";
      ready = true;
    } else if (myCustomGameSettings.computerDifficulty == 2) {
      difficutyLabel =
          'When found your ship, computer will prioritise destroying it \nbefore continuing to further scan the battlefield.';
      ready = true;
    } else if (myCustomGameSettings.computerDifficulty == 3) {
      difficutyLabel = 'More challenges to be introduced soon...';
      ready = false;
    }
    setState(() {});
    return difficutyLabel;
  }

  String mapSizeLabel = '';

  String getMapSizeLabel() {
    if (myCustomGameSettings.mapsize < 6) {
      mapSizeLabel = 'SMALL';
    } else if (myCustomGameSettings.mapsize < 8) {
      mapSizeLabel = 'MEDIUM';
    } else if (myCustomGameSettings.mapsize < 11) {
      mapSizeLabel = 'LARGE';
    } else {
      mapSizeLabel = 'VERY LARGE';
    }
    setState(() {});

    return (' ') +
        myCustomGameSettings.mapsize.toInt().toString() +
        ('x') +
        myCustomGameSettings.mapsize.toInt().toString() +
        (' ') +
        ('tiles') +
        (' - ') +
        mapSizeLabel;
  }

  String bigMapWarning() {
    String warning = 'This map is really big, it will take time to finish.';
    return warning;
  }

  String getNotReadyErrorMessage() {
    String message = '';
    if (myCustomGameSettings.gameMode == 0) {
      //game mode not set => error
      message = 'Choose game mode.';
      ready = false;
    } else if (myCustomGameSettings.gameMode == 1 &&
        myCustomGameSettings.computerDifficulty == 0) {
      //game mode PVP and computer difficulty not defined => ready
      message =
          'Confirm the map size ${myCustomGameSettings.mapsize.toInt()}x${myCustomGameSettings.mapsize.toInt()} ?';
      ready = true;
    } else if (myCustomGameSettings.gameMode == 2 &&
        myCustomGameSettings.computerDifficulty == 0) {
      // game mode PVC and difficulty not defined => error
      message = 'Choose game difficulty.';
      ready = false;
    } else if ((myCustomGameSettings.gameMode == 1) ||
        (myCustomGameSettings.gameMode == 2 &&
                myCustomGameSettings.computerDifficulty == 1 ||
            myCustomGameSettings.computerDifficulty == 2)) {
      // game mode PVP or game mode PVC with specified difficulty => ready
      message =
          'Confirm the map size ${myCustomGameSettings.mapsize.toInt()}x${myCustomGameSettings.mapsize.toInt()} ?';
      ready = true;
    } else if (myCustomGameSettings.computerDifficulty == 3) {
      message = 'Hard difficulty not available yet. Select other option.';
      ready = false;
    }
    setState(() {});
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Custom Game')),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'GAME MODE',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => setGameMode(1),
                    icon: Icon(Icons.person, color: Colors.white),
                    label: Text('PVP', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(
                          width: 2,
                          color:
                              myCustomGameSettings.gameMode == 1
                                  ? Colors.blue
                                  : Colors.blueGrey,
                        ),
                      ),
                      backgroundColor:
                          myCustomGameSettings.gameMode == 1
                              ? Colors.blue[300]
                              : Colors.blueGrey,
                    ),
                  ),

                  SizedBox(width: 30, height: 1),

                  ElevatedButton.icon(
                    onPressed: () => setGameMode(2),
                    icon: Icon(Icons.smart_toy_outlined, color: Colors.white),
                    label: Text('PVC', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(
                          width: 2,
                          color:
                              myCustomGameSettings.gameMode == 2
                                  ? Colors.blue
                                  : Colors.blueGrey,
                        ),
                      ),
                      backgroundColor:
                          myCustomGameSettings.gameMode == 2
                              ? Colors.blue[300]
                              : Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 0, height: 10),

              Text(getGamemodeLabel()),
              if (myCustomGameSettings.gameMode == 2)
                Column(
                  children: [
                    SizedBox(height: 30),
                    Text(
                      'DIFFICULTY',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        ElevatedButton.icon(
                          onPressed: () => setDifficulty('easy'),
                          icon: Icon(
                            Icons.star_outline_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            'easy',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: BorderSide(
                                width: 2,
                                color:
                                    myCustomGameSettings.computerDifficulty == 1
                                        ? Colors.blue
                                        : Colors.blueGrey,
                              ),
                            ),
                            backgroundColor:
                                myCustomGameSettings.computerDifficulty == 1
                                    ? Colors.blue[300]
                                    : Colors.blueGrey,
                          ),
                        ),
                        SizedBox(width: 20, height: 1),
                        ElevatedButton.icon(
                          onPressed: () => setDifficulty('normal'),
                          icon: Icon(
                            Icons.star_half_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            'normal',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: BorderSide(
                                width: 2,
                                color:
                                    myCustomGameSettings.computerDifficulty == 2
                                        ? Colors.blue
                                        : Colors.blueGrey,
                              ),
                            ),
                            backgroundColor:
                                myCustomGameSettings.computerDifficulty == 2
                                    ? Colors.blue[300]
                                    : Colors.blueGrey,
                          ),
                        ),
                        SizedBox(width: 20, height: 1),
                        ElevatedButton.icon(
                          onPressed: () => setDifficulty('hard'),
                          icon: Icon(Icons.star_rounded, color: Colors.white),
                          label: Text(
                            'hard',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: BorderSide(
                                width: 2,
                                color:
                                    myCustomGameSettings.computerDifficulty == 3
                                        ? Colors.red
                                        : Colors.blueGrey,
                              ),
                            ),
                            backgroundColor:
                                myCustomGameSettings.computerDifficulty == 3
                                    ? Colors.red[300]
                                    : Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 0, height: 10),

                    Text(getDifficultyLabel(), textAlign: TextAlign.center),
                  ],
                ),

              SizedBox(width: 1, height: 30),
              Text(
                'MAP SIZE',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 1, height: 1),
              Slider(
                value: myCustomGameSettings.mapsize,
                min: 4,
                max: 16,
                divisions: 12,
                label:
                    myCustomGameSettings.mapsize.toInt().toString() +
                    ('x') +
                    myCustomGameSettings.mapsize.toInt().toString(),
                thumbColor: Colors.blue,
                onChanged: (double value) {
                  setState(() {
                    myCustomGameSettings.mapsize = value;
                    if (myCustomGameSettings.gameMode == 1) {
                      ready = true;
                      print('Slider changed — ready = $ready');
                    }
                  });
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Selected map '),
                  Icon(Icons.map_outlined, color: Colors.blueGrey),
                  SizedBox(width: 0),
                  Text(getMapSizeLabel()),
                ],
              ),
            ],
          ),
          SizedBox(width: 1, height: 80),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: ready ? Colors.white : Colors.blueGrey[200],
                ),
                label: Text(
                  ready ? 'confirm' : 'continue',
                  style: TextStyle(
                    color: ready ? Colors.white : Colors.blueGrey[200],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: ready ? 3 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                      width: 2,
                      color: ready ? Colors.green[500]! : Colors.blueGrey[100]!,
                    ),
                  ),
                  backgroundColor:
                      ready ? Colors.green[300] : Colors.blueGrey[100],
                ),
                onPressed: () {
                  if (ready) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          Player currentPlayer = Player(
                            name: '',
                            avatar: Avatar(
                              Icons.question_mark_rounded,
                              Colors.grey,
                            ),
                            fraction: null,
                            shipTypes: [],
                            ships: [],
                            playerID: generatePlayerID(),
                            isReady: false,
                            totalHealth: 0,
                          );
                          myCustomGameSettings.players.add(currentPlayer);
                          print(
                            'players in my custom game: ${myCustomGameSettings.players}',
                          );
                          return CustomPlayerIntroduction(
                            currentPlayer: currentPlayer,
                            settings: myCustomGameSettings,
                          );
                        },
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(getNotReadyErrorMessage()),
                        behavior:
                            SnackBarBehavior
                                .floating, // Makes it float, not pinned
                        margin: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 80, // Push it up near a button
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
