function Game() {
  let id = parseInt(document.querySelector('#game_id').innerHTML);
  this.getGameDataUrl = '/games/' + id + '/get_game_data';
  this.postGameDataUrl = '/games/' + id + '/send_game_data';
  this.status = "pending";
  this.playerGrid = null;
  this.enemyGrid = null;
  this.misses = [];
  this.shipsLeft = [];
  this.nextShipName = "";
  this.shipsDeployed = 0;
  this.allowMove = false;
  this.currentPlayerName = "";
  this.attackedField = [];
  this.winnerName = "";

  this.deploymentGridId = null;
  this.playerGridId = null;
  this.enemyGridId = null;
  this.pMainGameInfo = document.querySelector('p#main_game_info');
  this.pDirection = document.querySelector('p#direction');
  this.pNextShipName = document.querySelector('p#next_ship_name');
  this.pClickedFieldInfo = document.querySelector('p#clicked_field_info');
  this.pPlayer1Name = document.querySelector('p#player1_name');
  this.pPlayer2Name = document.querySelector('p#player2_name');
  this.spanPlayer1Info = document.querySelector('span#player1_info');
  this.spanPlayer2Info = document.querySelector('span#player2_info');
  this.divGameArea = document.querySelector('#game_area');
  this.divComments = document.querySelector('.comments_body');
  this.commentsCount = 0;

  var Game = this;
  var fieldClicked = false;

  this.initializeGame = function() {
    enableMainInterval();
    addEventListenerForChatInput();
  }

  function enableMainInterval() {
    setInterval(function fwGetGameData() {
      getGameData();
      return fwGetGameData;
    }(), 1500);
  }

  function addEventListenerForChatInput() {
    document.querySelector("#chat_form").addEventListener("submit", function(e) {
      e.preventDefault();
      let chatInput = document.querySelector("#chat_input");
      let inputValue = chatInput.value;

      if (!inputValue.length) {
        return;
      }

      chatInput.value = "";
      $.post(Game.postGameDataUrl, { comment: inputValue }, function(data) {
        getGameData();
      }, "json");
    })
  }

  function getGameData() {
    $.get(Game.getGameDataUrl, function(data) {
      Game.status = data['status'];
      Game.playerGrid = data['player_grid'];
      Game.enemyGrid = data['enemy_grid'];
      Game.misses = data['misses'];
      Game.shipsLeft = data['ships_left'];
      checkPlayer2Name(data['player2_name']);
      printComments(data['comments']);

      if (Game.status == "pending") {
        Game.pMainGameInfo.innerHTML = "Waiting for opponent...";
      } else if (Game.status == "deployment") {
        Game.nextShipName = data['status_params']['deployment']['next_ship_name'];
        Game.shipsDeployed = parseInt(data['status_params']['deployment']['ships_deployed']);
        gameStatusDeployment();
      } else if (Game.status == "started") {
        Game.allowMove = data['status_params']['started']['allow_move'];
        Game.currentPlayerName = data['status_params']['started']['current_player_name'];
        Game.attackedField = data['status_params']['started']['attacked_field'];
        gameStatusStarted();
      } else if (Game.status == "ended") {
        Game.winnerName = data['status_params']['ended']['winner_name'];
        gameStatusEnded();
      }
    });
  }

  function checkPlayer2Name(name) {
    if (name) {
      Game.pPlayer2Name.innerHTML = name;
    }
  }

  function gameStatusDeployment() {
    if (Game.deploymentGridId == null) {
      enableDirectionButtons();
      buildDeploymentGrid();
      Game.pMainGameInfo.innerHTML = "Commanders, deploy your ships!";
      $(Game.pMainGameInfo).hide().slideDown(1250);
      $(Game.pNextShipName).slideDown(1250);
    }
    updateGrid(Game.deploymentGridId, Game.playerGrid);
    directionKeyboardCheck();
    maximumShipsCount();
  }

  function directionKeyboardCheck() {
    if (Game.shipsDeployed >= 6) {
      let clickedDirection = document.querySelector('button.highlighted_field');
      if (clickedDirection) {
        clickedDirection.classList.remove('highlighted_field');
      }
    }
  }

  function maximumShipsCount() {
    if (Game.shipsDeployed < 10) {
      displayNextShipName();
    } else {
      allShipsDeployed();
    }
  }

  function displayNextShipName() {
    Game.pNextShipName.innerHTML = "Ship #" + (Game.shipsDeployed + 1) + ": " + Game.nextShipName + "<br>";
  }

  function allShipsDeployed() {
    Game.pMainGameInfo.innerHTML = "Waiting for second player ships deployment";
    Game.pNextShipName.style = "display: none;";
  }

  function enableDirectionButtons() {
    let buttons = document.querySelectorAll('.btn-direction');
    buttons[0].classList.add("highlighted_field");

    for (let i = 0; i < buttons.length; i++) {
      buttons[i].addEventListener("click", function() {
        if (Game.shipsDeployed >= 6) {
          return;
        }

        let previouslyClickedButton = document.querySelector('button.highlighted_field');
        this.classList.add('highlighted_field');

        if (this != previouslyClickedButton) {
          previouslyClickedButton.classList.remove('highlighted_field');
        }
      })
    }
  }

  function buildDeploymentGrid() {
    Game.deploymentGridId = buildGrid(10, 10, 'clickableGrid', deploymentClickCallback);
    Game.deploymentGridId.setAttribute("id", "deployment");
    $(Game.deploymentGridId).hide().fadeIn(1250);
    $(Game.pDirection).hide().fadeIn(1250);
  }

  function deploymentClickCallback(field, row, col) {
    if (fieldClicked || Game.shipsDeployed == 10) {
      return;
    }

    let directionButton = document.querySelector('button.highlighted_field') || []
    let dir = directionButton.value || "up";
    let newRow = row + 1;
    let newCol = col + 1;

    $.post(Game.postGameDataUrl, { row: newRow, col: newCol, direction: dir }, function(data) {
      if (data['return_value'] == false) {
        printMessage("Ship can not be deployed here");
        return;
      }

      Game.status = data['status'];
      Game.shipsDeployed = parseInt(data['ships_deployed']);
      updateGrid(Game.deploymentGridId, data['player_grid']);
      highlightShipFields(row, col, dir, data['ship_parts']);
      getGameData();
      maximumShipsCount()
    }, "json");
  }

  function highlightShipFields(row, col, dir, shipParts) {
    let rowMod = 0, colMod = 0;

    switch (dir) {
      case "up":
        rowMod = -1, colMod = 0;
        break;
      case "right":
        rowMod = 0, colMod = 1;
        break;
      case "down":
        rowMod = 1, colMod = 0;
        break;
      case "left":
        rowMod = 0, colMod = -1;
        break;
    }

    for (let i = 0; i < shipParts; i++) {
      let temp_row = row + rowMod * i, temp_col = col + colMod * i;
      let temp_field = Game.deploymentGridId.querySelectorAll('tr')[temp_row].querySelectorAll('td')[temp_col];
      styleClickedField(temp_field);
    }
  }

  function gameStatusStarted() {
    if (Game.enemyGridId == null && Game.playerGridId == null) {
      Game.pClickedFieldInfo.innerHTML = "Game started, make the ships dive!";
      $(Game.pClickedFieldInfo).hide().slideDown(1250);
      removeDeploymentGUI();
      buildGrids();
      gameStatusStarted();
      $(Game.spanPlayer1Info).hide().slideDown(1250);
      $(Game.spanPlayer2Info).hide().slideDown(1250);
      $(Game.pMainGameInfo).hide().fadeIn(1250);
    } else {
      displayInfo();
      displayPlayersInfo();
      updateGrids()
      highlightPlayersAttackedField();
    }
  }

  function buildGrids() {
    buildEnemyGrid();
    buildPlayerGrid();
  }

  function updateGrids() {
    updateGrid(Game.enemyGridId, Game.enemyGrid);
    updateGrid(Game.playerGridId, Game.playerGrid);
  }

  function displayInfo() {
    Game.pMainGameInfo.innerHTML = "Current turn:<strong> " + Game.currentPlayerName + "</strong>";
    highlightCurrentPlayer();
  }

  function highlightCurrentPlayer() {
    if (Game.pPlayer2Name.innerHTML == Game.currentPlayerName) {
      Game.pPlayer2Name.className = "players_turn_border";
      Game.pPlayer1Name.className = "";
    } else {
      Game.pPlayer1Name.className = "players_turn_border";
      Game.pPlayer2Name.className = "";
    }
  }

  function displayPlayersInfo() {
    Game.spanPlayer1Info.innerHTML = "Ships left: " + Game.shipsLeft[0] + "<br>Misses: " + Game.misses[0];
    Game.spanPlayer2Info.innerHTML = "Ships left: " + Game.shipsLeft[1] + "<br>Misses: " + Game.misses[1];
  }

  function highlightPlayersAttackedField() {
    if (Game.attackedField.length) {
      let row = parseInt(Game.attackedField[0]) - 1;
      let col = parseInt(Game.attackedField[1]) - 1;
      let temp_field = Game.playerGridId.querySelectorAll('tr')[row].querySelectorAll('td')[col];
      styleClickedField(temp_field, "attacked_field");
    }
  }

  function removeDeploymentGUI() {
    let grid = document.querySelector('#deployment');
    if (grid) {
      grid.parentNode.removeChild(grid);
    }
    Game.pDirection.style = "display: none;";
  }

  function buildEnemyGrid() {
    Game.enemyGridId = buildGrid(10, 10, 'clickableGrid', startedGameClickCallback);
    $(Game.enemyGridId).hide().slideDown(1250);
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
      printMessage(data['message'], "important");
      getGameData();
    }, "json");
  }

  function gameStatusEnded() {
    Game.pMainGameInfo.innerHTML = "Game ended! Winner: " + Game.winnerName;
    Game.pMainGameInfo.classList.add('important');

    if (Game.enemyGridId == null) {
      buildGrids();
      $(Game.pMainGameInfo).hide().slideDown(1250);
    }

    updateGrids();
    displayPlayersInfo();
  }

  function buildPlayerGrid() {
    Game.playerGridId = buildGrid(10, 10, 'staticGrid');
    $(Game.playerGridId).hide().slideDown(1250);
  }

  function styleClickedField(field, classname = "highlighted_field") {
    field.classList.add(classname);
    fieldClicked = true;

    setTimeout(function() {
      clearBackground(field, classname);
    }, 1000);

    function clearBackground(field, classname) {
      field.classList.remove(classname);
      fieldClicked = false;
    }
  }

  function printMessage(message, classname) {
    Game.pClickedFieldInfo.innerHTML = message;
    if (classname) {
      Game.pClickedFieldInfo.classList.add(classname);
    }

    setTimeout(function() {
      Game.pClickedFieldInfo.innerHTML = "";
      if (classname) {
        Game.pClickedFieldInfo.classList.remove(classname);
      }
    }, 1500)
  }

  function printComments(comments) {
    let commentsLength = comments.length;

    if (Game.commentsCount == commentsLength) {
      return;
    }

    let previousCommentsCount = Game.commentsCount;
    Game.commentsCount = commentsLength;
    Game.divComments.innerHTML = "";

    for (let i = 0; i < commentsLength; i++) {
      let strTime = (new Date(comments[i]['created_at'])).toTimeString();
      let time = strTime.substr(0, strTime.indexOf(' '));
      let p = document.createElement('p');

      p.innerHTML = "<strong>" + comments[i]['nickname'] + "</strong> " + time + "<br>" + comments[i]['message'];
      Game.divComments.appendChild(p);

      if (previousCommentsCount && i < commentsLength - previousCommentsCount) {
        $(p).hide().slideDown(400);
      }
    }
  }

  function buildGrid(rows, cols, gridClass, callback, callback2) {
      var grid = document.createElement('table');
      grid.style = "align: center;";
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
              field.classList.add("field");

              if (callback) {
                field.addEventListener('click', (function(field, row, col) {
                    return function() {
                        callback(field, row, col);
                    }
                })(field, row, col), false);
              }
          }
      }

      Game.divGameArea.appendChild(grid);
      return grid;
  }

  function updateGrid(grid, data) {
    for (var x = 1; x <= 10; x++) {
      for (var y = 1; y <= 10; y++) {
        var tr = grid.querySelectorAll('tr')[x - 1];
        var td = tr.querySelectorAll('td')[y - 1];
        var string = '[' + x + ', ' + y + ']';

        if (data[string] == 'hit') {
          td.classList.add("hit");
        } else if (data[string] == 'miss') {
          td.classList.add("miss");
        } else if (data[string] == 'ship') {
          td.classList.add("ship");
        } else {
          td.innerHTML = "";
        }
      }
    }
  }
}
