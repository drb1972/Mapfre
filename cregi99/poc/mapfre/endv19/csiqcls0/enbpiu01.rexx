/*  REXX program to check if data sets exist.  */
/*  Copyright (C) 2022 Broadcom. All rights reserved. */
  Trace o
  Arg Dataset ;
  if Pos('.',Dataset) = 0 then exit(0)
  DsnCheck = SYSDSN("'"Dataset"'") ;
  Message = ' '
  rsrc = 0
  IF DsnCheck = 'OK' THEN
     Do
       Message = '/* Already Exists */'
       rsrc = 12
     End
  Push Message ;
  exit(rsrc)
