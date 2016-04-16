var s = countLayers(app.activeDocument);
alert(s.layers.on+"/"+s.layers.all+" layers are visible, " +
      "organized into "+s.groups.on+"/"+s.groups.all+" visible groups.");
      
      
      function countLayers(item,stats){
  var i;
  if (!stats) stats={layers:{on:0,off:0,all:0},groups:{on:0,off:0,all:0}};
  stats.layers.all += (i=item.layers.length);
  while (i--) stats.layers[item.layers[i].visible ? "on" : "off"]++;
  stats.groups.all += (i=item.layerSets.length);
  while (i--){
    stats.groups[item.layerSets[i].visible ? "on" : "off"]++;
    countLayers(item.layerSets[i],stats);
  }
  return stats;
}