import 'package:confetti/confetti.dart';
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
  isWinner = false;
  message = '';
  _allowAction = true;

  mapTiles.clear();
  _exitRequested = false;
  greenTiles.clear();
  thisShipPlacedTiles = 0;

  mapside = 4;
  myCustomGameSettings.computerDifficulty = ComputerDifficulty.notSet;
  myCustomGameSettings.gameMode = GameMode.notSet;
  myCustomGameSettings.mapsize = 4.0;
  idbase = 1;

  for (Player player in myCustomGameSettings.players) {
    player.avatar = Avatar(Icons.question_mark_rounded, Colors.grey);
    player.faction = null;
    player.playerName = '';
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

void checkIsWinner(GameManager gameManager, GameStatsManager gameStatsManager) {
  if (gameManager.enemyPlayer.player.currentHealth == 0) {
    isWinner = true;
    gameStatsManager.getUncoveredTilesStats(gameManager);
    gameStatsManager.getHitPercentageStat(gameManager);
    gameStatsManager.getMissedShotsStat(gameManager);
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

void markEnemyStrikesOnNativeMap(
  GameManager gameManager,
  MapTile targetTile,
  bool isHit,
) {
  for (MapTile enemyNativeMapTile in gameManager.enemyPlayer.nativeTiles) {
    if (enemyNativeMapTile.x == targetTile.x &&
        enemyNativeMapTile.y == targetTile.y) {
      if (isHit) {
        enemyNativeMapTile.status = TileStatus.destroyed;
        break;
      } else {
        enemyNativeMapTile.status = TileStatus.target;
        break;
      }
    }
  }
}

void shotEnemyTile(
  GameManager gameManager,
  MapTile targetTile,
  GameStatsManager gameStatsManager,
) {
  bool isHit = false;
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
              isHit = true;
              gameManager.currentPlayer.player.successfulShots++;
              if (!gameStatsManager.isFirstHit) {
                gameStatsManager.gameStats.add(
                  GameStat(
                    gameStatType: GameStatType.firstHit,
                    playerName: gameManager.currentPlayer.player.playerName,
                    value: gameManager.currentTurn,
                  ),
                );
                gameStatsManager.isFirstHit = true;
              }
              message = 'Hit enemy ship at ${targetTile.alfaAdress} !';
              // directly display that the ship was already destroyed, uncover neighbouring tiles to clear up the map
              Ship? clickedShip = identifyEnemyShipByTile(
                gameManager.enemyPlayer,
                targetTile,
              );
              if (clickedShip!.health == 0) {
                message = "Enemy ship '${clickedShip.shipName}' was sunk!";
                uncoverNeighbourTiles(gameManager, clickedShip);
                if (!gameStatsManager.isFirstSunk) {
                  gameStatsManager.gameStats.add(
                    GameStat(
                      gameStatType: GameStatType.firstSunk,
                      playerName: gameManager.currentPlayer.player.playerName,
                      value: gameManager.currentTurn,
                    ),
                  );
                  gameStatsManager.isFirstSunk = true;
                }
              }

              break;
            } else {
              targetTile.status = TileStatus.water;
              targetTile.isExplored = true;
            }
          }
          if (isHit) {
            break;
          }
          message = 'Miss...';
          gameManager.currentPlayer.player.shotsFired++;
        }
        markEnemyStrikesOnNativeMap(gameManager, targetTile, isHit);
        // preview of targets selected by enemy on player's native map. if hit status marked as Destroyed (dark red), else marked as target (bright red)
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
  checkIsWinner(gameManager, gameStatsManager);
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
  late GameSettings gameSettings;
  int currentTurn = 1;

  GameManager({
    required this.playerA,
    required this.playerB,
    required this.gameSettings,
  });

  PlayerState get currentPlayer => currentTurn % 2 == 0 ? playerA : playerB;
  PlayerState get enemyPlayer => currentTurn % 2 == 0 ? playerB : playerA;

  void nextTurn() {
    currentTurn++;
  }
}

