#target photoshop

var ci = app. activeDocument.countItems;
var ind = ci.index;
var l = ci.legth;
var uv0 = new UnitValue(1000, 'px');
var uv1 = new UnitValue(900, 'px');
var uv = [uv0,uv1];
ci.add(uv);
var item = ci[1];
var name  = item.typename;
var item2 = ci[2];

