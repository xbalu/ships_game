function Game() {
  var Game = this;
  this.id = parseInt(document.querySelector('#game_id').innerHTML);
  this.getGameDataUrl = '/games/' + this.id + '/get_data';
  this.postGameDataUrl = '/games/' + this.id + '/send_data';
  this.status = "";
  this.shipsCount = 0;
  this.spanInfo1 = document.querySelector('span#info1');
  this.pDirection = document.querySelector('p#direction');
  this.spanNextShip = document.querySelector('span#next_ship');

  this.initializeGame = function() {
    checkGameStatus();
    this.mainIntervalId = setInterval(checkGameStatus, 2000);
  }

  function checkGameStatus() {
    $.get(Game.getGameDataUrl, function(data) {
      Game.status = data['status'];
      Game.shipsCount = data['ships_count'];

      if (Game.status == "deployment") {
        Game.spanInfo1.innerHTML = "Commanders, deploy your ships!";
        shipsDeploymentPhase();
      } else {
        waitForStart();
      }
    });
  }

  function shipsDeploymentPhase() {
    clearInterval(Game.mainIntervalId);
    buildDeploymentGrid();
    Game.pDirection.style = "display: inline;";
    displayNextShip();
  }

  function displayNextShip() {
    $.get(Game.getGameDataUrl, function(data) {
      if (Game.shipsCount < 10) {
        Game.spanNextShip.innerHTML = "Ship #" + (Game.shipsCount + 1) + ": " + data['next_ship_name'];
      } else {
        Game.spanInfo1.innerHTML = "Wait for second player to deploy ships";
        Game.pDirection.style = "display: none;";
        Game.spanNextShip.style = "display: none;";
        waitForStart();
        Game.mainIntervalId = setInterval(waitForStart, 2000);
      }
    });
  }

  function waitForStart() {
    $.get(Game.getGameDataUrl, function(data) {
      Game.status = data['status'];

      if (Game.status == "started") {
        Game.spanInfo1.innerHTML = "Game has started!";
      }
    });
  }

  var fieldClicked = false;

  function buildDeploymentGrid() {
    var deploymentGrid = buildGrid(10, 10, 'clickableGrid', clickCallback);
    deploymentGrid.setAttribute("id", "deployment");
    document.body.appendChild(deploymentGrid);
    updateDeploymentGrid(deploymentGrid);
  }

  function updateDeploymentGrid(grid) {
    $.get(Game.getGameDataUrl, function(data) {
      updateGrid(grid, data['player_grid']);
    });
  }

  function clickCallback(field, row, col) {
    if (fieldClicked || Game.shipsCount == 10) {
      return;
    }

    field.style = "background-color: red;";
    fieldClicked = true;
    setTimeout(function() {
      clearBackground(field);
    }, 1000);

    function clearBackground(field) {
      field.style = "background-color: inherit;";
      fieldClicked = false;
    }

    let dir = $('input[name="direction"]:checked').val();
    let newRow = row + 1;
    let newCol = col + 1;

    $.post(Game.postGameDataUrl, { row: newRow, col: newCol, direction: dir }, function(data) {
      if (data['return_value'] == false) {
        var p = document.createElement('p');
        p.innerHTML = "You can't deploy your ship here";
        document.body.appendChild(p);
        setTimeout(function() {
          p.parentNode.removeChild(p);
        }, 1000)

        return;
      }

      Game.shipsCount = data['ships_count'];
      displayNextShip();
      updateGrid(document.querySelector('.clickableGrid'), data['player_grid']);
    }, "json");
  }

  function buildGrid(rows, cols, gridClass, callback) {
      var grid = document.createElement('table');
      //grid.style = "float: left; margin: 5px 40px;";
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
    let gridId = grid.getAttribute("id");
    let gridClassName = grid.className;

    for (var x = 1; x <= 10; x++) {
      for (var y = 1; y <= 10; y++) {
        var tr = grid.querySelectorAll('tr')[x - 1];
        var td = tr.querySelectorAll('td')[y - 1];
        var string = '[' + x + ', ' + y + ']';

        if (data[string] == 'hit') {
          td.innerHTML = "X";
        } else if (data[string] == 'miss') {
          td.innerHTML = ".";
        } else if (data[string] == 'ship' && (gridId == "deployment" || gridClassName == "staticGrid")) {
          td.innerHTML = "S";
        } else {
          td.innerHTML = "";
        }
      }
    }
  }
}
