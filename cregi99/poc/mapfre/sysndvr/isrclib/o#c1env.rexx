  $StripData = 'N' ;
  MODEL = 'MODEL'
  IF $row# < 1 then MODEL = 'NOTHING'

  Envtitl = Strip(Envname) 'Environment'
  tmp = "''"Strip(Envtitl)"''," ;
  Envtitl = Overlay('X',tmp,51) ;

  Stg1ttl = Strip(Stg1nme) 'Stage'
  tmp = "''"Strip(Stg1ttl)"''," ;
  Stg1ttl = Overlay('X',tmp,51) ;

  Stg2ttl = Strip(Stg2nme) 'Stage'
  tmp = "''"Strip(Stg2ttl)"''," ;
  Stg2ttl = Overlay('X',tmp,51) ;

  Envname = Strip(Envname)
  tmp = Strip(Substr(Envname,1,3,'$')1) ;
  Stg1vsm = SiteHighLevelQual'.'tmp'.MCF'
  tmp = "''"Strip(Stg1vsm)"''," ;
  Stg1vsm = Overlay('X',tmp,51) ;

  tmp = Strip(Substr(Envname,1,3,'$')2) ;
  Stg2vsm = SiteHighLevelQual'.'tmp'.MCF'
  tmp = "''"Strip(Stg2vsm)"''," ;
  Stg2vsm = Overlay('X',tmp,51) ;

  tmp = "''"Strip(Stg1nme)"''," ;
  Stg1nme@= Overlay('X',tmp,51) ;

  tmp = "''"Strip(Stg2nme)"''," ;
  Stg2nme@= Overlay('X',tmp,51) ;

  tmp = "''"Strip(Envname)"''," ;
  Envname@ = Overlay('X',tmp,51) ;

  a= Strip(Stg1ID)","
  b= Strip(Stg2ID)","

  NextEnvironmt = ' '
  If NextEnv /= '' then NextEnvironmt = EntryStage.Envname
  tmp = Strip(NextEnvironmt)"," ;
  NextEnvironmt = Overlay('X',tmp,49) ;
  e = Strip(Entrystg#)','
