setTimeout(function duelsCheckTimeout() {
  duelsCheck();
  return setTimeout(duelsCheckTimeout, 10000);
}(), 10000);

function duelsCheck() {
  $.get("/duels/find_new", function(data) {
    if (!data) {
      return;
    }
    
    if (data['duel_id']) {
      let div = document.createElement("div");
      div.innerHTML = getChallengedBody(data['invited_by']);
      document.body.appendChild(div);

      $(function() {
        $("#duel_invite").dialog({
          resizable: false,
          height: "auto",
          width: 360,
          modal: true,
          buttons: {
            "Accept": function() {
              sendUserResponse(this, { duel_id: data['duel_id'], accepted: true }, function(url) {
                window.open(url, "_self");
              });
            },
            "Accept, but no redirection": function() {
              sendUserResponse(this, { duel_id: data['duel_id'], accepted: true });
            },
            "Refuse": function() {
              sendUserResponse(this, { duel_id: data['duel_id'], accepted: false });
            }
          }
        });
      } );
    }

    if (data['response_from'] && data['response_from'].length > 0) {
      let div = document.createElement("div");
      div.innerHTML = getResponseBody(data['response_from'], data['game_url'], data['created_at']);
      document.body.appendChild(div);

      $(function() {
        $("#duel_response").dialog({
          resizable: false,
          height: "auto",
          width: 380,
          modal: false,
          buttons: {
            "Close": function() {
              $(this).dialog("close");
            }
          }
        });
      } );
    }
  });
}

function sendUserResponse(dialog, data, callback) {
  $(dialog).dialog("close");

  $.post("/duels/response", data, function(data) {
    if (callback) {
      callback(data['game_url']);
    }
  }, "json");
}

function getChallengedBody(invited_by) {
  return "<div id='duel_invite' title='You have been challenged for a duel' style='display: none;'>" +
    "Challenged by: <strong class='dialog_nickname'>" + invited_by + "</strong><br>" +
    "Clicking <em>Accept</em> will redirect you to battle room</div>"
}

function getResponseBody(responsed_by, game_url, created_at) {
  if (game_url.length > 0) {
    return "<div id='duel_response' title='Your duel invitation has been accepted' style='display: none;'>" +
      "Accepted by: <strong class='dialog_nickname'>" + responsed_by + "</strong><br>" +
      "Created: <strong class='dialog_date'>" + created_at + "</strong><br><br>" +
      "<a class='duel_url' href=" + game_url + ">Click here to enter battle room</a></div>"
  } else {
    return "<div id='duel_response' title='Your duel invitation has been refused' style='display: none;'>" +
      "Refused by: <strong class='dialog_nickname'>" + responsed_by + "</strong><br>" +
      "Created: <strong class='dialog_date'>" + created_at + "</strong><br></div>"
  }
}
