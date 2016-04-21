﻿#target photoshop// examples:=================== //var txt = "Current group: " + getCurrentGroup() + ". Count: "  + getCountsInGroup(getCurrentGroup()).length + "." ;alert("Reading coordinates.");// getting the counts for the current selected group//var c = getCountsInGroup(0);//get counts for the first groupcsv = buildCSV();saveTxt (csv);alert("CSV file saved."); // ==================================================//function buildCSV(){    var cArr = listAllCounts();    var nCounts = cArr.length;    var txt = "";    for(g = 0; g < nCounts; g++){         var point = cArr[g];        var X = point.x;        var Y = point.y;        var grp = point.grpIDX;        var id = point.idx;                     txt = txt + grp + ", " + X + ", " + Y + ", " + id +"\n";     }    return txt;} function listAllCounts(){      var cArr = new Array();      var ref = new ActionReference();      ref.putEnumerated( charIDToTypeID("Dcmn") , charIDToTypeID( "Ordn" ), charIDToTypeID( "Trgt" ) );      desc0 = executeActionGet(ref);      desc1 = desc0.getList(stringIDToTypeID('countClass'));            ncounts = desc1.count;            for(var i = 0; i<ncounts; i++){            var obj = desc1.getObjectValue(i);            var gr = desc1.getObjectValue(i).getInteger(charIDToTypeID("Grup"));            var itI = desc1.getObjectValue(i).getInteger(charIDToTypeID("ItmI"));            var itX = desc1.getObjectValue(i).getUnitDoubleValue(charIDToTypeID("X   "));            var itY = desc1.getObjectValue(i).getUnitDoubleValue(charIDToTypeID("Y   "));            var cntObj = {idx:itI, x:itX, y:itY, grpIDX:gr, domI: i};                        cArr.push(cntObj);      }          return cArr;}function listCountsArr(){      var cArr = new Array();      var ref = new ActionReference();      ref.putEnumerated( charIDToTypeID("Dcmn") , charIDToTypeID( "Ordn" ), charIDToTypeID( "Trgt" ) );      desc0 = executeActionGet(ref);      desc1 = desc0.getList(stringIDToTypeID('countClass'));            ngroups = desc1.count;             var crntG = 0;      var grpArr = new Array();      for(var i = 0; i<ngroups; i++){            var obj = desc1.getObjectValue(i);                      var gr = desc1.getObjectValue(i).getInteger(charIDToTypeID("Grup"));            var itI = desc1.getObjectValue(i).getInteger(charIDToTypeID("ItmI"));            var itX = desc1.getObjectValue(i).getUnitDoubleValue(charIDToTypeID("X   "));            var itY = desc1.getObjectValue(i).getUnitDoubleValue(charIDToTypeID("Y   "));            var cntObj = {idx:itI, x:itX, y:itY, grpIDX:gr, domI: i};            if(crntG == gr ){                  grpArr.push(cntObj);            }            if(crntG != gr ){                  cArr.push(grpArr);                  grpArr = new Array();                  grpArr.push(cntObj);                  crntG = gr;            }       }       cArr.push(grpArr);       return cArr;}function saveTxt(txt){    var Name = app.activeDocument.name.replace(/\.[^\.]+$/, '');    var Ext = decodeURI(app.activeDocument.name).replace(/^.*\./,'');    if (Ext.toLowerCase() != 'psd'){        return;    }    var Path = app.activeDocument.path;    var saveFile = File(Path + "/" + Name +".txt");    if(saveFile.exists){        saveFile.remove();    }    saveFile.encoding = "UTF8";    saveFile.open("e", "TEXT", "????");    saveFile.writeln(txt);    saveFile.close();}