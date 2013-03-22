function form(lat,lon,city,wei,pts,mkrs,wds)
{
        var loc=new google.maps.LatLng(parseFloat(lat),parseFloat(lon));
        var temp={location: loc, weight:parseInt(wei,10)};
        pts.push(temp);
        var contentString = '<div><p><b>City:</b>'+city+'</p><p><b>Access:</b>'+wei+'</p><div>';
        var infowindow = new google.maps.InfoWindow({
                content: contentString,
                position: loc
        });
        var temp_info = new Array();
        temp_info["city"]=city;
        temp_info["weight"]=wei;
        //temp_info["info"]=info;
        var marker = new google.maps.Marker({position: loc});
        wds.push(temp_info);
        mkrs.push(marker)
}

function bindInfoW(map, marker, contentString, infowindow)
{
        google.maps.event.addListener(marker, 'mouseover', function() {
            infowindow.setContent(contentString);
            infowindow.setBackgroundColor('#ddddff')
            infowindow.open(map, marker);
        });
        google.maps.event.addListener(marker, 'mouseout', function() {
            if (infowindow.isOpen()) {
                infowindow.close();
            }
        });
}

function hmp(pts,mkrs,wds) {
    var northAtlanticOcean = new google.maps.LatLng(38.95940879245423,-51.416015625);

    var map = new google.maps.Map(document.getElementById('map_canvas'), {
        center: northAtlanticOcean,
        zoom: 4,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    });

    var heatmap = new google.maps.visualization.HeatmapLayer({
        data: pts,
        gradient: [
                      'rgba(0, 0, 0, 0)',       //black - transparent
                      'rgba(0, 0, 255, 1)',     //blue
                      'rgba(0, 255, 255, 1)',   //cyan
                      'rgba(0, 238, 0, 1)',     //green
                      'rgba(0, 255, 0, 1)',     //lime-green
                      'rgba(255, 255, 0, 1)',   //yellow
                      'rgba(255, 165, 0, 1)',   //orange
                      'rgba(255, 0, 0, 1)',     //red
                      'rgba(139, 0, 0, 1)'      //dark-red
                    ],
        radius: 40 //4 pixels
    });

    heatmap.setMap(map);

    for (var i = 0; i < wds.length; i++){
        var contentString = '<div align="left"><font color="blue"><p><b>City:</b>'+wds[i]["city"]+'</p><p><b>Access:</b>'+wds[i]["weight"]+'</p></font><div>';
        var marker=mkrs[i];
        var infowindow = new InfoBubble();
        bindInfoW(map,marker, contentString, infowindow);
    }
        //var marker = new google.maps.Marker({
        //position: sanFrancisco,
        //map: map
    //});
    //google.maps.event.addListener(marker, 'mouseover', function() {
        //infowindow.open(map,marker);
    //});
    var mcOptions = {gridSize: 50, maxZoom: 15};
    var markerCluster = new MarkerClusterer(map, mkrs, mcOptions);
}
