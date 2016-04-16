

// =======================================================
var idOpn = charIDToTypeID( "Opn " );
    var desc1 = new ActionDescriptor();
    var idnull = charIDToTypeID( "null" );
    desc1.putPath( idnull, new File( "C:\\Users\\malegro\\Documents\\MATLAB\\test_cell.jpg" ) );
executeAction( idOpn, desc1, DialogModes.NO );

// =======================================================
var idcountColor = stringIDToTypeID( "countColor" );
    var desc2 = new ActionDescriptor();
    var idRd = charIDToTypeID( "Rd  " );
    desc2.putInteger( idRd, 253 );
    var idGrn = charIDToTypeID( "Grn " );
    desc2.putInteger( idGrn, 1 );
    var idBl = charIDToTypeID( "Bl  " );
    desc2.putInteger( idBl, 19 );
executeAction( idcountColor, desc2, DialogModes.NO );

// =======================================================
var idcountColor = stringIDToTypeID( "countColor" );
    var desc3 = new ActionDescriptor();
    var idRd = charIDToTypeID( "Rd  " );
    desc3.putInteger( idRd, 253 );
    var idGrn = charIDToTypeID( "Grn " );
    desc3.putInteger( idGrn, 1 );
    var idBl = charIDToTypeID( "Bl  " );
    desc3.putInteger( idBl, 19 );
executeAction( idcountColor, desc3, DialogModes.NO );

// =======================================================
var idcountGroupMarkerSize = stringIDToTypeID( "countGroupMarkerSize" );
    var desc4 = new ActionDescriptor();
    var idSz = charIDToTypeID( "Sz  " );
    desc4.putInteger( idSz, 10 );
executeAction( idcountGroupMarkerSize, desc4, DialogModes.NO );

// =======================================================
var idcountAdd = stringIDToTypeID( "countAdd" );
    var desc5 = new ActionDescriptor();
    var idX = charIDToTypeID( "X   " );
    desc5.putDouble( idX, 618.500000 );
    var idY = charIDToTypeID( "Y   " );
    desc5.putDouble( idY, 162.500000 );
executeAction( idcountAdd, desc5, DialogModes.NO );

// =======================================================
var idcountAdd = stringIDToTypeID( "countAdd" );
    var desc6 = new ActionDescriptor();
    var idX = charIDToTypeID( "X   " );
    desc6.putDouble( idX, 474.500000 );
    var idY = charIDToTypeID( "Y   " );
    desc6.putDouble( idY, 124.500000 );
executeAction( idcountAdd, desc6, DialogModes.NO );

// =======================================================
var idcountAdd = stringIDToTypeID( "countAdd" );
    var desc7 = new ActionDescriptor();
    var idX = charIDToTypeID( "X   " );
    desc7.putDouble( idX, 460.500000 );
    var idY = charIDToTypeID( "Y   " );
    desc7.putDouble( idY, 174.500000 );
executeAction( idcountAdd, desc7, DialogModes.NO );

// =======================================================
var idcountAddGroup = stringIDToTypeID( "countAddGroup" );
    var desc8 = new ActionDescriptor();
    var idNm = charIDToTypeID( "Nm  " );
    desc8.putString( idNm, "Count Group 2" );
executeAction( idcountAddGroup, desc8, DialogModes.NO );

// =======================================================
var idcountColor = stringIDToTypeID( "countColor" );
    var desc9 = new ActionDescriptor();
    var idRd = charIDToTypeID( "Rd  " );
    desc9.putInteger( idRd, 48 );
    var idGrn = charIDToTypeID( "Grn " );
    desc9.putInteger( idGrn, 1 );
    var idBl = charIDToTypeID( "Bl  " );
    desc9.putInteger( idBl, 253 );
executeAction( idcountColor, desc9, DialogModes.NO );

// =======================================================
var idcountColor = stringIDToTypeID( "countColor" );
    var desc10 = new ActionDescriptor();
    var idRd = charIDToTypeID( "Rd  " );
    desc10.putInteger( idRd, 48 );
    var idGrn = charIDToTypeID( "Grn " );
    desc10.putInteger( idGrn, 1 );
    var idBl = charIDToTypeID( "Bl  " );
    desc10.putInteger( idBl, 253 );
executeAction( idcountColor, desc10, DialogModes.NO );

// =======================================================
var idcountAdd = stringIDToTypeID( "countAdd" );
    var desc11 = new ActionDescriptor();
    var idX = charIDToTypeID( "X   " );
    desc11.putDouble( idX, 418.500000 );
    var idY = charIDToTypeID( "Y   " );
    desc11.putDouble( idY, 374.500000 );
executeAction( idcountAdd, desc11, DialogModes.NO );

// =======================================================
var idcountAdd = stringIDToTypeID( "countAdd" );
    var desc12 = new ActionDescriptor();
    var idX = charIDToTypeID( "X   " );
    desc12.putDouble( idX, 332.500000 );
    var idY = charIDToTypeID( "Y   " );
    desc12.putDouble( idY, 416.500000 );
executeAction( idcountAdd, desc12, DialogModes.NO );

// =======================================================
var idCls = charIDToTypeID( "Cls " );
    var desc13 = new ActionDescriptor();
    var idSvng = charIDToTypeID( "Svng" );
    var idYsN = charIDToTypeID( "YsN " );
    var idN = charIDToTypeID( "N   " );
    desc13.putEnumerated( idSvng, idYsN, idN );
executeAction( idCls, desc13, DialogModes.NO );