import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'player_deploy_page.dart';
import 'custom_game_settings.dart';
import 'main.dart';

class CustomPlayerIntroduction extends StatefulWidget {
  final GameSettings settings;
  final Player currentPlayer;

  const CustomPlayerIntroduction({
    super.key,
    required this.currentPlayer,
    required this.settings,
  });
  @override
  State<CustomPlayerIntroduction> createState() {
    return _CustomPlayerIntroduction();
  }
}

bool _exitRequested = false;
List<Player> players = [];
int idbase = 1;
// String? selectedFraction;

bool isFraction = false;
bool isName = false;
bool isAvatarIcon = false;
bool isAvatarBackground = false;

bool get canContinue {
  return isName && isFraction && isAvatarIcon && isAvatarBackground;
}

class Avatar {
  // storing avatar configuration made in this page
  IconData icon = Icons.question_mark_rounded;
  Color background = Colors.grey;

  Avatar(this.icon, this.background);

  void setAvatarIcon(IconData selectedIcon) {
    icon = selectedIcon;
  }

  void setAvatarColor(Color selectedColor) {
    background = selectedColor;
  }
}

// Avatar playerUneditedAvatar = Avatar(Icons.question_mark_rounded, Colors.grey);
// Avatar computerAvatar = Avatar(
//   Icons.smart_toy_outlined,
//   getComputerAvatarRandomColor(),
// );

class Ship {
  // define information a ship needs to carry to improve deploying process, calculating ammount of ships in the fleet and other during the game...
  String shipName;
  int tiles;
  List<MapTile> locations = [];
  bool? isVertical;
  bool isDeployed = false;
  late int health;

  Ship({
    required this.shipName,
    required this.tiles,
    required this.locations,
    required this.isVertical,
    required this.isDeployed,
    required this.health,
  });

  Ship copy() {
    return Ship(
      shipName: shipName,
      tiles: tiles,
      locations: locations,
      isVertical: isVertical,
      isDeployed: isDeployed,
      health: health,
    );
  }
}

enum FractionName { navy, pirates, federation }

Fraction? selectedFraction;

Map<FractionName, Fraction> fractions = {
  FractionName.navy: navyFraction,
  FractionName.pirates: piratesFraction,
  FractionName.federation: federationFraction,
};

enum ShipSize { size1, size2, size3, size4, size5, size6 }

Map<ShipSize, int> shipSizeTiles = {
  ShipSize.size1: 1,
  ShipSize.size2: 2,
  ShipSize.size3: 3,
  ShipSize.size4: 4,
  ShipSize.size5: 5,
  ShipSize.size6: 6,
};

class Fraction {
  final FractionName name;
  final String description;
  final Map<ShipSize, double> shipSizeChanceConfig;
  final Map<ShipSize, String> shipNameConfig;

  Fraction({
    required this.name,
    required this.description,
    required this.shipSizeChanceConfig,
    required this.shipNameConfig,
  });
}

Fraction navyFraction = Fraction(
  name: FractionName.navy,
  description:
      "The Navy goes all-in with their armoured ships\ncovering vast areas of the sea.\n(Easier to detect but most durable)",
  shipSizeChanceConfig: {
    ShipSize.size1: 0.1,
    ShipSize.size2: 0.3,
    ShipSize.size3: 0.5,
    ShipSize.size4: 0.4,
    ShipSize.size5: 0.0,
    ShipSize.size6: 0.1,
  },
  shipNameConfig: {
    ShipSize.size1: "Patrol Boat",
    ShipSize.size2: "Interceptor",
    ShipSize.size3: "Destroyer",
    ShipSize.size4: "Battlecrusier",
    ShipSize.size5: "",
    ShipSize.size6: "Mothership",
  },
);

Fraction piratesFraction = Fraction(
  name: FractionName.pirates,
  description:
      "Pirates, me lad, we don't play fair.\nWe be strikin' from the shadows, arr!\n(Scattered and stealthy but fragile)",
  shipSizeChanceConfig: {
    ShipSize.size1: 0.4,
    ShipSize.size2: 0.3,
    ShipSize.size3: 0.21,
    ShipSize.size4: 0.09,
    ShipSize.size5: 0.0,
    ShipSize.size6: 0.0,
  },
  shipNameConfig: {
    ShipSize.size1: "Seaghoul",
    ShipSize.size2: "Brigantine",
    ShipSize.size3: "Storm Queen",
    ShipSize.size4: "Shadowstalker",
    ShipSize.size5: "",
    ShipSize.size6: "",
  },
);

