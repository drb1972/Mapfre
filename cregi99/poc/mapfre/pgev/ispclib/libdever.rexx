/*-----------------------------REXX----------------------------------*\
 *  Apply LIBDEF and ALTLIB overrides to for stage E-F.              *
 *  Executed by typing LIBDEVER on the command line in Endevor.      *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

address ispexec

"libdef ISPMLIB dataset id('PREV.EEV1.ISPMLIB'," ,
                          "'PREV.FEV1.ISPMLIB') stkadd"
if rc ^= 0 then say 'ISPMLIB LIBDEF override failed'

"libdef ISPPLIB dataset id('PREV.EEV1.ISPPLIB'," ,
                          "'PREV.FEV1.ISPPLIB') stkadd"
if rc ^= 0 then say 'ISPPLIB LIBDEF override failed'

"libdef ISPSLIB dataset id('PREV.EEV1.ISPSLIB'," ,
                          "'PREV.FEV1.ISPSLIB') stkadd"
if rc ^= 0 then say 'ISPSLIB LIBDEF override failed'

address tso
"ALTLIB ACTIVATE APPLICATION(CLIST) DATASET('PREV.EEV1.ISPCLIB'," ,
       "'PREV.FEV1.ISPCLIB','PGEV.BASE.ISPCLIB'," ,
       "'SYSNDVR.CAI.ISRCLIB')"
if rc ^= 0 then say 'ALTLIB activate failed'

say 'ISPF overrides applied'
