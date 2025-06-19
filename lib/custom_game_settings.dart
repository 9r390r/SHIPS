import 'package:flutter/material.dart';

import 'custom_player_introduction.dart';

class GameSetupPage extends StatefulWidget {
  const GameSetupPage({super.key});

  @override
  State<GameSetupPage> createState() => _GameSetupPageState();
}

enum GameMode { notSet, pvp, computer }

enum ComputerDifficulty { notSet, easy, normal, hard }

class GameSettings {
  GameMode gameMode;
  ComputerDifficulty computerDifficulty;
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
  gameMode: GameMode.notSet,
  computerDifficulty: ComputerDifficulty.notSet,
  mapsize: 4,
  players: [],
);

class _GameSetupPageState extends State<GameSetupPage> {
  bool ready =
      false; //is the game setup ready to go to the next page? => players introduction

  void setGameMode(GameMode gameMode) {
    if (gameMode == GameMode.pvp) {
      myCustomGameSettings.gameMode = GameMode.pvp;
    } else if (gameMode == GameMode.computer) {
      myCustomGameSettings.gameMode = GameMode.computer;
      if (myCustomGameSettings.computerDifficulty ==
          ComputerDifficulty.notSet) {
        ready = false;
      }
    }
    setState(() {});
  }

  String getGamemodeLabel() {
    String gamemodeLabel = '';
    if (myCustomGameSettings.gameMode == GameMode.notSet) {
      gamemodeLabel = '';
    } else if (myCustomGameSettings.gameMode == GameMode.pvp) {
      gamemodeLabel = 'Play against your friend.';
    } else if (myCustomGameSettings.gameMode == GameMode.computer) {
      gamemodeLabel = 'Play against the computer.';
    }
    setState(() {});

    return gamemodeLabel;
  }

  // void setDifficulty(String difficuty) {
  //   if (difficuty == 'easy') {
  //     myCustomGameSettings.computerDifficulty = ComputerDifficulty.easy;
  //   } else if (difficuty == 'normal') {
  //     myCustomGameSettings.computerDifficulty = ComputerDifficulty.normal;
  //   } else if (difficuty == 'hard') {
  //     myCustomGameSettings.computerDifficulty = ComputerDifficulty.hard;
  //   }
  //   setState(() {});
  // }

  String getDifficultyLabel() {
    String difficutyLabel = '';
    if (myCustomGameSettings.computerDifficulty == ComputerDifficulty.notSet) {
      difficutyLabel = '';
    } else if (myCustomGameSettings.computerDifficulty ==
        ComputerDifficulty.easy) {
      difficutyLabel = "Computer's moves are only random.";
      ready = true;
    } else if (myCustomGameSettings.computerDifficulty ==
        ComputerDifficulty.normal) {
      difficutyLabel =
          'When found your ship, computer will prioritise destroying it \nbefore continuing to further scan the battlefield.';
      ready = true;
    } else if (myCustomGameSettings.computerDifficulty ==
        ComputerDifficulty.hard) {
      difficutyLabel = 'More challenges to be introduced soon...';
      ready = false;
    }
    setState(() {});
    return difficutyLabel;
  }

  String mapSizeLabel = '';

