﻿#target photoshop// examples:=================== var txt = "Current group: " + getCurrentGroup() + ". Count: "  + getCountsInGroup(getCurrentGroup()).length + "." ;alert(txt);// getting the counts for the current selected groupsaveTxt (txt);  //getCountsInGroup(0);//get counts for the first group// ===================================function getCountsInGroup( idx ){    var cArr = listCountsArr();    return cArr[idx];}  function getCurrentGroup(){// find the index of the selected group      var firstArr = listCountsArr();// make a list with arrays as grpoups and inside them objects for each count      addTempCount();// create a temp cont      var secArr = listCountsArr();// make a second list      theCGroup = 0;      for( i=0; i<firstArr.length; i++){// compare the listCountsArr        if( firstArr[i].length != secArr[i].length){            theCGroup = i;            break;        }      }      deleteCount( secArr[theCGroup][secArr[theCGroup].length - 1].idx + 1);// detele the temp count      return theCGroup;}function addTempCount(){      var desc = new ActionDescriptor();      desc.putDouble( charIDToTypeID( "X   " ), 0 );      desc.putDouble( charIDToTypeID( "Y   " ), 0 );      executeAction( stringIDToTypeID( "countAdd" ), desc, DialogModes.NO );}function deleteCount( idx ){      var desc = new ActionDescriptor();      desc.putInteger( charIDToTypeID( "ItmI" ), idx );      executeAction( stringIDToTypeID( "countDelete" ), desc, DialogModes.NO );}function listCountsArr(){      var cArr = new Array();      var ref = new ActionReference();      ref.putEnumerated( charIDToTypeID("Dcmn") , charIDToTypeID( "Ordn" ), charIDToTypeID( "Trgt" ) );      desc1 = executeActionGet(ref);      desc1 = desc1.getList(stringIDToTypeID('countClass'));      var crntG = 0;      var grpArr = new Array();      for(var i = 0; i<desc1.count; i++){            var gr = desc1.getObjectValue(i).getInteger(charIDToTypeID("Grup"));            var itI = desc1.getObjectValue(i).getInteger(charIDToTypeID("ItmI"));            var itX = desc1.getObjectValue(i).getUnitDoubleValue(charIDToTypeID("X   "));            var itY = desc1.getObjectValue(i).getUnitDoubleValue(charIDToTypeID("Y   "));            var cntObj = {idx:itI, x:itX, y:itY, grpIDX:gr, domI: i};            if(crntG == gr ){                  grpArr.push(cntObj);            }            if(crntG != gr ){                  cArr.push(grpArr);                  grpArr = new Array();                  grpArr.push(cntObj);                  crntG = gr;            }       }       cArr.push(grpArr);       return cArr;}function saveTxt(txt){    var Name = app.activeDocument.name.replace(/\.[^\.]+$/, '');    var Ext = decodeURI(app.activeDocument.name).replace(/^.*\./,'');    if (Ext.toLowerCase() != 'psd'){        return;    }    var Path = app.activeDocument.path;    var saveFile = File(Path + "/" + Name +".txt");    if(saveFile.exists){        saveFile.remove();    }    saveFile.encoding = "UTF8";    saveFile.open("e", "TEXT", "????");    saveFile.writeln(txt);    saveFile.close();}