Fraction federationFraction = Fraction(
  name: FractionName.federation,
  description:
      "The Federation, driven by profit and efficiency,\nalways deploys balanced and versatile fleet.\n(Standard and flexible lineup)",
  shipSizeChanceConfig: {
    ShipSize.size1: 0.4,
    ShipSize.size2: 0.3,
    ShipSize.size3: 0.21,
    ShipSize.size4: 0.09,
    ShipSize.size5: 0.0,
    ShipSize.size6: 0.0,
  },
  shipNameConfig: {
    ShipSize.size1: "Sanction Drone",
    ShipSize.size2: "Costal Janitor",
    ShipSize.size3: "Armed Science Vessel",
    ShipSize.size4: "Corporate Anihilator",
    ShipSize.size5: "",
    ShipSize.size6: "",
  },
);

extension FractionNameDisplay on FractionName {
  String get display {
    switch (this) {
      case FractionName.navy:
        return "Navy";
      case FractionName.pirates:
        return "Pirates";
      case FractionName.federation:
        return "Federation";
    }
  }
}

List<ShipTypeForPlayerAndFraction> calculateShipTypesLineupForPLayer({
  required double mapsize,
  required Fraction fraction,
  required int playerID,
}) {
  List<ShipTypeForPlayerAndFraction> lineup = [];

  final reversedShipSizes = ShipSize.values.reversed;

  for (ShipSize currentShipSize in reversedShipSizes) {
    double thisShipSizeQuantity =
        fraction.shipSizeChanceConfig[currentShipSize]!;
    int thisShipQuantity = (mapsize * thisShipSizeQuantity).round();
    if (thisShipQuantity > 0) {
      lineup.add(
        ShipTypeForPlayerAndFraction(
          fractionName: fraction.name,
          typeName: fraction.shipNameConfig[currentShipSize]!,
          tiles: shipSizeTiles[currentShipSize]!,
          quantity: thisShipQuantity,
          playerID: playerID,
        ),
      );
    }
  }

  return lineup;
}

class ShipTypeForPlayerAndFraction {
  final FractionName fractionName;
  final String typeName;
  final int tiles;
  final int quantity;
  final int playerID;

  ShipTypeForPlayerAndFraction({
    required this.fractionName,
    required this.typeName,
    required this.tiles,
    required this.quantity,
    required this.playerID,
  });
}

class Player {
  // stroing information about player made in this page
  String playerName;
  Avatar avatar;
  Fraction? fraction;
  List<ShipTypeForPlayerAndFraction>
  shipTypes; // for generating configuration (quantity)
  List<Ship> ships; // actual individual ships in game logic
  int playerID;
  bool isReady = false;
  late int totalHealth;
  late int currentHealth;

  Player({
    required this.playerName,
    required this.avatar,
    required this.fraction,
    required this.shipTypes,
    required this.ships,
    required this.playerID,
    required this.isReady,
    required this.totalHealth,
  });

  List<Ship> copyShipSetup() {
    return ships.map((ships) => ships.copy()).toList();
  }
}

int generatePlayerID() {
  return idbase++;
}

void displayShipTypes(
  FractionName fractionName,
  List<ShipTypeForPlayerAndFraction> shipTypes,
) {
  print('');
  print(shipTypes);
  print('===================================');
  print('PLAYER 1 SETUP:');
  print('==========  $fractionName ============');
  for (ShipTypeForPlayerAndFraction shipType in shipTypes) {
    print(
      '${shipType.typeName}, (${shipType.tiles} tiles) x${shipType.quantity}',
    );
  }
  print('===================================');
}

class GameSetup {
  // export class to transition to the next page (player1_deploy) and further to player2 introduction to store player2 information
  GameSettings difficultyGameModeAndMapSettings;
  Player player1;
  Player? player2; // this will store the second player later when it's ready

  GameSetup(this.difficultyGameModeAndMapSettings, this.player1);
}

