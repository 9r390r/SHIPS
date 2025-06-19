import 'dart:math' as math;
// import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:ships/custom_game_settings.dart';
import 'package:ships/game_page.dart';
import 'custom_player_introduction.dart';
import 'main.dart';

class PlayerDeployPage extends StatefulWidget {
  final PreGameManager preGameManager;
  final Player currentPlayer;

  const PlayerDeployPage(this.preGameManager, this.currentPlayer, {super.key});

  @override
  State<PlayerDeployPage> createState() => _PlayerDeployPage();
}

//////
enum TileStatus {
  fogofwar, // undiscovered tile (black)
  water, // empty tile (blue)
  ship, // ship tile (brown)
  allowed, // you can make action here (green)
  blocked, // you can not make action here (red)
  destroyed, // for marking hit tiles, ?calculating
  sand, // for later implementations (yellow)
  grass, // for later implementations (green)
}

Color getCoordinateContrastingColor(TileStatus status) {
  switch (status) {
    case TileStatus.fogofwar:
    case TileStatus.ship:
    case TileStatus.allowed:
    case TileStatus.destroyed:
      return Colors.white;

    case TileStatus.blocked:
    case TileStatus.sand:
    case TileStatus.water:
      return Colors.black;

    default:
      return Colors.blueGrey;
  }
}

Color getTileColor(TileStatus status) {
  if (status == TileStatus.fogofwar) {
    return Colors.black;
  } else if (status == TileStatus.water) {
    return Colors.blue[100]!;
  } else if (status == TileStatus.ship) {
    return Colors.brown[700]!;
  } else if (status == TileStatus.allowed) {
    return Colors.greenAccent[700]!;
  } else if (status == TileStatus.blocked) {
    return Colors.redAccent[400]!;
  } else if (status == TileStatus.destroyed) {
    // return Colors.red[900]!;
    return Colors.deepOrangeAccent[700]!;
  } else if (status == TileStatus.sand) {
    return Colors.amber[400]!;
  } else {
    return Colors.black;
  }
}

class MapTile {
  final int id; // index
  String alfaAdress; // e.g., "A3"
  Color adresColor; // black when bright backround, white when dark backround
  TileStatus
  status; // color coded for displayin ship-tile (brown), water-tile (blue)...
  int x;
  int y;
  bool isExplored = false;

  MapTile({
    required this.id,
    required this.alfaAdress,
    required this.adresColor,
    required this.status,
    required this.x,
    required this.y,
  });

  MapTile copy() {
    return MapTile(
      id: id, // index
      alfaAdress: alfaAdress,
      adresColor: adresColor,
      status: status,
      x: x,
      y: y,
    );
  }
}

int thisShipPlacedTiles = 0; // logic operator

List<int> shipsToDeploySimplified =
    []; // simplified ships (tile-counts) for deploying logic purposes
late int mapside;
List<ShipTypeForPlayerAndFraction> currentPlayershipTypesToDeploy =
    []; // types of ships of currentPlayer
List<Ship> currentPlayerShipsOriginal = []; // original list no modifications

List<MapTile> availableTiles = []; // non-blocked tiles
List<MapTile> greenTiles = []; // specifically used for auto-deploy functions

List<MapTile> mapTiles = []; // storage for the map
int n = 0;

int currentPlayerDeployProgress = 0; // progress bar

List<int> shipsQuantiiesToDisplay = []; // how many ship of each type

bool continueIsReady = false;
bool deployError = false;
bool _exitRequested = false;
late bool isPVC;
late bool isComputerDeployTurn;

bool get coverComputerDeploy {
  return isPVC && isComputerDeployTurn;
}

late Color playerColor;
late IconData playerIcon;

// enum Orientation { horizontal, verical }
late ValueNotifier<List<MapTile>> mapTilesNotifier;

void prepareMapToDeployNextPlayer() {
  availableTiles.clear();
  for (MapTile tile in mapTiles) {
    tile.status = TileStatus.water;
    tile.adresColor = getCoordinateContrastingColor(TileStatus.water);
    availableTiles.add(tile);
  }

  n = 0; // ship index in player.ships
  thisShipPlacedTiles = 0;

  shipsQuantiiesToDisplay.clear();
  shipsToDeploySimplified.clear();
  greenTiles.clear();
  currentPlayerDeployProgress = 0;
  print('================================');
  print('Map ready to deploy next player!');
  print('================================');
}

