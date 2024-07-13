/*-----------------------------REXX----------------------------------*\
 *  Apply LIBDEF and ALTLIB overrides to for stage E-F.              *
 *  Executed by typing LIBDEVER on the command line in Endevor.      *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

address ispexec

"libdef ISPMLIB dataset id('PREV.TEV1.ISPMLIB'," ,
                          "'PREV.UEV1.ISPMLIB') stkadd"
if rc ^= 0 then say 'ISPMLIB LIBDEF override failed'

"libdef ISPPLIB dataset id('PREV.TEV1.ISPPLIB'," ,
                          "'PREV.UEV1.ISPPLIB') stkadd"
if rc ^= 0 then say 'ISPPLIB LIBDEF override failed'

"libdef ISPSLIB dataset id('PREV.TEV1.ISPSLIB'," ,
                          "'PREV.UEV1.ISPSLIB') stkadd"
if rc ^= 0 then say 'ISPSLIB LIBDEF override failed'

address tso
"ALTLIB ACTIVATE APPLICATION(CLIST) DATASET('PREV.TEV1.ISPCLIB'," ,
       "'PREV.UEV1.ISPCLIB','PGEV.BASE.ISPCLIB'," ,
       "'PREV.TEV1.REXX','PREV.UEV1.REXX','PGEV.BASE.REXX'," ,
       "'SYSNDVR.CAI.ISRCLIB')"
if rc ^= 0 then say 'ALTLIB activate failed'

say 'ISPF overrides applied'