class UncoveredTiles {
  late final int totalUncoveredTiles;
  late final String playerName;
}

class HitPercentage {
  late final double hitPercentage;
  late final String playerName;
}

class LongestHitStreak {
  Map<String, int> hitStreakMap =
      {}; // <String> playerName, <int> longestStreak
}

enum GameStatType {
  firstHit, // <int> round
  firstSunk, // <int> round
  missedShots, // <int>
  longestHitStreak, // <int>
  uncoveredTiles, // <int> number of undiscovered tiles
  hitPercentage, // <int> % of accurate shots
}

class GameStat {
  final GameStatType gameStatType;
  final String playerName;
  final int value;

  const GameStat({
    required this.gameStatType,
    required this.playerName,
    required this.value,
  });
}

class GameStatsManager {
  List<GameStat> gameStats = [];
  bool isFirstHit = false;
  bool isFirstSunk = false;

  Map<GameStatType, int> statWeights = {};

  GameStatsManager();

  void getUncoveredTilesStats(GameManager gameManager) {
    int uncoveredTilesCounter = 0;
    for (MapTile tile in gameManager.currentPlayer.enemyTiles) {
      if (!tile.isExplored) {
        uncoveredTilesCounter++;
      }
    }
    gameStats.add(
      GameStat(
        gameStatType: GameStatType.uncoveredTiles,
        playerName: gameManager.currentPlayer.player.playerName,
        value: uncoveredTilesCounter,
      ),
    );
    uncoveredTilesCounter = 0;
    for (MapTile tile in gameManager.enemyPlayer.enemyTiles) {
      if (!tile.isExplored) {
        uncoveredTilesCounter++;
      }
    }
    gameStats.add(
      GameStat(
        gameStatType: GameStatType.uncoveredTiles,
        playerName: gameManager.enemyPlayer.player.playerName,
        value: uncoveredTilesCounter,
      ),
    );
  }

  void getHitPercentageStat(GameManager gameManager) {
    int accuracy =
        gameManager.currentPlayer.player.shotsFired == 0
            ? 0
            : ((gameManager.currentPlayer.player.successfulShots /
                        gameManager.currentPlayer.player.shotsFired) *
                    100)
                .round();
    gameStats.add(
      GameStat(
        gameStatType: GameStatType.hitPercentage,
        playerName: gameManager.currentPlayer.player.playerName,
        value: accuracy,
      ),
    );

    ///
    accuracy =
        gameManager.enemyPlayer.player.shotsFired == 0
            ? 0
            : ((gameManager.enemyPlayer.player.successfulShots /
                        gameManager.enemyPlayer.player.shotsFired) *
                    100)
                .round();
    gameStats.add(
      GameStat(
        gameStatType: GameStatType.hitPercentage,
        playerName: gameManager.enemyPlayer.player.playerName,
        value: accuracy,
      ),
    );
  }

  void getMissedShotsStat(GameManager gameManager) {
    gameStats.add(
      GameStat(
        gameStatType: GameStatType.missedShots,
        playerName: gameManager.currentPlayer.player.playerName,
        value:
            gameManager.currentPlayer.player.shotsFired -
            gameManager.currentPlayer.player.successfulShots,
      ),
    );

    gameStats.add(
      GameStat(
        gameStatType: GameStatType.missedShots,
        playerName: gameManager.enemyPlayer.player.playerName,
        value:
            gameManager.enemyPlayer.player.shotsFired -
            gameManager.enemyPlayer.player.successfulShots,
      ),
    );
  }

  GameStat getPlayerStat(String playerName) {
    List<GameStat> statsForSelectedPlayer = [];
    for (int i = 0; i < gameStats.length; i++) {
      if (gameStats[i].playerName == playerName) {
        statsForSelectedPlayer.add(gameStats[i]);
      }
    }
    return getRandomItem(statsForSelectedPlayer);
  }

