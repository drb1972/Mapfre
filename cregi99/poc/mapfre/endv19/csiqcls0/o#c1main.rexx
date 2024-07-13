*  This member contains REXX edits and adjustments on the C1DEFLTS
*  variables.

   tmp = Strip(EndevorAlternateUserid)"," ;
   EndevorAlternateUserid = Overlay('X',tmp,49) ;

   tmp = "''"Strip(CompanyName)"''," ;
   CompanyName     = Overlay('X',tmp,52) ;

   tmp = Strip(IncludeOption)"," ;
   IncludeOption = Overlay('X',tmp,50) ;

   tmp = "''"Strip(ACMRootFilename)"''," ;
   ACMRootFilename = Overlay('X',tmp,51) ;

   tmp = "''"Strip(ACMxrefFilename)"''," ;
   ACMxrefFilename = Overlay('X',tmp,51) ;

   tmp = "''"Strip(ElementCatalogFilename)"''," ;
   ElementCatalogFilename = Overlay('X',tmp,51) ;

   tmp = "''"Strip(ElementIndexFilename)"''," ;
   ElementIndexFilename   = Overlay('X',tmp,51) ;

   tmp = "''"Strip(ParmLibraryName)"'',";
   ParmLibraryName         = Overlay('X',tmp,51) ;

   tmp = "''"Strip(PackageFilename)"''," ;
   PackageFileName         = Overlay('X',tmp,52) ;