Player setUpComputerEnemy() {
  int newID = generatePlayerID();
  late Player computerPlayer = Player(
    playerName: '',
    avatar: Avatar(Icons.smart_toy_outlined, getComputerAvatarRandomColor()),
    fraction: randomFraction(),
    shipTypes: [],
    ships: [],
    playerID: newID,
    isReady: false,
    totalHealth: 0,
  );
  if (myCustomGameSettings.gameMode == GameMode.computer) {
    Fraction chosenRandomFraction = randomFraction();

    computerPlayer = Player(
      playerName: generateComputerName(),
      avatar: Avatar(Icons.smart_toy_outlined, getComputerAvatarRandomColor()),
      fraction: chosenRandomFraction,
      shipTypes: calculateShipTypesLineupForPLayer(
        mapsize: myCustomGameSettings.mapsize,
        fraction: chosenRandomFraction,
        playerID: newID,
      ),
      ships: [],
      playerID: newID,
      isReady: false,
      totalHealth: 0,
    );
  }
  // Diagnostic print function
  print('');
  print("==========================================================");
  print("Auto set up of a Computer Enemy:");
  print("Computer Name: ${computerPlayer.playerName}");
  print("Computer Fraction: ${computerPlayer.fraction}");
  print("==========================================================");
  myCustomGameSettings.players.add(computerPlayer);

  return computerPlayer;
}

List<Ship> expandToIndividualShips(
  List<ShipTypeForPlayerAndFraction> playerShipTypeList,
) {
  List<Ship> individualShips = [];
  for (var shipType in playerShipTypeList) {
    for (int i = 0; i < shipType.quantity; i++) {
      individualShips.add(
        Ship(
          shipName: shipType.typeName,
          tiles: shipType.tiles,
          locations: [],
          isVertical: null,
          isDeployed: false,
          health: shipType.tiles,
        ),
      );
    }
  }
  return individualShips;
}

ItemType getRandomItem<ItemType>(List<ItemType> items) {
  final random = math.Random();
  int index = random.nextInt(items.length);
  return items[index];
}

String generateComputerName() {
  List<String> computerNames = [
    'Captain Hack',
    'Blackheart',
    'Captain Yapk',
    'Lieutenant Sendmail',
    'Bytebeard the Seahawk',
    'Admiral GPT',
    'Prof. Processor',
    'Captain RAM',
    'General Glitch',
    'Overlord OS',
  ];
  return getRandomItem(computerNames);
  /*
  final random = math.Random();
  int index = random.nextInt(computerNames.length);
  return computerNames[index];
  */
}

Color getComputerAvatarRandomColor() {
  return getRandomItem(computerAvatarColorList);
  /*
  final random = math.Random();
  int index = random.nextInt(computerAvatarColorList.length);
  return computerAvatarColorList[index]!;
  */
}

List<Color> playerAvatarColorList = [
  Colors.deepOrange[300]!,
  Colors.cyan[300]!,
  Colors.amber[500]!,
  Colors.teal[300]!,
  Colors.deepPurple[200]!,
];

List<Color> computerAvatarColorList = [
  Colors.deepOrange[100]!,
  Colors.cyan[100]!,
  Colors.amber[200]!,
  Colors.teal[100]!,
  Colors.deepPurple[100]!,
];
// Colors.red[300],
// Colors.cyan[400],
// Colors.amber[500],
// Colors.teal[300],
// Colors.purple[200],

void selectPlayerAvaterIcons() {
  final random = math.Random();
  int randomIconIndex = random.nextInt(allIcons.length);
  IconData? randomIcon = allIcons[randomIconIndex];

  for (int i = 0; i < 6; i++) {
    playerAvatarIconList.add(randomIcon);
  }
}

List<IconData?> playerAvatarIconList = [
  Icons.pest_control_rodent_rounded,
  Icons.support_sharp,
  Icons.kayaking_rounded,
  Icons.anchor_rounded,
  Icons.houseboat_rounded,
];

List<IconData?> allIcons = [
  Icons.sports_bar_outlined,
  Icons.bathtub_outlined,
  Icons.directions_boat_sharp,
  Icons.anchor_rounded,
  Icons.pest_control_rodent_rounded,
  Icons.sailing_sharp,
  Icons.castle_rounded,
  Icons.precision_manufacturing_rounded,
  Icons.kayaking_rounded,
  Icons.bakery_dining_rounded,
  Icons.soup_kitchen,
  Icons.diamond_rounded,
  Icons.fire_hydrant_alt_rounded,
  Icons.houseboat_rounded,
  Icons.pest_control_rodent_rounded,
  Icons.support_sharp,
  Icons.kayaking_rounded,
  Icons.anchor_rounded,
  Icons.houseboat_rounded,
];