  String describeStat(GameStat stat) {
    switch (stat.gameStatType) {
      case GameStatType.firstHit:
        return 'First hit in round ${stat.value}';
      case GameStatType.firstSunk:
        return 'First sunk in round ${stat.value}';
      case GameStatType.uncoveredTiles:
        return 'uncovered tiles: ${stat.value}';
      case GameStatType.hitPercentage:
        return '${stat.value}% shot accuracy';
      case GameStatType.missedShots:
        return '${stat.value} missed shots';
      // case GameStatType.longestHitStreak:
      //   return '';

      default:
        return 'GG';
    }
  }
}

class _GamePageState extends State<GamePage> {
  late GameManager gameManager;
  late GameStatsManager gameStatsManager;

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
        if (matchingTile.status == TileStatus.destroyed) {
          matchingTile.status = TileStatus.destroyed;
        } else {
          matchingTile.status = TileStatus.ship;
        }
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

    gameManager = GameManager(
      playerA: playerstate1,
      playerB: playerstate2,
      gameSettings: widget.gameSettings,
    );

    gameStatsManager = GameStatsManager();

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
        title: isWinner ? Text('') : Text('turn: ${gameManager.currentTurn}'),
        automaticallyImplyLeading: false,
        leading:
            isWinner
                ? null
                : Icon(gameManager.currentPlayer.player.avatar.icon),
        actions:
            isWinner
                ? []
                : [
                  IconButton(
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
                            margin: EdgeInsets.only(
                              left: 10,
                              right: 10,
                              bottom: 680,
                            ),
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
                      Icons.exit_to_app_rounded,
                      color: _exitRequested ? Colors.black : Colors.black12,
                    ),
                  ),
                ],
        backgroundColor:
            isWinner
                ? Colors.grey[200]!
                : gameManager.currentPlayer.player.avatar.background,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
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
                  //         '${gameManager.currentPlayer.player.name}  (${gameManager.currentPlayer.player.faction})',
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
                            ////////////////////////////////////////////////////////////// main playable map
                            child: GridView.builder(
                              itemCount: mapside * mapside,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: mapside,
                                    crossAxisSpacing: 0,
                                    mainAxisSpacing: 0,
                                  ),
                              itemBuilder: (context, index) {
                                MapTile enemyFieldTile =
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
                                        gameStatsManager,
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
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _exitRequested = false;
                                    if (gameManager
                                            .currentPlayer
                                            .player
                                            .hideNativeMap ==
                                        true) {
                                      gameManager
                                          .currentPlayer
                                          .player
                                          .hideNativeMap = false;
                                    } else {
                                      gameManager
                                          .currentPlayer
                                          .player
                                          .hideNativeMap = true;
                                    }
                                  });
                                },
                                child: SizedBox(
                                  height: 150,
                                  width: 150,
                                  ////////////////////////////////////////////////////////////// player's native map
                                  child:
                                      (gameManager
                                              .currentPlayer
                                              .player
                                              .hideNativeMap)
                                          ? Container(
                                            color: Colors.blueGrey,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Text(
                                                  '?',
                                                  style: TextStyle(
                                                    color:
                                                        Colors
                                                            .blueGrey
                                                            .shade400,
                                                    fontSize: 130,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'toggle map visibility',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : GridView.builder(
                                            itemCount: mapside * mapside,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: mapside,
                                                  crossAxisSpacing: 0,
                                                  mainAxisSpacing: 0,
                                                ),
                                            itemBuilder: (context, index) {
                                              MapTile nativeTile =
                                                  gameManager
                                                      .currentPlayer
                                                      .nativeTiles[index];
                                              return AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: 350,
                                                ),
                                                alignment: Alignment.center,
                                                color: getTileColor(
                                                  nativeTile.status,
                                                ),
                                                // child: Column(
                                                //   children: [
                                                //     Text(
                                                //       nativeTile
                                                //           .alfaAdress, //A4, B2, C3....
                                                //       textAlign: TextAlign.center,
                                                //       style: TextStyle(
                                                //         color: nativeTile.adresColor,
                                                //       ),
                                                //     ),
                                                //   ],
                                                // ),
                                              );
                                            },
                                          ),
                                ),
                              ),
                              SizedBox(width: 10),
                              SizedBox(
                                height: 90,

                                child: Column(
                                  children: [
                                    Row(
                                      spacing: 30,

                                      children: [
                                        Text(
                                          gameManager
                                              .currentPlayer
                                              .player
                                              .playerName,
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
                                      spacing: 30,
                                      children: [
                                        Text(
                                          gameManager
                                              .enemyPlayer
                                              .player
                                              .playerName,
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
                  // Text(player1.faction?.toString() ?? "null"),
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
                  // Text(player2.faction?.toString() ?? "null"),
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
                EndgameWidget(
                  gameManager: gameManager,
                  gameStatsManager: gameStatsManager,
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

String getQuote(String faction) {
  String quote = 'It is your turn!';
  final random = math.Random();
  int initial = random.nextInt(10);
  if (initial > 4) {
    return 'It is your turn!';
  } else if (initial > 2) {
    int randomNeutralQuoteIndex = random.nextInt(neutralQuotes.length);
    return neutralQuotes[randomNeutralQuoteIndex];
  } else {
    if (faction == 'Navy') {
      int randomNavyQuoteIndex = random.nextInt(navyQuotes.length);
      return navyQuotes[randomNavyQuoteIndex];
    } else if (faction == 'Pirates') {
      int randomPiratesQuoteIndex = random.nextInt(piratesQuotes.length);
      return piratesQuotes[randomPiratesQuoteIndex];
    } else if (faction == 'Federation') {
      int randomFederationQuoteIndex = random.nextInt(federationQuotes.length);
      return federationQuotes[randomFederationQuoteIndex];
    }
  }
  return quote;
}

class _PlayerCardState extends State<PlayerCard> {
  @override
  Widget build(BuildContext context) {
    String currentfaction =
        widget.currentPlayerState.player.faction!.name.display;
    String currentPlayerName = widget.currentPlayerState.player.playerName;
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
              Text(currentfaction, style: TextStyle(fontSize: 13)),
              SizedBox(height: 40),
              Text(
                getQuote(currentfaction),
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

class EndgameWidget extends StatefulWidget {
  final GameManager gameManager;
  final GameStatsManager gameStatsManager;

  const EndgameWidget({
    super.key,
    required this.gameManager,
    required this.gameStatsManager,
  });

  @override
  State<EndgameWidget> createState() => _EndgameWidgetState();
}

class _EndgameWidgetState extends State<EndgameWidget> {
  double? summaryColumnsSpacing = 100;
  double? summaryMapSize = 150;
  double? statsfontsize = 15;

  bool showStats = false;

  final _confettiController = ConfettiController();

  @override
  void dispose() {
    super.dispose();
    _confettiController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    if (showStats) {
      return Positioned.fill(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Text(
                'Game Summary',
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        widget.gameManager.currentPlayer.player.playerName,
                        style: TextStyle(fontSize: 30),
                      ),
                      Text(
                        widget
                            .gameManager
                            .currentPlayer
                            .player
                            .faction!
                            .name
                            .display,
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 15),
                      SizedBox(
                        height: summaryMapSize,
                        width: summaryMapSize,
                        child: GridView.builder(
                          itemCount: mapside * mapside,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: mapside,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                              ),
                          itemBuilder: (context, index) {
                            MapTile nativeTile =
                                widget
                                    .gameManager
                                    .currentPlayer
                                    .nativeTiles[index];
                            return Container(
                              alignment: Alignment.center,
                              color: getTileColor(nativeTile.status),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 30),
                      // SizedBox(
                      //   height: summaryMapSize,
                      //   width: summaryMapSize,
                      //   child: GridView.builder(
                      //     itemCount: mapside * mapside,
                      //     gridDelegate:
                      //         SliverGridDelegateWithFixedCrossAxisCount(
                      //           crossAxisCount: mapside,
                      //           crossAxisSpacing: 0,
                      //           mainAxisSpacing: 0,
                      //         ),
                      //     itemBuilder: (context, index) {
                      //       MapTile nativeTile =
                      //           widget
                      //               .gameManager
                      //               .currentPlayer
                      //               .enemyTiles[index];
                      //       return Container(
                      //         alignment: Alignment.center,
                      //         color: getTileColor(nativeTile.status),
                      //       );
                      //     },
                      //   ),
                      // ),
                      SizedBox(height: 30),
                      Text(
                        widget.gameStatsManager.describeStat(
                          widget.gameStatsManager.getPlayerStat(
                            widget.gameManager.currentPlayer.player.playerName,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: statsfontsize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 20), //summary columns spacing
                  Column(
                    children: [
                      Text(
                        widget.gameManager.enemyPlayer.player.playerName,
                        style: TextStyle(fontSize: 30),
                      ),
                      Text(
                        widget
                            .gameManager
                            .enemyPlayer
                            .player
                            .faction!
                            .name
                            .display,
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 15),
                      SizedBox(
                        height: summaryMapSize,
                        width: summaryMapSize,
                        child: GridView.builder(
                          itemCount: mapside * mapside,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: mapside,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                              ),
                          itemBuilder: (context, index) {
                            MapTile nativeTile =
                                widget
                                    .gameManager
                                    .enemyPlayer
                                    .nativeTiles[index];
                            return Container(
                              alignment: Alignment.center,
                              color: getTileColor(nativeTile.status),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 30),
                      // SizedBox(
                      //   height: summaryMapSize,
                      //   width: summaryMapSize,
                      //   child: GridView.builder(
                      //     itemCount: mapside * mapside,
                      //     gridDelegate:
                      //         SliverGridDelegateWithFixedCrossAxisCount(
                      //           crossAxisCount: mapside,
                      //           crossAxisSpacing: 0,
                      //           mainAxisSpacing: 0,
                      //         ),
                      //     itemBuilder: (context, index) {
                      //       MapTile nativeTile =
                      //           widget
                      //               .gameManager
                      //               .enemyPlayer
                      //               .enemyTiles[index];
                      //       return Container(
                      //         alignment: Alignment.center,
                      //         color: getTileColor(nativeTile.status),
                      //       );
                      //     },
                      //   ),
                      // ),
                      SizedBox(height: 30),
                      Text(
                        widget.gameStatsManager.describeStat(
                          widget.gameStatsManager.getPlayerStat(
                            widget.gameManager.enemyPlayer.player.playerName,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: statsfontsize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 50),
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
                        builder: (context) => MyHomePage(title: 'SHIPS'),
                      ),
                      (Route<dynamic> route) =>
                          false, // Remove all previous routes
                    );
                  });
                },
                label: Text('end game', style: TextStyle(color: Colors.white)),
                icon: Icon(Icons.sentiment_very_satisfied, color: Colors.white),
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
      );
    } else {
      return Positioned.fill(
        child: Container(
          color: Colors.white,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                // blastDirection: -(math.pi) / 2,
                colors: [
                  Colors.deepOrange[300]!,
                  Colors.cyan[300]!,
                  Colors.amber[500]!,
                  Colors.teal[300]!,
                  Colors.deepPurple[200]!,
                ],
                gravity: 0.03,
                emissionFrequency: 0.4,
                numberOfParticles: 10,
              ),
              Column(
                children: [
                  SizedBox(height: 30),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          widget
                              .gameManager
                              .currentPlayer
                              .player
                              .avatar
                              .background,
                    ),
                    child: Icon(
                      widget.gameManager.currentPlayer.player.avatar.icon,
                      size: 50,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "${widget.gameManager.currentPlayer.player.playerName}\nwins!",
                    style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'thank you for playing',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[500],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _confettiController.stop();
                        showStats = true;
                      });
                    },
                    label: Text(
                      'show game stats',
                      style: TextStyle(color: Colors.white),
                    ),
                    icon: Icon(Icons.bar_chart_outlined, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(width: 2, color: Colors.green),
                      ),
                      backgroundColor: Colors.green[200]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}
