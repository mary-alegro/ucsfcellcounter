#target Photoshop  
  
var doc = app.activeDocument;  
  
for ( var i = 4; i >= 0; i-- ) { // Just a reverse remove  
  
  var allCounts = doc.countItems.length;  
  
  alert( ' All remaining Counters: ' + allCounts ); // All the doc counts…  
  
  selectCountGroup( i );  
  
  clearCountGroup();  
  
  var newCount = doc.countItems.length;  
  
  var grpCount = allCounts - newCount;  
  
  alert( 'Group ' + ( i + 1 ) + ' Counters: ' + grpCount )  
  
};  
  
// This has NO affect on count its either ALL || NOTHING  
function countGroupVisible() {  
  function cTID(s) { return app.charIDToTypeID(s); };  
  function sTID(s) { return app.stringIDToTypeID(s); };  
  
    var desc130 = new ActionDescriptor();  
    desc130.putBoolean( cTID('Vsbl'), false );  
    executeAction( sTID('countGroupVisible'), desc130, DialogModes.NO );  
};  
  
//  
function selectCountGroup( numb ) {  
  function cTID(s) { return app.charIDToTypeID(s); };  
  function sTID(s) { return app.stringIDToTypeID(s); };  
  
    var desc133 = new ActionDescriptor();  
    desc133.putInteger( cTID('ItmI'), numb );  
    executeAction( sTID('countSetCurrentGroup'), desc133, DialogModes.NO );  
};  
  
//  
function clearCountGroup() {  
  function cTID(s) { return app.charIDToTypeID(s); };  
  function sTID(s) { return app.stringIDToTypeID(s); };  
  
    var desc198 = new ActionDescriptor();  
    executeAction( sTID('countClear'), desc198, DialogModes.NO );  
};  