class _PlayerDeployPage extends State<PlayerDeployPage> {
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

  @override
  void initState() {
    super.initState();

    mapTilesNotifier = ValueNotifier<List<MapTile>>(mapTiles);

    mapside =
        widget.preGameManager.difficultyGameModeAndMapSettings.mapsize.toInt();
    isPVC =
        widget.preGameManager.difficultyGameModeAndMapSettings.gameMode ==
        GameMode.computer;
    isComputerDeployTurn = widget.currentPlayer.isComputer;
    currentPlayershipTypesToDeploy = widget.currentPlayer.shipTypes;
    currentPlayerShipsOriginal = widget.currentPlayer.ships;

    playerColor = widget.currentPlayer.avatar.background;
    playerIcon = widget.currentPlayer.avatar.icon;

    for (var ship in currentPlayershipTypesToDeploy) {
      int shipSize = ship.tiles;
      int quantity = ship.quantity;
      for (int i = 0; i < quantity; i++) {
        // deployShipsSizesList.add(quantity);
        shipsToDeploySimplified.add(shipSize);
        shipsQuantiiesToDisplay.add(quantity);
        currentPlayerDeployProgress += shipSize;
      }
    }
    if (mapTiles.isEmpty) {
      // only generate map if it is not ready yet, this should stop regenerating the map each time you open this page
      initializeMapTilesAndAddresses();
    }
    clearMapResetDeploy();
    // if (widget.gameSetup.difficultyGameModeAndMapSettings.gameMode == 2 &&
    //     widget.gameSetup.player1.isReady) {
    //   autoDeploy();
    //   prepareMapToDeployNextPlayer();
    // }
  }

