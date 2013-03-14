jQuery(document).ready(function() {
  window.i = 0;
  $.history.init(pageload);
});

function pageload() {
  getHash();
}

function getHash() {
  $.getJSON("/api/report", null, function(data) {
    if (data != null) {
      $.each(data, function(index, item) {
        window.i++;
        hash = Base64.encode(JSON.stringify(item));
        window.timeperiod = String(item["time"]["from"]) + "--" + String(item["time"]["to"])
        var jlink = $('<a/>').addClass('jlink').attr('href', "../#" + hash).html($('<i/>').addClass('icon-link'));
        var linkTableData = $("<td/>").css('white-space', 'nowrap');
        //add screenshot here
        //var path = getScreenShot(hash,window.i);
        var path = "images/thumbnail.png";
        var thumbnail = $('<img/>').addClass('thumbnail').attr('src',path);
        linkTableData.append(thumbnail).prepend(jlink);
        var tableRow = $("<tr/>").append(linkTableData);
        tableRow.append($("<td/>").text(item["search"]));
        var mode = item["mode"];
        if (mode == "") {
          mode = "default";
        }
        tableRow.append($("<td/>").text(mode));
        $("#reportsreenshot tbody").prepend(tableRow);
      });
      $('#reporttimeframe h4').text("Scheduled Report for " + window.timeperiod);
      $('#reportsreenshot thead').append($("<th/>").text("ScreenShot"));
      $('#reportsreenshot thead').append($("<th/>").text("Query"));
      $('#reportsreenshot thead').append($("<th/>").text("Mode"))
    }
    else {
      $('#reportsreenshot').html('<tr><td>No restored scheduled search</td></tr>');
    }
  });
}
