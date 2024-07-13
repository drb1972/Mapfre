  If System = ' ' then $SkipRow = 'Y'
  If Subsystem = ' ' then $SkipRow = 'Y'
  DataRow = Overlay('  ',DataRow,1,3,' ') ;
  System = Strip(System)
  DataRow = Overlay(System,DataRow,4,8,' ') ;
  Subsystem = Strip(Subsystem)
  DataRow = Overlay(Subsystem,DataRow,13,8,' ') ;
  DataRow = Overlay('&DataRow2',DataRow,23) ;