Fraction randomFraction() {
  List<FractionName> fractionsNames = fractions.keys.toList();
  final random = math.Random();
  int index = random.nextInt(fractionsNames.length);
  return fractions.values.toList()[index];
}

GameSetup savedGameSettingsWithPlayers() {
  GameSetup customGameInformation = GameSetup(
    myCustomGameSettings,
    myCustomGameSettings.players.last,
  );
  return customGameInformation;
}

class _CustomPlayerIntroduction extends State<CustomPlayerIntroduction> {
  bool fractioniIsChosen = false;

  @override
  void initState() {
    super.initState();
    selectedFraction = null;
  }

  void test() {
    print('Current gameMode: ${myCustomGameSettings.gameMode}');
  }

  List<IconData> getGameModeSymbol(GameMode gameMode) {
    List<IconData> gameModeSymbolList = [];

    setState(() {
      if (gameMode == GameMode.pvp) {
        gameModeSymbolList.add((Icons.person));
        gameModeSymbolList.add((Icons.person));
      } else if (gameMode == GameMode.computer) {
        gameModeSymbolList.add((Icons.person));
        gameModeSymbolList.add((Icons.smart_toy_outlined));
      }
    });
    return gameModeSymbolList;
  }

  IconData setAvatarIcon(Player currentPlayer, IconData selectedIcon) {
    setState(() {
      currentPlayer.avatar.setAvatarIcon(selectedIcon);
      _exitRequested = false;
      isAvatarIcon = true;
    });
    return selectedIcon;
  }

  Color setAvatarColor(Player currentPlayer, Color selectedColor) {
    setState(() {
      currentPlayer.avatar.setAvatarColor(selectedColor);
      _exitRequested = false;
      isAvatarBackground = true;
    });
    return selectedColor;
  }

  // String fractionDescription(String fraction) {
  //   String description = '';

  //   setState(() {
  //     if (fraction == 'Navy') {
  //       description =
  //           "Navy deploys fewer but very powerful ships\nthat are more difficult to sink.\n(Heavy and powerful but easy to target)";
  //     } else if (fraction == 'Pirates') {
  //       description =
  //           "Pirates, me lad, we don't play fair.\nWe be strikin' from shadows, arr.\n(Scattered and stealthy but fragile)";
  //     } else if (fraction == 'Federation') {
  //       description =
  //           "Balanced and versatile.\nThe Federation adapts to any mission.\n(Standard, balanced lineup)";
  //     }
  //   });
  //   return description;
  // }

