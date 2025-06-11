import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'dart:math' as math;
import 'package:ships/custom_game_settings.dart';
import 'custom_player_introduction.dart';
import 'player_deploy_page.dart';
import 'main.dart';

class GamePage extends StatefulWidget {
  final GameSettings gameSettings;
  final Player player1;
  final Player player2;

  const GamePage(this.gameSettings, this.player1, this.player2, {super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

bool _exitRequested = false;
bool isWinner = false;

late Player player1;
late Player player2;

bool _showPlayerCard = true;
String message = '';

void exitGame() {
  mapTiles.clear();
  _exitRequested = false;
  greenTiles.clear();
  thisShipPlacedTiles = 0;

  mapside = 4;
  myCustomGameSettings.computerDifficulty = 0;
  myCustomGameSettings.gameMode = GameMode.notSet;
  myCustomGameSettings.mapsize = 4.0;
  idbase = 1;

  for (Player player in myCustomGameSettings.players) {
    player.avatar = Avatar(Icons.question_mark_rounded, Colors.grey);
    player.fraction = null;
    player.name = '';
    player.shipTypes.clear();
    player.ships.clear();
    player.playerID = 0;
  }
  myCustomGameSettings.players.clear();
}

List<MapTile> initializeNewMapTilesAndAddresses() {
  List<MapTile> newlyGeneratedMaptiles = [];
  int idCounter = 0;
  for (int y = 0; y < mapside; y++) {
    // -> y = rows
    for (int x = 0; x < mapside; x++) {
      // -> x = columns
      MapTile initializedTile = MapTile(
        y: y,
        x: x,
        alfaAdress: alfaAdressEncoderByIndex(idCounter),
        id: idCounter++,
        adresColor: getCoordinateContrastingColor(TileStatus.water),
        status: TileStatus.water,
      );
      // availableTiles.add(initializedTile);
      newlyGeneratedMaptiles.add(initializedTile);
    }
  }
  _exitRequested = false;
  return newlyGeneratedMaptiles;
}

String alfaAdressEncoderByIndex(int index) {
  int x = index % mapside;
  int y = index ~/ mapside;
  return boardLetters[x]! + (y + 1).toString();
}

final Map<int, String> boardLetters = {
  0: 'A',
  1: 'B',
  2: 'C',
  3: 'D',
  4: 'E',
  5: 'F',
  6: 'G',
  7: 'H',
  8: 'I',
  9: 'J',
  10: 'K',
  11: 'L',
  12: 'M',
  13: 'N',
  14: 'O',
  15: 'P',
  16: 'R',
  17: 'S',
  18: 'T',
  19: 'U',
  20: 'W',
  21: 'Y',
  22: 'Z',
};

bool _allowAction = true;

MapTile indexToMaptileBySubMap(List<MapTile> map, int index) {
  return map[index];
}

Ship? identifyEnemyShipByTile(PlayerState enemyPlayer, MapTile checkTile) {
  for (Ship ship in enemyPlayer.player.ships) {
    for (MapTile tile in ship.locations) {
      if (tile.x == checkTile.x && tile.y == checkTile.y) {
        return ship;
      }
    }
  }
  return null;
}

void checkIsWinner(GameManager gameManager) {
  if (gameManager.enemyPlayer.player.currentHealth == 0) {
    isWinner = true;
    message =
        "${gameManager.currentPlayer.player.name}'s all ships have been destroyed! ${gameManager.currentPlayer.player.name} wins!";
  }
}

MapTile? getMapTileByYX(int y, int x) {
  return mapTiles.firstWhereOrNull((tile) => tile.x == x && tile.y == y);
}

void uncoverNeighbourTiles(GameManager gameManager, Ship targetShip) {
  List<MapTile> tilesToUncover = [];

  for (MapTile shipTile in targetShip.locations) {
    int x = shipTile.x;
    int y = shipTile.y;

    List<(int, int)> neighbourAdresses = [
      (y, x + 1),
      (y, x - 1),
      (y + 1, x),
      (y - 1, x),
    ];
    for (final (neighbourY, neighbourX) in neighbourAdresses) {
      // MapTile? neighbourTile = getMapTileByYX(neighbourY, neighbourX);
      MapTile? neighbourTile = gameManager.currentPlayer.enemyTiles
          .firstWhereOrNull(
            (tile) => tile.x == neighbourX && tile.y == neighbourY,
          );

      if (neighbourTile != null) {
        tilesToUncover.add(neighbourTile);
      }
    }
  }

  for (MapTile shipOriginalTile in targetShip.locations) {
    int originalX = shipOriginalTile.x;
    int originalY = shipOriginalTile.y;

    tilesToUncover.removeWhere(
      (tile) => tile.x == originalX && tile.y == originalY,
    );
  }

  for (MapTile tileToUncover in tilesToUncover) {
    tileToUncover.status = TileStatus.water;
    tileToUncover.isExplored = true;
  }
}

void shotEnemyTile(GameManager gameManager, MapTile targetTile) {
  bool hit = false;
  _exitRequested = false;
  if (!isWinner) {
    if (targetTile.isExplored == false) {
      if (_allowAction) {
        List<Ship> enemyShips = gameManager.enemyPlayer.player.ships;
        for (Ship enemyShip in enemyShips) {
          for (MapTile enemyShipTile in enemyShip.locations) {
            if (enemyShipTile.x == targetTile.x &&
                enemyShipTile.y == targetTile.y) {
              targetTile.status = TileStatus.destroyed;
              enemyShip.health--;
              gameManager.enemyPlayer.player.currentHealth--;
              targetTile.isExplored = true;
              hit = true;
              message = 'Hit enemy ship at ${targetTile.alfaAdress} !';
              // directly display that the ship was already destroyed, uncover neighbouring tiles to clear up the map
              Ship? clickedShip = identifyEnemyShipByTile(
                gameManager.enemyPlayer,
                targetTile,
              );
              if (clickedShip!.health == 0) {
                message = "Enemy ship '${clickedShip.shipName}' was sunk!";
                uncoverNeighbourTiles(gameManager, clickedShip);
              }

              break;
            } else {
              targetTile.status = TileStatus.water;
              targetTile.isExplored = true;
            }
          }
          if (hit) {
            break;
          }
          message = 'Miss...';
        }
      } else {
        message = "That is all you could do. End your turn?";
      }

      _allowAction = false;
    } else {
      if (targetTile.status == TileStatus.water) {
        message =
            '${targetTile.alfaAdress}? You have already checked this tile.';
      } else if (targetTile.status == TileStatus.destroyed) {
        Ship? clickedShip = identifyEnemyShipByTile(
          gameManager.enemyPlayer,
          targetTile,
        );
        if (clickedShip != null) {
          if (clickedShip.health != 0) {
            message = 'Great! You have hit enemy ship. Try to destroy it!';
          } else if (clickedShip.health == 0) {
            message = "Congratulations! This ship is already destroyed.";
            // "Congratulations! This '${clickedShip.shipName}' is already destroyed.";
          }
        }
      }
    }
  }
  checkIsWinner(gameManager);
}

class PlayerState {
  final Player player;
  final List<MapTile> nativeTiles = initializeNewMapTilesAndAddresses();
  final List<MapTile> enemyTiles = initializeNewMapTilesAndAddresses();

  PlayerState({required this.player});

  void initializeNativeTiles() {
    for (MapTile nativeTile in nativeTiles) {
      nativeTile.status = TileStatus.water;
    }
  }

  void initializeEnemyTiles() {
    for (MapTile enemyTile in enemyTiles) {
      enemyTile.status = TileStatus.fogofwar;
    }
  }
}

class GameManager {
  late PlayerState playerA;
  late PlayerState playerB;
  int currentTurn = 1;

  GameManager({required this.playerA, required this.playerB});

  PlayerState get currentPlayer => currentTurn % 2 == 0 ? playerA : playerB;
  PlayerState get enemyPlayer => currentTurn % 2 == 0 ? playerB : playerA;

  void nextTurn() {
    currentTurn++;
  }
}

class _GamePageState extends State<GamePage> {
  late GameManager gameManager;

  void markPlayerNativeMapTilesOnNativeList(
    PlayerState currentNativePlayerState,
  ) {
    Player currentNativePlayer = currentNativePlayerState.player;
    for (Ship ship in currentNativePlayer.ships) {
      // iterating over player's ships
      for (MapTile shipTile in ship.locations) {
        // iterating over these ships' locations

        MapTile matchingTile = currentNativePlayerState.nativeTiles.firstWhere(
          (tile) => tile.x == shipTile.x && tile.y == shipTile.y,
        );
        matchingTile.status = TileStatus.ship;
      }
    }
  }

  int calculateTotalHealth(Player player) {
    int thisPlayerTotalHealth = 0;

    for (Ship ship in player.ships) {
      thisPlayerTotalHealth += ship.health;
    }

    return thisPlayerTotalHealth;
  }

  @override
  void initState() {
    super.initState();
    player1 = widget.gameSettings.players[0];
    player2 = widget.gameSettings.players[1];

    PlayerState playerstate1 = PlayerState(player: player1);
    PlayerState playerstate2 = PlayerState(player: player2);

    playerstate1.initializeNativeTiles();
    playerstate1.initializeEnemyTiles();

    playerstate2.initializeNativeTiles();
    playerstate2.initializeEnemyTiles();

    gameManager = GameManager(playerA: playerstate1, playerB: playerstate2);

    markPlayerNativeMapTilesOnNativeList(gameManager.currentPlayer);

    player1.totalHealth = calculateTotalHealth(player1);
    player1.currentHealth = player1.totalHealth;

    player2.totalHealth = calculateTotalHealth(player2);
    player2.currentHealth = player2.totalHealth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('turn: ${gameManager.currentTurn}'),
        leading: Icon(gameManager.currentPlayer.player.avatar.icon),
        actions: [
          IconButton(
            onPressed: () {
              if (_exitRequested) {
                exitGame();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyHomePage(title: 'SHIPS'),
                  ),
                  (Route<dynamic> route) => false, // Remove all previous routes
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '          Press again to exit the game          ',
                      style: TextStyle(color: Colors.red, fontSize: 24),
                    ),
                    behavior:
                        SnackBarBehavior.floating, // Makes it float, not pinned
                    margin: EdgeInsets.only(left: 10, right: 10, bottom: 680),
                    duration: Duration(seconds: 4),
                  ),
                );
                setState(() {
                  _exitRequested = true;
                  message = 'Do you want to end the game?';
                });
              }
            },
            icon: Icon(
              Icons.do_disturb,
              color: _exitRequested ? Colors.black : Colors.black12,
            ),
          ),
        ],
        backgroundColor: gameManager.currentPlayer.player.avatar.background,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // TextButton.icon(
            //   onPressed: () {
            //     _exitRequested = false;
            //   },
            //   icon: Icon(Icons.toggle_off),
            //   label: Text('toggle map'),
            //   style: TextButton.styleFrom(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(5),
            //       side: BorderSide(width: 2, color: Colors.grey[300]!),
            //     ),
            //   ),
            // ),
            if (!isWinner)
              TextButton.icon(
                onPressed: () {
                  if (!_allowAction) {
                    setState(() {
                      message = '';
                      _exitRequested = false;
                      _showPlayerCard = true;
                      _allowAction = true;
                      gameManager.nextTurn();
                      markPlayerNativeMapTilesOnNativeList(
                        gameManager.currentPlayer,
                      );
                    });
                  } else {
                    setState(() {
                      message = 'Make your move!';
                    });
                  }
                },

                icon: Icon(
                  Icons.double_arrow_rounded,
                  color: !_allowAction ? Colors.green : Colors.grey[200]!,
                ),
                label: Text(
                  'end your turn',
                  style: TextStyle(
                    color: !_allowAction ? Colors.green : Colors.grey[200]!,
                  ),
                ),
                //               style: ElevatedButton.styleFrom(
                //   elevation: ready ? 3 : 0,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(5),
                //     side: BorderSide(
                //       width: 2,
                //       color: ready ? Colors.green[500]! : Colors.blueGrey[100]!,
                //     ),
                //   ),
                //   backgroundColor:
                //       ready ? Colors.green[300] : Colors.blueGrey[100],
                // ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !_allowAction ? Colors.green[200] : Colors.grey[200]!,
                  elevation: !_allowAction ? 3 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                      width: 2,
                      color: !_allowAction ? Colors.green : Colors.grey[200]!,
                    ),
                  ),
                  // backgroundColor: Colors.grey[300]!,
                ),
              ),
          ],
        ),
      ),
      body: PopScope(
        canPop: false,
        child: Center(
          child: Stack(
            children: [
              Column(
                children: [
                  // SizedBox(height: 50),
                  // Text('current player view:'),
                  // Container(
                  //   height: 40,
                  //   color: gameManager.currentPlayer.player.avatar.background,

                  //   child: Row(
                  //     children: [
                  //       Icon(gameManager.currentPlayer.player.avatar.icon),
                  //       SizedBox(width: 10),
                  //       Text(
                  //         '${gameManager.currentPlayer.player.name}  (${gameManager.currentPlayer.player.fraction})',
                  //         style: TextStyle(fontSize: 20),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(width: 3),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: SizedBox(
                            width: 400,
                            height: 400,
                            child: GridView.builder(
                              itemCount: mapside * mapside,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: mapside,
                                    crossAxisSpacing: 1,
                                    mainAxisSpacing: 1,
                                  ),
                              itemBuilder: (context, index) {
                                final MapTile enemyFieldTile =
                                    gameManager.currentPlayer.enemyTiles[index];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      MapTile targetEnemyTile =
                                          indexToMaptileBySubMap(
                                            gameManager
                                                .currentPlayer
                                                .enemyTiles,
                                            index,
                                          );
                                      shotEnemyTile(
                                        gameManager,
                                        targetEnemyTile,
                                      );
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 350),
                                    alignment: Alignment.center,
                                    color: getTileColor(enemyFieldTile.status),
                                    child: Column(
                                      children: [
                                        Text(
                                          enemyFieldTile
                                              .alfaAdress, //A4, B2, C3....
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                getCoordinateContrastingColor(
                                                  enemyFieldTile.status,
                                                ),
                                          ),
                                        ),
                                        //   Text(
                                        //     tile.x.toString() +
                                        //         (':') +
                                        //         tile.y.toString(),
                                        //     textAlign: TextAlign.center,
                                        //     style: TextStyle(color: tile.adresColor),
                                        //   ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 90,
                                width: 90,
                                child: GridView.builder(
                                  itemCount: mapside * mapside,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: mapside,
                                        crossAxisSpacing: 1,
                                        mainAxisSpacing: 1,
                                      ),
                                  itemBuilder: (context, index) {
                                    final MapTile nativeTile =
                                        gameManager
                                            .currentPlayer
                                            .nativeTiles[index];
                                    return GestureDetector(
                                      onTap: () {
                                        // MapTile clickedTile = indexToMaptile(index);
                                        // gridTapPlaceShipTile(clickedTile);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        color: getTileColor(nativeTile.status),
                                        // child: Column(
                                        //   children: [
                                        //     Text(
                                        //       tile.alfaAdress, //A4, B2, C3....
                                        //       textAlign: TextAlign.center,
                                        //       style: TextStyle(color: tile.adresColor),
                                        //     ),
                                        //     Text(
                                        //       tile.x.toString() +
                                        //           (':') +
                                        //           tile.y.toString(),
                                        //       textAlign: TextAlign.center,
                                        //       style: TextStyle(color: tile.adresColor),
                                        //     ),
                                        //   ],
                                        // ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 10),
                              SizedBox(
                                height: 90,

                                child: Column(
                                  children: [
                                    Row(
                                      spacing: 10,

                                      children: [
                                        Text(
                                          gameManager.currentPlayer.player.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          Icons.favorite,
                                          size: 15,
                                          color:
                                              gameManager
                                                  .currentPlayer
                                                  .player
                                                  .avatar
                                                  .background,
                                        ),
                                        Text(
                                          '${gameManager.currentPlayer.player.currentHealth}/${gameManager.currentPlayer.player.totalHealth}',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      spacing: 10,
                                      children: [
                                        Text(
                                          gameManager.enemyPlayer.player.name,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          Icons.favorite,
                                          size: 15,
                                          color:
                                              gameManager
                                                  .enemyPlayer
                                                  .player
                                                  .avatar
                                                  .background,
                                        ),
                                        Text(
                                          '${gameManager.enemyPlayer.player.currentHealth}/${gameManager.enemyPlayer.player.totalHealth}',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const Text(
                  //   'Player 1',
                  //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  // ),
                  // Text('Name: ${player1.name}'),
                  // Icon(player1.avatar.icon),
                  // Container(
                  //   color: player1.avatar.background,
                  //   height: 10,
                  //   width: 10,
                  // ),
                  // Text(player1.fraction?.toString() ?? "null"),
                  // Text('Ship Types: ${player1.shipTypes.join(", ")}'),
                  // Text('Ships count: ${player1.ships.length}'),
                  // Text('Player ID: ${player1.playerID}'),
                  // Text('Is Ready: ${player1.isReady}'),

                  // const SizedBox(height: 16),

                  // const Text(
                  //   'Player 2',
                  //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  // ),
                  // Text('Name: ${player2.name}'),
                  // Icon(player2.avatar.icon),
                  // Container(
                  //   color: player2.avatar.background,
                  //   height: 10,
                  //   width: 10,
                  // ),
                  // Text(player2.fraction?.toString() ?? "null"),
                  // Text('Ship Types: ${player2.shipTypes.join(", ")}'),
                  // Text('Ships count: ${player2.ships.length}'),
                  // Text('Player ID: ${player2.playerID}'),
                  // Text('Is Ready: ${player2.isReady}'),
                ],
              ),
              if (_showPlayerCard)
                Positioned.fill(
                  child: PlayerCard(
                    gameSettings: widget.gameSettings,
                    currentPlayerState: gameManager.currentPlayer,
                    onContinue: () {
                      setState(() {
                        _showPlayerCard = false;
                      });
                    },
                  ),
                ),
              if (isWinner)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SizedBox(height: 70),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                gameManager
                                    .currentPlayer
                                    .player
                                    .avatar
                                    .background,
                          ),
                          child: Icon(
                            gameManager.currentPlayer.player.avatar.icon,
                            size: 50,
                          ),
                        ),
                        SizedBox(height: 30),
                        Text(
                          "${gameManager.currentPlayer.player.name} wins!",
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          gameManager.currentPlayer.player.fraction!,
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 40),
                        Text(
                          'thank you for playing',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              exitGame();
                              isWinner = false;
                              message = '';
                              _allowAction = true;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MyHomePage(title: 'SHIPS'),
                                ),
                                (Route<dynamic> route) =>
                                    false, // Remove all previous routes
                              );
                            });
                          },
                          label: Text(
                            'end game',
                            style: TextStyle(color: Colors.white),
                          ),
                          icon: Icon(
                            Icons.sentiment_very_satisfied,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: BorderSide(width: 2, color: Colors.red),
                            ),
                            backgroundColor: Colors.red[200]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerCard extends StatefulWidget {
  final GameSettings gameSettings;
  final PlayerState currentPlayerState;
  final VoidCallback onContinue;

  const PlayerCard({
    super.key,
    required this.gameSettings,
    required this.currentPlayerState,
    required this.onContinue,
  });

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

List<String> neutralQuotes = [
  'Dominating the seas yet?',
  "Let's get the boat off shore!",
  'The sea is yours — for now.',
  'Which way will the wind blow today?',
  "You've got this... probably!",
  "The sea's waiting — don't let her dry out!",
  "Let's make this one count!",
  'Your next move could make waves.',
];
List<String> navyQuotes = [
  'Time for your move, Commander!',
  'We await your orders.',
  "Let's bring discipline to these waters.",
  "Let's make this maneuver count.",
  'Bring order to the waves.',
  "Let them fire first — we'll fire last.",
  "The torpedoes are fine. It's the aim that worries me...",
  "It's high time we brought peace to these waters.",
  "Don't worry, we brought extra torpedoes.",
  'Maintain formation.',
  "It is not a submarine! It is not supposed to sink like that!!",
];
List<String> piratesQuotes = [
  'Arr!',
  "Aye aye Captain!",
  "Time to sink'em scallywags!",
  "Let's give'em landlubbers a taste of the sea bottom!",
  "Get'em!",
  "What will we do with a drunken sailor?",
  "Dead men tell no tales!",
  "Fire in the hole!",
  "These treasures ain't gonna steal themselves!",
  "A smooth sea never made a skilled pirate.",
  "Sink 'em before they sink you!",
  "If it floats, we can sink it!",
  "Who needs a plan when you've got cannons!?",
];
List<String> federationQuotes = [
  "Let's solve this conflict... profitably.",
  "Keys? yes, Phone? yes, Morality? .... Money? yes! - All good!",
  "Federation ships don't run on idealism.",
  "Reputation is fine. Payment is why we fight.",
  "Another target. Another invoice.",
  "Let's make this... cost-effective.",
  "Protocol says don't hesitate. Profit agrees.",
  "Autopilot would've done this faster.",
  "We don't chase glory. We bill it.",
  "Flash sale! 20% off for orders over ten targets!",
  "Shot-one-get-one-free",
  "Let's liquify their ships!",
  "Authorisation. Would you like a confirmation for that target?",
  "It's you again? Would you like to join our loyalty programme?",
  "Do like you'd do it for yourself (if they pay enough).",
  'Would you like to round up this strike for charity?',
];

String getQuote(String fraction) {
  String quote = 'It is your turn!';
  final random = math.Random();
  int initial = random.nextInt(10);
  if (initial > 4) {
    return 'It is your turn!';
  } else if (initial > 2) {
    int randomNeutralQuoteIndex = random.nextInt(neutralQuotes.length);
    return neutralQuotes[randomNeutralQuoteIndex];
  } else {
    if (fraction == 'Navy') {
      int randomNavyQuoteIndex = random.nextInt(navyQuotes.length);
      return navyQuotes[randomNavyQuoteIndex];
    } else if (fraction == 'Pirates') {
      int randomPiratesQuoteIndex = random.nextInt(piratesQuotes.length);
      return piratesQuotes[randomPiratesQuoteIndex];
    } else if (fraction == 'Federation') {
      int randomFederationQuoteIndex = random.nextInt(federationQuotes.length);
      return federationQuotes[randomFederationQuoteIndex];
    }
  }
  return quote;
}

class _PlayerCardState extends State<PlayerCard> {
  @override
  Widget build(BuildContext context) {
    String currentFraction = widget.currentPlayerState.player.fraction!;
    String currentPlayerName = widget.currentPlayerState.player.name;
    Color currentColor = widget.currentPlayerState.player.avatar.background;
    IconData currentIcon = widget.currentPlayerState.player.avatar.icon;

    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            children: [
              SizedBox(height: 70),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentColor,
                ),
                child: Icon(currentIcon, size: 50),
              ),
              SizedBox(height: 30),
              Text(
                currentPlayerName,
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              Text(currentFraction, style: TextStyle(fontSize: 13)),
              SizedBox(height: 40),
              Text(
                getQuote(currentFraction),
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  widget.onContinue();
                },
                label: Text('continue', style: TextStyle(color: Colors.white)),
                icon: Icon(Icons.arrow_forward, color: Colors.white),
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