  void initializeMapTilesAndAddresses() {
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
        availableTiles.add(initializedTile);
        mapTiles.add(initializedTile);
      }
    }
    _exitRequested = false;
  }

  int get adressesCount => mapside * mapside;

  String alfaAdressEncoderByIndex(int index) {
    int x = index % mapside;
    int y = index ~/ mapside;
    return boardLetters[x]! + (y + 1).toString();
  }

  MapTile? getMapTileByYX(int y, int x) {
    return mapTiles.firstWhereOrNull((tile) => tile.x == x && tile.y == y);
  }

  bool checkIsShipTilePlacedNextToExisitingShipTile(MapTile tile) {
    final thisShipIs1Tile = widget.currentPlayer.ships[n].tiles == 1;
    if (thisShipIs1Tile) {
      // does not aply to a ship which is 1-tile only
      return true;
    } else if (thisShipPlacedTiles == 0) {
      // does not apply to a ship which deployment is just starting
      return true;
    }
    // all other conditions need to be checked, new tile must be placed next to the exsiting one
    bool isNextTo = false;

    int x = tile.x;
    int y = tile.y;

    List<(int, int)> neighbourAdresses = [
      (y, x + 1),
      (y, x - 1),
      (y + 1, x),
      (y - 1, x),
    ];

    for (final (neighbourY, neighbourX) in neighbourAdresses) {
      MapTile? checkedTile = getMapTileByYX(neighbourY, neighbourX);
      final isPlacedNextToExisingShipTile = widget
          .currentPlayer
          .ships[n]
          .locations
          .contains(checkedTile);
      if (isPlacedNextToExisingShipTile) {
        return true;
      }
    }
    return isNextTo;
  }

  void blockUnallowedNeighbours(bool isVertical, MapTile shipTile) {
    // funtion marks above and below maptiles as blocked for horizontal ship
    // funtion marks left and right maptiles as blocked for vertical ship

    if (isVertical) {
      List<(int, int)> unallowedVerticalNeighbours = [
        (shipTile.y, shipTile.x + 1),
        (shipTile.y, shipTile.x - 1),
      ];
      for (final (y, x) in unallowedVerticalNeighbours) {
        final isInMapRange = x >= 0 && x < mapside && y >= 0 && y < mapside;
        if (isInMapRange) {
          MapTile maptileToBlock = getMapTileByYX(y, x)!;
          maptileToBlock.status = TileStatus.blocked;
          availableTiles.remove(maptileToBlock);
          greenTiles.remove(maptileToBlock);
        }
      }
    } else {
      List<(int, int)> unallowedHorizontalNeighbours = [
        (shipTile.y + 1, shipTile.x),
        (shipTile.y - 1, shipTile.x),
      ];
      for (final (y, x) in unallowedHorizontalNeighbours) {
        if (x >= 0 && x < mapside && y >= 0 && y < mapside) {
          MapTile maptileToBlock = getMapTileByYX(y, x)!;
          maptileToBlock.status = TileStatus.blocked;
          availableTiles.remove(maptileToBlock);
          greenTiles.remove(maptileToBlock);
        }
      }
    }
  }

  void showAllowedBlockedTiles(MapTile tile) {
    //

    Ship currentShip = widget.currentPlayer.ships[n];
    Ship? lastCheckedShip;

    if (currentShip != lastCheckedShip) {
      // now deploying new ship:
      thisShipPlacedTiles++;
      lastCheckedShip = currentShip;
      // ended deploying this ship
    }

    final isCompletelyDeployed =
        (widget.currentPlayer.ships[n].tiles != 1) &&
        (thisShipPlacedTiles == widget.currentPlayer.ships[n].tiles);
    if (isCompletelyDeployed) {
      // it means that the ship has been completely deployed
      // here proceeding with changing the tails marked as availabe to blocked

      List<int> yValues =
          widget.currentPlayer.ships[n].locations
              .map((tile) => tile.y)
              .toList();
      List<int> xValues =
          widget.currentPlayer.ships[n].locations
              .map((tile) => tile.x)
              .toList();

      int minY = yValues.reduce(math.min) - 1;
      int minX = xValues.reduce(math.min) - 1;

      int maxY = yValues.reduce(math.max) + 1;
      int maxX = xValues.reduce(math.max) + 1;

      // vertical ships: (tiles to block are) topTail, bottomTail -> // minY & // maxY
      MapTile? topTail = getMapTileByYX(minY, xValues[0]); // topTail
      MapTile? bottomTail = getMapTileByYX(maxY, xValues[0]); // bottomTail

      // horizontal ships: (tiles to block are) maxLeftTail, maxRightTail -> // minX & // maxX
      MapTile? maxLeftTail = getMapTileByYX(yValues[0], minX); // maxLeftTail
      MapTile? maxRightTail = getMapTileByYX(yValues[0], maxX); // maxRightTail

      if (topTail != null) {
        topTail.status = TileStatus.blocked;
        availableTiles.remove(topTail);
        greenTiles.remove(topTail);
      }
      if (bottomTail != null) {
        bottomTail.status = TileStatus.blocked;
        availableTiles.remove(bottomTail);
        greenTiles.remove(bottomTail);
      }
      if (maxLeftTail != null) {
        maxLeftTail.status = TileStatus.blocked;
        availableTiles.remove(maxLeftTail);
        greenTiles.remove(maxLeftTail);
      }
      if (maxRightTail != null) {
        maxRightTail.status = TileStatus.blocked;
        availableTiles.remove(maxRightTail);
        greenTiles.remove(maxRightTail);
      }

      print('');
      print('this "${currentShip.shipName}" has been succesfully deployed!');
      print('');
    } else if (widget.currentPlayer.ships[n].tiles == 1) {
      // previous logic focuses on 2-tile ships and bigger
      // here, if 1-tile ship is placed, neighbouring tiles are immediately set as blocked

      int thisOneTileShipY = tile.y;
      int thisOneTileShipX = tile.x;

      List<(int, int)> oneTileShipNeighbourAdresses = [
        (thisOneTileShipY + 1, thisOneTileShipX),
        (thisOneTileShipY - 1, thisOneTileShipX),
        (thisOneTileShipY, thisOneTileShipX + 1),
        (thisOneTileShipY, thisOneTileShipX - 1),
      ];

      for (final (neighbourY, neighbourX) in oneTileShipNeighbourAdresses) {
        final isNeighbourInMapRange =
            (neighbourY < mapside && neighbourY >= 0) &&
            (neighbourX < mapside && neighbourX >= 0);
        if (isNeighbourInMapRange) {
          MapTile tileToBlock = getMapTileByYX(neighbourY, neighbourX)!;
          tileToBlock.status = TileStatus.blocked;
          availableTiles.remove(tileToBlock);
          greenTiles.remove(tileToBlock);
        }
      }
      print('');
      print(
        'this "${currentShip.shipName}" has been succesfully deployed! single-tile',
      );
      print('');
    }

    setState(() {
      final isThisShipLargerThanTwoTiles = currentShip.locations.length >= 2;
      if (isThisShipLargerThanTwoTiles) {
        bool isVertical =
            currentShip.locations[0].x == currentShip.locations[1].x;
        if (isVertical) {
          // print('--------> this ship is vertical');
          currentShip.isVertical = true;
        } else {
          // print('--------> this ship is horizontal');
          currentShip.isVertical = false;
        }

        for (MapTile tile in currentShip.locations) {
          blockUnallowedNeighbours(isVertical, tile);
        }
      }
    });

    int y = tile.y;
    int x = tile.x;

    List<(int, int)> neighbourAdresses = [
      (y + 1, x),
      (y - 1, x),
      (y, x + 1),
      (y, x - 1),
    ];

    for (final (neighbourY, neighbourX) in neighbourAdresses) {
      for (MapTile tileToUpdate in availableTiles) {
        final isInMapRange = x >= 0 && x < mapside && y >= 0 && y < mapside;
        if (isInMapRange) {
          // safetycheck, are accessed indexes only existing ones
          final tileToUpdateIsNeighbourTile =
              tileToUpdate.y == neighbourY && tileToUpdate.x == neighbourX;
          if (tileToUpdateIsNeighbourTile) {
            tileToUpdate.status = TileStatus.allowed;
            greenTiles.add(tileToUpdate);
          }
        }
      }
    }
    printGreenTiles();
  }

  void printGreenTiles() {
    // List<MapTile> greenTiles
    print(" G R E E N    T I L E S");

    for (var element in greenTiles) {
      print('${element.alfaAdress}');
    }
    print(" -------------------- ");
  }

  MapTile indexToMaptile(int index) {
    return mapTiles[index];
  }

  MapTile gridTapPlaceShipTile(MapTile clickedTile) {
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   =>   n = $n");
    _exitRequested = false;
    // MapTile clickedTile = mapTiles[index];
    setState(() {
      final hasShipsToDeploy = shipsToDeploySimplified.isNotEmpty;
      if (hasShipsToDeploy) {
        // Are there ships to deploy?
        // list of simplified ships is a list of total ships (their tile value) that player will deploy (not just types of ships 'destroyer', like in the class),
        // [3, 2, 2] = one 3-tile ship and two 2-tile ships
        // as long as this list contains elements, there are ships that have to be deployed

        final hasTilesToDeploy = shipsToDeploySimplified[0] > 0;
        if (hasTilesToDeploy) {
          // Are there still tiles to place for the current ship?
          // always starting deploying from the first item, we check if the current ship is deployed entirely or not yet
          // if it is not deployed yet (if shipsToDeploySimplified[0] > 0) we can edit the selected tile 'clickedTile'
          final isNotPlacedCorrectly =
              !checkIsShipTilePlacedNextToExisitingShipTile(clickedTile);
          if (isNotPlacedCorrectly) {
            return;
          }
          _editClickedTile(clickedTile, n);
          final hasNoTilesToDeploy = shipsToDeploySimplified[0] == 0;
          if (hasNoTilesToDeploy) {
            shipsToDeploySimplified.removeAt(0);
            widget.currentPlayer.ships[n].isDeployed = true;
            n++;
            thisShipPlacedTiles = 0;

            availableTiles.remove(clickedTile);
            //???? greenTiles.remove(clickedTile);
            print(
              "===========================> range error?? n=$n, ships length=${widget.currentPlayer.ships.length}",
            );
            print('');
            _printDeployLog();
            print('........................');
          }
        }
      } else {
        // All ships placed, ready to continue
        continueIsReady = true;
        print('');
        print('=========< SHIP DEPLOYMENT SUCCESS >=========');
        print('');
        widget.currentPlayer.isReady = true;
      }
    });

    return clickedTile;
  }

  void _editClickedTile(MapTile tile, int n) {
    setState(() {
      final isTilePlacedOnCorrectLocation =
          (tile.status == TileStatus.water && thisShipPlacedTiles == 0) ||
          (thisShipPlacedTiles > 0 && tile.status == TileStatus.allowed);
      final isUndoCandidate =
          tile.status == TileStatus.ship &&
          !widget.currentPlayer.ships[n].isDeployed;
      final isTileBloced = tile.status == TileStatus.blocked;
      if (isTilePlacedOnCorrectLocation) {
        if (!availableTiles.contains(tile)) {
          return;
        }
        availableTiles.remove(tile);
        greenTiles.remove(tile);
        // update tile visual properties (background color and color of the adress)
        currentPlayerDeployProgress--;
        // with each click that depploys a part of ship we subtract this global counter that roughly informs us about how much of deploying is left
        tile.status = TileStatus.ship; // set tile color
        tile.adresColor = getCoordinateContrastingColor(
          TileStatus.ship,
        ); // set adress color
        // in the original ship database for player the selected tile is being added to the locations list
        widget.currentPlayer.ships[n].locations.add(tile);
        shipsToDeploySimplified[0]--; // decrease the current ship tile count
      } else if (isUndoCandidate) {
        return;
        // undo not allowed for stability reasons, => can restart deploy by clearing the map
        // undo logic could be reintroduced in the future versions

        // availableTiles.add(tile);
        // // reversed logic for undo ship tile deployment. (changing colours and adding +1 back to lists and counters)
        // currentPlayerDeployProgress++; // global counter
        // tile.status = TileStatus.water; // set tile color
        // tile.adresColor = getCoordinateContrastingColor(
        //   TileStatus.water, // set adress color
        // );
        // shipsToDeploySimplified[0]++; // increase the the current ship tile count
      } else if (isTileBloced) {
        return;
        // don't allow selecting on blocked tiles under any conditions
      }
      showAllowedBlockedTiles(tile);
    });
  }

  void _printDeployLog() {
    print('==========================================================');
    print('currentPlayer DeployProgress: $currentPlayerDeployProgress');
    print('shipsToDeploySimplified: $shipsToDeploySimplified');
    print('n = $n');
  }

  void clearMapResetDeploy() {
    setState(() {
      for (Ship ship in widget.currentPlayer.ships) {
        ship.isDeployed = false;
        ship.locations.clear();
      }
      availableTiles.clear();
      for (MapTile tile in mapTiles) {
        tile.status = TileStatus.water;
        tile.adresColor = getCoordinateContrastingColor(TileStatus.water);
        availableTiles.add(tile);
      }
      widget.currentPlayer.shipTypes = calculateShipTypesLineupForPLayer(
        mapsize: widget.preGameManager.difficultyGameModeAndMapSettings.mapsize,
        fraction: widget.currentPlayer.fraction!,
        playerID: widget.currentPlayer.playerID,
      );
      widget.currentPlayer.ships = expandToIndividualShips(
        widget.currentPlayer.shipTypes,
      );
      n = 0; // ship index in player.ships
      currentPlayershipTypesToDeploy = widget.currentPlayer.shipTypes;
      currentPlayerShipsOriginal = widget.currentPlayer.ships;
      currentPlayerDeployProgress = widget.currentPlayer.ships.length;
      thisShipPlacedTiles = 0;

      shipsQuantiiesToDisplay.clear();
      shipsToDeploySimplified.clear();
      greenTiles.clear();

      for (var ship in currentPlayershipTypesToDeploy) {
        int shipSize = ship.tiles;
        int quantity = ship.quantity;
        for (int i = 0; i < quantity; i++) {
          // deployShipsSizesList.add(quantity);
          shipsToDeploySimplified.add(shipSize);
          shipsQuantiiesToDisplay.add(quantity);
          currentPlayerDeployProgress += shipSize;
        }
      }
      print('==============================================');
      print('Succesfully reversed Map to its initial state!');
      print('==============================================');
    });
  }

  void exitGame() {
    clearMapResetDeploy();
    mapTiles.clear();
    _exitRequested = false;
    greenTiles.clear();
    thisShipPlacedTiles = 0;
    idbase = 1;

    mapside = 4;
    myCustomGameSettings.computerDifficulty = ComputerDifficulty.notSet;
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

  MapTile randomSelect() {
    final random = math.Random();
    int randomIndex = random.nextInt(availableTiles.length);
    MapTile selectedTile = availableTiles[randomIndex];

    gridTapPlaceShipTile(selectedTile);

    return selectedTile;
  }

  void autoDeploy() {
    print('----------------------> auto deploy');
    int failCount = 0;
    const int failLimit = 10;
    final random = math.Random();

    // randomSelect(); // clicks on first tile (of corresponding ship) on the map
    setState(() {
      while (shipsToDeploySimplified.isNotEmpty) {
        MapTile firstTile =
            randomSelect(); // clicks on first tile (of corresponding ship) on the map
        print('first tile = ${firstTile.alfaAdress}');
        for (int i = 0; i < widget.currentPlayer.ships[n].tiles; i++) {
          int previousIterationDeployProgress = currentPlayerDeployProgress;

          // if the ship is larger than 1-tile continue clicking on suggested green tiles
          if (greenTiles.isNotEmpty) {
            int randomGreenTileIndex = random.nextInt(greenTiles.length);
            gridTapPlaceShipTile(greenTiles[randomGreenTileIndex]);
          } else {
            print(
              'Finished deploying a ship. (No green tiles found.) Moving on to the random selection of the first tile for the next ship deployment.',
            );
            break;
          }

          int thisIterationDeployProgress = currentPlayerDeployProgress;
          // this and previous count relate to shipsToDeploySimplified list, if both values are the same it means that no tile was placed during the whole iteration - likely something went wrong so rising error
          if (previousIterationDeployProgress == thisIterationDeployProgress) {
            print(
              'No tiles were placed in this iteration. Likely invalid placement. Aborting auto-deploy.',
            );
            deployError = true;
            break;
          }
        }
        if (deployError) {
          print('error in auto-deploy');
          // clearMapResetDeploy();
          deployError = false;
          // autoDeploy();
          break;
        }
        failCount++;
        if (failCount == failLimit) {
          print(
            'Aborting auto-deploy! error code: "($failCount/$failLimit) failed attempts!"',
          );
          clearMapResetDeploy();
          autoDeploy();
          break;
        }
      }
      widget.currentPlayer.isReady = true;
      reverseBlockedTilesBackToWaterStatus();
    });
  }

  void reverseBlockedTilesBackToWaterStatus() {
    for (MapTile tile in mapTiles) {
      if (tile.status == TileStatus.blocked) {
        tile.status = TileStatus.water;
      }
    }
    // mapTilesNotifier.value = List.from(mapTiles); // triggers UI update
  }

  String displayShipsToDeploy(Ship ship) {
    String shipDisplayOutput =
        ('  ') + ship.shipName + (' (${ship.tiles} tiles) ');

    return shipDisplayOutput;
  }

  @override
  Widget build(BuildContext context) {
    // final currentPlayer = widget.currentPlayer;

    return PopScope(
      canPop: false,

      child: Scaffold(
        appBar: AppBar(
          title: Text(
            coverComputerDeploy
                ? ''
                : 'Deploy Your ${widget.currentPlayer.fraction!.name.display}',
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
          backgroundColor: playerColor,
          leading: Icon(
            coverComputerDeploy ? null : playerIcon,
            color: Colors.black,
            size: 35,
          ),
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
        bottomNavigationBar:
            coverComputerDeploy
                ? null
                : BottomAppBar(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => clearMapResetDeploy(),
                        icon: Icon(Icons.deselect_sharp),
                        label: Text('clear map'),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(
                              width: 2,
                              color: Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => autoDeploy(),
                        icon: Icon(Icons.auto_fix_high_outlined),
                        label: Text('auto deploy'),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(
                              width: 2,
                              color: Colors.grey[300]!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        body: Stack(
          children: [
            Column(
              children: [
                // debug display for players' avatars
                // SizedBox(
                //   height: 30,
                //   width: 300,
                //   child: ListView.builder(
                //     itemCount: myCustomGameSettings.players.length,
                //     scrollDirection: Axis.horizontal,
                //     itemBuilder: (context, index) {
                //       return Container(
                //         height: 30,
                //         width: 30,
                //         color:
                //             myCustomGameSettings.players[index].avatar.background,
                //         child: Icon(
                //           myCustomGameSettings.players[index].avatar.icon,
                //         ),
                //       );
                //     },
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: ValueListenableBuilder<List<MapTile>>(
                      valueListenable: mapTilesNotifier,
                      builder: (context, tiles, _) {
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: mapside,
                                crossAxisSpacing: 1,
                                mainAxisSpacing: 1,
                              ),
                          itemCount: mapTiles.length,
                          itemBuilder: (context, index) {
                            final tile = mapTiles[index];
                            return GestureDetector(
                              onTap: () {
                                MapTile clickedTile = indexToMaptile(index);
                                gridTapPlaceShipTile(clickedTile);
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                alignment: Alignment.center,
                                color: getTileColor(tile.status),
                                child: Column(
                                  children: [
                                    Text(
                                      tile.alfaAdress, //A4, B2, C3....
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: tile.adresColor),
                                    ),
                                    // Text(
                                    //   tile.x.toString() + (':') + tile.y.toString(),
                                    //   textAlign: TextAlign.center,
                                    //   style: TextStyle(color: tile.adresColor),
                                    // ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 10),
                Text(
                  n < currentPlayerShipsOriginal.length
                      ? 'Your ships to deploy on the map:'
                      : 'All ships ready!',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 5),
                DeploymentListOrContinueButton(
                  currentPlayer: widget.currentPlayer,
                  onContinue: () {
                    autoDeploy();
                  },
                ),
              ],
            ),
            if (coverComputerDeploy)
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 50,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 70),
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.currentPlayer.avatar.background,
                            ),
                            child: Icon(
                              widget.currentPlayer.avatar.icon,
                              size: 50,
                            ),
                          ),
                          SizedBox(height: 30),
                          Text(
                            widget.currentPlayer.playerName,
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Text(
                          //   widget.currentPlayer.fraction!.name.display,
                          //   style: TextStyle(fontSize: 13),
                          // ),
                          // fraction is not revealed in order not to give second player any advantage.
                          // could be shown if enemy fraction is selected, otherwise 'random'
                          SizedBox(height: 40),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              autoDeploy();
                              randomSelect();
                              Player newCurrentHumanPlayer = Player(
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
                                isComputer: false,
                              );
                              myCustomGameSettings.players.add(
                                newCurrentHumanPlayer,
                              );
                              prepareMapToDeployNextPlayer();

                              PreGameManager pregameManager = PreGameManager(
                                myCustomGameSettings,
                                newCurrentHumanPlayer,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return CustomPlayerIntroduction(
                                      settings: pregameManager,
                                      currentPlayer: newCurrentHumanPlayer,
                                    );
                                  },
                                ),
                              );
                            },
                            label: Text(
                              'confirm enemy',
                              style: TextStyle(color: Colors.white),
                            ),
                            icon: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: BorderSide(
                                  width: 2,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              backgroundColor: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DeploymentListOrContinueButton extends StatefulWidget {
  final Player currentPlayer;
  final VoidCallback onContinue;
  const DeploymentListOrContinueButton({
    super.key,
    required this.currentPlayer,
    required this.onContinue,
  });

  @override
  State<DeploymentListOrContinueButton> createState() {
    return _DeploymentListOrContinueButton();
  }
}

class _DeploymentListOrContinueButton
    extends State<DeploymentListOrContinueButton> {
  @override
  Widget build(BuildContext context) {
    if (n < currentPlayerShipsOriginal.length) {
      return Expanded(
        child: ListView.builder(
          itemCount: currentPlayerShipsOriginal.length,
          itemBuilder: (context, index) {
            final shipCurrentlyDeployed = widget.currentPlayer.ships[n];
            final shipInQueue = widget.currentPlayer.ships[index];
            if (index != n) {
              // ships already deployed or waiting for deployment are displayed in grey
              return ListTile(
                title: Row(
                  children: [
                    Container(color: Colors.blueGrey),
                    Text('${(index + 1).toString()}.        '),
                    Text(
                      shipInQueue.shipName + (' (${shipInQueue.tiles} tiles) '),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            } else {
              // Currently deployed ship is highlighted
              return Container(
                height: 50,
                color: playerColor, // Highlight color

                child: Row(
                  children: [
                    Container(color: playerColor),
                    Icon(Icons.arrow_forward_ios),
                    SizedBox(width: 30),
                    Text(
                      shipCurrentlyDeployed.shipName +
                          (' (${shipsToDeploySimplified[0]} tiles) '),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.all(70),
        child: ElevatedButton.icon(
          icon: Icon(Icons.check_rounded, color: Colors.white),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
              side: BorderSide(width: 2, color: Colors.blueGrey),
            ),
            backgroundColor: Colors.blueGrey,
          ),
          label: Text(
            'Save and continue!',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            widget.currentPlayer.isReady = true;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  if (myCustomGameSettings.gameMode == GameMode.computer) {
                    final bothPlayersReady =
                        myCustomGameSettings.players[0].isReady &&
                        myCustomGameSettings.players[1].isReady;
                    if (bothPlayersReady) {
                      return GamePage(
                        myCustomGameSettings,
                        myCustomGameSettings.players[0],
                        myCustomGameSettings.players[1],
                      );
                    } else {
                      Player newCurrentHumanPlayer = Player(
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
                        isComputer: false,
                      );
                      myCustomGameSettings.players.add(newCurrentHumanPlayer);
                      prepareMapToDeployNextPlayer();

                      PreGameManager pregameManager = PreGameManager(
                        myCustomGameSettings,
                        newCurrentHumanPlayer,
                      );
                      return CustomPlayerIntroduction(
                        settings: pregameManager,
                        currentPlayer: newCurrentHumanPlayer,
                      );
                    }
                  } else if (myCustomGameSettings.gameMode == GameMode.pvp) {
                    if (myCustomGameSettings.players.length < 2) {
                      Player newCurrentHumanPlayer = Player(
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
                        isComputer: false,
                      );
                      myCustomGameSettings.players.add(newCurrentHumanPlayer);
                      prepareMapToDeployNextPlayer();

                      PreGameManager pregameManager = PreGameManager(
                        myCustomGameSettings,
                        newCurrentHumanPlayer,
                      );
                      return CustomPlayerIntroduction(
                        settings: pregameManager,
                        currentPlayer: newCurrentHumanPlayer,
                      );
                    }
                    final bothPlayersReady =
                        myCustomGameSettings.players[0].isReady &&
                        myCustomGameSettings.players[1].isReady;
                    if (bothPlayersReady) {
                      return GamePage(
                        myCustomGameSettings,
                        myCustomGameSettings.players[0],
                        myCustomGameSettings.players[1],
                      );
                    } else {
                      Player newCurrentHumanPlayer = Player(
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
                        isComputer: false,
                      );
                      myCustomGameSettings.players.add(newCurrentHumanPlayer);
                      prepareMapToDeployNextPlayer();

                      PreGameManager pregameManager = PreGameManager(
                        myCustomGameSettings,
                        newCurrentHumanPlayer,
                      );
                      return CustomPlayerIntroduction(
                        settings: pregameManager,
                        currentPlayer: newCurrentHumanPlayer,
                      );
                    }
                  } else {
                    return PopScope(
                      canPop: false,
                      child: Scaffold(
                        body: Center(
                          child: Column(
                            children: [
                              Text(
                                "Game loading error!",
                                style: TextStyle(fontSize: 19),
                              ),
                              IconButton(
                                onPressed: () {
                                  exitGame();
                                },
                                icon: Icon(Icons.do_disturb),
                              ),
                              Text('try again'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      );
    }
  }
}