  String getMapSizeLabel() {
    if (myCustomGameSettings.mapsize < 5) {
      mapSizeLabel = 'SMALL';
    } else if (myCustomGameSettings.mapsize < 7) {
      mapSizeLabel = 'MEDIUM';
    } else if (myCustomGameSettings.mapsize < 10) {
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
    if (myCustomGameSettings.gameMode == GameMode.notSet) {
      //game mode not set => error
      message = 'Choose game mode.';
      ready = false;
    } else if (myCustomGameSettings.gameMode == GameMode.pvp &&
        myCustomGameSettings.computerDifficulty == ComputerDifficulty.notSet) {
      //game mode PVP and computer difficulty not defined => ready
      message =
          'Confirm the map size ${myCustomGameSettings.mapsize.toInt()}x${myCustomGameSettings.mapsize.toInt()} ?';
      ready = true;
    } else if (myCustomGameSettings.gameMode == GameMode.computer &&
        myCustomGameSettings.computerDifficulty == ComputerDifficulty.notSet) {
      // game mode PVC and difficulty not defined => error
      message = 'Choose game difficulty.';
      ready = false;
    } else if ((myCustomGameSettings.gameMode == GameMode.pvp) ||
        (myCustomGameSettings.gameMode == GameMode.computer &&
                myCustomGameSettings.computerDifficulty ==
                    ComputerDifficulty.easy ||
            myCustomGameSettings.computerDifficulty ==
                ComputerDifficulty.normal)) {
      // game mode PVP or game mode PVC with specified difficulty => ready
      message =
          'Confirm the map size ${myCustomGameSettings.mapsize.toInt()}x${myCustomGameSettings.mapsize.toInt()} ?';
      ready = true;
    } else if (myCustomGameSettings.computerDifficulty ==
        ComputerDifficulty.hard) {
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
                    onPressed: () => setGameMode(GameMode.pvp),
                    icon: Icon(Icons.person, color: Colors.white),
                    label: Text('PVP', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(
                          width: 2,
                          color:
                              myCustomGameSettings.gameMode == GameMode.pvp
                                  ? Colors.blue
                                  : Colors.blueGrey,
                        ),
                      ),
                      backgroundColor:
                          myCustomGameSettings.gameMode == GameMode.pvp
                              ? Colors.blue[300]
                              : Colors.blueGrey,
                    ),
                  ),

                  SizedBox(width: 30, height: 1),

                  ElevatedButton.icon(
                    onPressed: () => setGameMode(GameMode.computer),
                    icon: Icon(Icons.smart_toy_outlined, color: Colors.white),
                    label: Text('PVC', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(
                          width: 2,
                          color:
                              myCustomGameSettings.gameMode == GameMode.computer
                                  ? Colors.blue
                                  : Colors.blueGrey,
                        ),
                      ),
                      backgroundColor:
                          myCustomGameSettings.gameMode == GameMode.computer
                              ? Colors.blue[300]
                              : Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 0, height: 10),

              Text(getGamemodeLabel()),
              if (myCustomGameSettings.gameMode == GameMode.computer)
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
                          onPressed:
                              () =>
                                  myCustomGameSettings.computerDifficulty =
                                      ComputerDifficulty.easy,
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
                                    myCustomGameSettings.computerDifficulty ==
                                            ComputerDifficulty.easy
                                        ? Colors.blue
                                        : Colors.blueGrey,
                              ),
                            ),
                            backgroundColor:
                                myCustomGameSettings.computerDifficulty ==
                                        ComputerDifficulty.easy
                                    ? Colors.blue[300]
                                    : Colors.blueGrey,
                          ),
                        ),
                        SizedBox(width: 20, height: 1),
                        ElevatedButton.icon(
                          onPressed:
                              () =>
                                  myCustomGameSettings.computerDifficulty =
                                      ComputerDifficulty.normal,
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
                                    myCustomGameSettings.computerDifficulty ==
                                            ComputerDifficulty.normal
                                        ? Colors.blue
                                        : Colors.blueGrey,
                              ),
                            ),
                            backgroundColor:
                                myCustomGameSettings.computerDifficulty ==
                                        ComputerDifficulty.normal
                                    ? Colors.blue[300]
                                    : Colors.blueGrey,
                          ),
                        ),
                        SizedBox(width: 20, height: 1),
                        ElevatedButton.icon(
                          onPressed:
                              () =>
                                  myCustomGameSettings.computerDifficulty =
                                      ComputerDifficulty.hard,
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
                                    myCustomGameSettings.computerDifficulty ==
                                            ComputerDifficulty.hard
                                        ? Colors.red
                                        : Colors.blueGrey,
                              ),
                            ),
                            backgroundColor:
                                myCustomGameSettings.computerDifficulty ==
                                        ComputerDifficulty.hard
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
                    if (myCustomGameSettings.gameMode == GameMode.pvp) {
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
                          if (myCustomGameSettings.gameMode ==
                              GameMode.computer) {
                            Fraction chosenRandomFraction = randomFraction();
                            int computerID = generatePlayerID();
                            Player computerPlayer = Player(
                              playerName: generateComputerName(),
                              avatar: Avatar(
                                Icons.smart_toy_outlined,
                                getComputerAvatarRandomColor(),
                              ),
                              fraction: chosenRandomFraction,
                              shipTypes: calculateShipTypesLineupForPLayer(
                                mapsize: myCustomGameSettings.mapsize,
                                fraction: chosenRandomFraction,
                                playerID: computerID,
                              ),
                              ships: [],
                              playerID: computerID,
                              isReady: false,
                              totalHealth: 0,
                            );
                            return CustomPlayerIntroduction(
                              currentPlayer: computerPlayer,
                              settings: myCustomGameSettings,
                            );
                          } else {
                            Player currentPlayer = Player(
                              playerName: '',
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
                          }
                        },
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(getNotReadyErrorMessage()),
                        behavior:
                            SnackBarBehavior
                                .floating, // SnackBarBehavior float, not pinned
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
