function Game() {
  let id = parseInt(document.querySelector('#game_id').innerHTML);
  this.getGameDataUrl = '/games/' + id + '/get_data';
  this.postGameDataUrl = '/games/' + id + '/send_data';
  this.status = "pending";
  this.playerGrid = null;
  this.enemyGrid = null;
  this.misses = [];
  this.nextShipName = "";
  this.shipsDeployed = 0;
  this.postDeployment = false;
  this.allowMove = false;
  this.currentPlayerName = "";
  this.winnerName = "";

  this.deploymentGridId = null;
  this.playerGridId = null;
  this.enemyGridId = null;
  this.spanInfo1 = document.querySelector('span#info1');
  this.pDirection = document.querySelector('p#direction');
  this.spanNextShip = document.querySelector('span#next_ship');
  this.spanMisses = document.querySelector('span#misses');

  var Game = this;
  var fieldClicked = false;

  this.initializeGame = function() {
    enableMainInterval();
  }

  function enableMainInterval() {
    Game.mainIntervalId = setInterval(function fwGetGameData() {
      getGameData();
      return fwGetGameData;
    }(), 2000);
  }

  function getGameData() {
    $.get(Game.getGameDataUrl, function(data) {
      Game.status = data['status'];
      Game.playerGrid = data['player_grid'];
      Game.enemyGrid = data['enemy_grid'];
      Game.misses = data['misses'];

      if (Game.status == "deployment") {
        Game.nextShipName = data['status_params']['deployment']['next_ship_name'];
        Game.shipsDeployed = parseInt(data['status_params']['deployment']['ships_deployed']);
        gameStatusDeployment();
      } else if (Game.status == "started") {
        Game.allowMove = data['status_params']['started']['allow_move'];
        Game.currentPlayerName = data['status_params']['started']['current_player_name'];
        gameStatusStarted();
      } else if (Game.status == "ended") {
        Game.winnerName = data['status_params']['ended']['winner_name'];
        gameStatusEnded();
      }
    });
  }

  function gameStatusDeployment() {
    if (Game.shipsDeployed < 10) {
      clearInterval(Game.mainIntervalId);
    }

    if (Game.deploymentGridId == null) {
      buildDeploymentGrid();
      Game.spanInfo1.innerHTML = "Commanders, deploy your ships!";
      Game.pDirection.style = "display: inline;";
    }
    updateGrid(Game.deploymentGridId, Game.playerGrid);
    maximumShipsCount();
  }

  function maximumShipsCount() {
    if (Game.shipsDeployed < 10) {
      displayNextShipName();
    } else {
      allShipsDeployed();
    }
  }

  function displayNextShipName() {
    Game.spanNextShip.innerHTML = "Ship #" + (Game.shipsDeployed + 1) + ": " + Game.nextShipName;
  }

  function allShipsDeployed() {
    Game.spanInfo1.innerHTML = "Wait for second player to deploy ships";
    Game.pDirection.style = "display: none;";
    Game.spanNextShip.style = "display: none;";

    if (!Game.postDeployment && Game.status == "deployment") {
      clearInterval(Game.mainIntervalId);
      Game.postDeployment = true;
      enableMainInterval();
    }
  }

  function buildDeploymentGrid() {
    Game.deploymentGridId = buildGrid(10, 10, 'clickableGrid', deploymentClickCallback);
    Game.deploymentGridId.setAttribute("id", "deployment");
    document.body.appendChild(Game.deploymentGridId);
  }

  function deploymentClickCallback(field, row, col) {
    if (fieldClicked || Game.shipsDeployed == 10) {
      return;
    }

    styleClickedField(field);
    let dir = $('input[name="direction"]:checked').val();
    let newRow = row + 1;
    let newCol = col + 1;

    $.post(Game.postGameDataUrl, { row: newRow, col: newCol, direction: dir }, function(data) {
      if (data['return_value'] == false) {
        printMessage("You can't deploy your ship here");
        return;
      }

      Game.status = data['status'];
      Game.shipsDeployed = parseInt(data['ships_deployed']);
      updateGrid(Game.deploymentGridId, data['player_grid']);
      getGameData();
      maximumShipsCount()
    }, "json");
  }

  function gameStatusStarted() {
    if (Game.enemyGridId == null && Game.playerGridId == null) {
      clearInterval(Game.mainIntervalId);
      Game.spanInfo1.innerHTML = "Game started!";
      removeDeploymentGrid();

      $(Game.spanInfo1).fadeOut(1000, function() {
        buildEnemyGrid();
        buildPlayerGrid();
        enableMainInterval();
      });
    } else {
      displayInfo(Game.currentPlayerName);
      displayMisses(Game.misses);
      updateGrid(Game.enemyGridId, Game.enemyGrid);
      updateGrid(Game.playerGridId, Game.playerGrid);
    }
  }

  function displayInfo(name) {
    Game.spanInfo1.innerHTML = "Current turn: " + name;
    Game.spanInfo1.style = "display: inline;";
  }

  function displayMisses(misses) {
    Game.spanMisses.innerHTML = "<br>Your misses: " + Game.misses[0] + "<br>Enemy misses: " + Game.misses[1];
  }

  function removeDeploymentGrid() {
    let grid = document.querySelector('#deployment');
    if (grid) {
      grid.parentNode.removeChild(grid);
    }
  }

  function buildEnemyGrid() {
    Game.enemyGridId = buildGrid(10, 10, 'clickableGrid', startedGameClickCallback);
    document.body.appendChild(Game.enemyGridId);
  }

  function startedGameClickCallback(field, row, col) {
    let str = '[' + (row + 1) + ', ' + (col + 1) + ']';

    if (fieldClicked || Game.enemyGrid[str] == "miss" || Game.enemyGrid[str] == "hit" ||
      Game.status == "ended" || !Game.allowMove) {

      return;
    }

    Game.allowMove = false;
    styleClickedField(field);
    let newRow = row + 1;
    let newCol = col + 1;
    enemyGridClick(newRow, newCol);
  }

  function enemyGridClick(row, col) {
    $.post(Game.postGameDataUrl, { row: row, col: col }, function(data) {
      printMessage(data['message']);
      getGameData();
    }, "json");
  }

  function gameStatusEnded() {
    clearInterval(Game.mainIntervalId);

    if (Game.enemyGridId == null) {
      buildEnemyGrid();
      buildPlayerGrid();
    }

    updateGrid(Game.enemyGridId, Game.enemyGrid);
    updateGrid(Game.playerGridId, Game.playerGrid);
    Game.spanInfo1.innerHTML = "Game ended! Winner: " + Game.winnerName;
    displayMisses(Game.misses);
  }

  function buildPlayerGrid() {
    Game.playerGridId = buildGrid(10, 10, 'staticGrid');
    document.body.appendChild(Game.playerGridId);
  }

  function styleClickedField(field) {
    field.style = "background-color: red;";
    fieldClicked = true;

    setTimeout(function() {
      clearBackground(field);
    }, 1000);

    function clearBackground(field) {
      field.style = "background-color: inherit;";
      fieldClicked = false;
    }
  }

  function printMessage(message) {
    var p = document.createElement('p');
    p.innerHTML = message;
    document.body.appendChild(p);

    setTimeout(function() {
      p.parentNode.removeChild(p);
    }, 1000)
  }

  function buildGrid(rows, cols, gridClass, callback) {
      var grid = document.createElement('table');
      grid.className = gridClass;

      for (var col = 0; col <= cols; col++) {
        var th = grid.appendChild(document.createElement('th'));
        th.innerHTML = col === 0 ? " " : String.fromCharCode(65 + col - 1);
      }

      for (var row = 0; row < rows; row++) {
          var tr = grid.appendChild(document.createElement('tr'));
          var th = tr.appendChild(document.createElement('th'));
          th.outerHTML = '<th scope="row">' + (row + 1) + '</th>';

          for (var col = 0; col < cols; col++) {
              var field = tr.appendChild(document.createElement('td'));

              if (callback) {
                field.addEventListener('click', (function(field, row, col) {
                    return function() {
                        callback(field, row, col);
                    }
                })(field, row, col), false);
              }
          }
      }

      return grid;
  }

  function updateGrid(grid, data) {
    for (var x = 1; x <= 10; x++) {
      for (var y = 1; y <= 10; y++) {
        var tr = grid.querySelectorAll('tr')[x - 1];
        var td = tr.querySelectorAll('td')[y - 1];
        var string = '[' + x + ', ' + y + ']';

        if (data[string] == 'hit') {
          td.innerHTML = "X";
        } else if (data[string] == 'miss') {
          td.innerHTML = ".";
        } else if (data[string] == 'ship') {
          td.innerHTML = "S";
        } else {
          td.innerHTML = "";
        }
      }
    }
  }
}
