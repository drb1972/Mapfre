/*-----------------------------REXX----------------------------------*\
 *  Apply LIBDEF and ALTLIB overrides to for stage F                 *
 *  Executed by typing LIBDFVER on the command line in Endevor.      *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

address ispexec

"libdef ISPMLIB dataset id('PREV.FEV1.ISPMLIB') stkadd"
if rc ^= 0 then say 'ISPMLIB LIBDEF override failed'

"libdef ISPPLIB dataset id('PREV.FEV1.ISPPLIB') stkadd"
if rc ^= 0 then say 'ISPPLIB LIBDEF override failed'

"libdef ISPSLIB dataset id('PREV.FEV1.ISPSLIB') stkadd"
if rc ^= 0 then say 'ISPSLIB LIBDEF override failed'

address tso
"ALTLIB ACTIVATE APPLICATION(CLIST) DATASET('PREV.FEV1.ISPCLIB'," ,
       "'PGEV.BASE.ISPCLIB'," ,
       "'SYSNDVR.CAI.ISRCLIB')"
if rc ^= 0 then say 'ALTLIB activate failed'

say 'ISPF overrides applied'
