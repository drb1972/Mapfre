  If Type = ' ' then $SkipRow = 'Y'
  If Procgrp = ' ' then $SkipRow = 'Y'
  Type = Strip(Type)
  DataRow2 = Overlay(Type,DataRow2,1,8,' ') ;
  Procgrp = Strip(Procgrp)
  DataRow2 = Overlay(Procgrp,DataRow2,10,8,' ') ;
  NewFrm = 'Y'
  DataRow2 = Overlay(NewFrm,DataRow2,21,1,' ') ;
  Lvls = '0'
  DataRow2 = Overlay(Lvls,DataRow2,27,2,' ') ;
  Out = '&Output'
  DataRow2 = Overlay(Out,DataRow2,31,7,' ') ;