  void exitGame() {
    // clearMapResetDeploy();
    mapTiles.clear();
    _exitRequested = false;
    greenTiles.clear();
    thisShipPlacedTiles = 0;
    idbase = 1;

    mapside = 4;
    myCustomGameSettings.computerDifficulty = 0;
    myCustomGameSettings.gameMode = GameMode.notSet;
    myCustomGameSettings.mapsize = 4.0;

    for (Player player in myCustomGameSettings.players) {
      player.avatar = Avatar(Icons.question_mark_rounded, Colors.grey);
      player.fraction = null;
      player.playerName = '';
      player.shipTypes.clear();
      player.ships.clear();
      player.playerID = 0;
    }
    myCustomGameSettings.players.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('customize your profile'),
          leading: Icon(Icons.person),
          actions: [
            IconButton(
              icon: Icon(
                Icons.do_disturb,
                color: _exitRequested ? Colors.black : Colors.black12,
                size: 35,
              ),
              onPressed: () {
                if (_exitRequested) {
                  exitGame();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(title: 'SHIPS'),
                    ),
                    (Route<dynamic> route) =>
                        false, // Remove all previous routes
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '          Press again to exit the game          ',
                        style: TextStyle(color: Colors.red, fontSize: 24),
                      ),
                      behavior:
                          SnackBarBehavior
                              .floating, // Makes it float, not pinned
                      margin: EdgeInsets.only(left: 10, right: 10, bottom: 680),
                      duration: Duration(seconds: 4),
                    ),
                  );
                  setState(() {
                    _exitRequested = true;
                  });
                }
              },
            ),
          ],
        ),
        body: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 60)),
                // Text('Custom Game:'),
                SizedBox(width: 10),

                Icon(Icons.map_outlined),
                Text(
                  myCustomGameSettings.mapsize.toInt().toString() +
                      ('x') +
                      myCustomGameSettings.mapsize.toInt().toString(),
                ),
                SizedBox(width: 10),
                Icon(getGameModeSymbol(myCustomGameSettings.gameMode)[0]),
                SizedBox(width: 1),
                Text('vs'),
                SizedBox(width: 1),

                Icon(getGameModeSymbol(myCustomGameSettings.gameMode)[1]),
              ],
            ),
            SizedBox(height: 40),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 60),

              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: widget.currentPlayer.avatar.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.currentPlayer.avatar.icon, size: 50),
                  ),
                  SizedBox(width: 20),
                  Column(
                    children: [
                      Text(
                        ('Player') + widget.currentPlayer.playerID.toString(),
                        style: TextStyle(fontSize: 30),
                      ),
                      SizedBox(
                        width: 130,
                        // height: 50,
                        // padding: EdgeInsets.symmetric(horizontal: 2),
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'enter your name',
                          ),
                          onChanged: (String input) {
                            setState(() {
                              isName = true;
                              widget.currentPlayer.playerName =
                                  input.trimRight();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text('Modify your avatar:'),
            SizedBox(height: 5),
            GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: playerAvatarIconList.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setAvatarIcon(
                      widget.currentPlayer,
                      playerAvatarIconList[index]!,
                    );
                    setState(() {
                      isAvatarIcon = true;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      playerAvatarIconList[index],
                      color: Colors.black,
                      size: 35,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 5),
            GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 10),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: playerAvatarColorList.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setAvatarColor(
                      widget.currentPlayer,
                      playerAvatarColorList[index],
                    );
                    setState(() {
                      isAvatarBackground = true;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: playerAvatarColorList[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            Text('Fraction'),
            DropdownButton<Fraction>(
              items:
                  fractions.values.map((Fraction fraction) {
                    return DropdownMenuItem<Fraction>(
                      value: fraction,
                      child: Text(fraction.name.display),
                    );
                  }).toList(),
              hint: const Text('Select your Fraction'),
              value: selectedFraction, // can be null
              onChanged: (Fraction? newFraction) {
                _exitRequested = false;
                if (newFraction != null) {
                  setState(() {
                    isFraction = true;
                    widget.currentPlayer.isReady = true;
                    selectedFraction = newFraction;
                    widget.currentPlayer.fraction = selectedFraction;

                    // generate types of ships with quantities
                    widget
                        .currentPlayer
                        .shipTypes = calculateShipTypesLineupForPLayer(
                      mapsize: myCustomGameSettings.mapsize,
                      fraction: newFraction,
                      playerID: widget.currentPlayer.playerID,
                    );

                    // unwind from ships types into a flat list to list of individual ships
                    widget.currentPlayer.ships = expandToIndividualShips(
                      widget.currentPlayer.shipTypes,
                    );

                    // debug: display generated shiptypes lineup
                    displayShipTypes(
                      widget.currentPlayer.fraction!.name,
                      widget.currentPlayer.shipTypes,
                    );
                  });
                }
              },
            ),
            SizedBox(height: 20),
            Text(
              isFraction ? widget.currentPlayer.fraction!.description : '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 50),
            ElevatedButton.icon(
              label: Text(
                'Deploy your fleet!',
                style: TextStyle(color: Colors.white),
              ),
              icon: Icon(Icons.arrow_forward_rounded, color: Colors.white),
              style: ElevatedButton.styleFrom(
                elevation: canContinue ? 3 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    width: 2,
                    color: canContinue ? Colors.blueGrey : Colors.grey[200]!,
                  ),
                ),
                backgroundColor:
                    canContinue ? Colors.blueGrey : Colors.grey[200]!,
              ),
              onPressed: () {
                if (canContinue) {
                  // if (widget.settings.gameMode == 2) {
                  //   setUpComputerEnemy();
                  // }
                  // this logic is to be handled in the player deploy page, computer is to be deployed second
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        final settings = savedGameSettingsWithPlayers();
                        return PlayerDeployPage(settings, settings.player1);
                      },
                    ),
                  );
                  isName = false;
                  isAvatarIcon = false;
                  isAvatarBackground = false;
                  isFraction = false;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
