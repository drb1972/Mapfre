/*-----------------------------REXX----------------------------------*\
 *  Apply LIBDEF and ALTLIB overrides to for stage O.                *
 *  Executed by typing LIBDFVER on the command line in Endevor.      *
\*-------------------------------------------------------------------*/
parse source . . rexxname .
if sysdsn("'TTEV.TRACE."rexxname"'") = 'OK' then trace i

address ispexec

"libdef ISPMLIB dataset id('PREV.UEV1.ISPMLIB') stkadd"
if rc ^= 0 then say 'ISPMLIB LIBDEF override failed'

"libdef ISPPLIB dataset id('PREV.UEV1.ISPPLIB') stkadd"
if rc ^= 0 then say 'ISPPLIB LIBDEF override failed'

"libdef ISPSLIB dataset id('PREV.UEV1.ISPSLIB') stkadd"
if rc ^= 0 then say 'ISPSLIB LIBDEF override failed'

address tso
"ALTLIB ACTIVATE APPLICATION(CLIST) DATASET('PREV.UEV1.ISPCLIB'," ,
       "'PGEV.BASE.ISPCLIB'," ,
       "'PREV.UEV1.REXX','PGEV.BASE.REXX'," ,
       "'SYSNDVR.CAI.ISRCLIB')"
if rc ^= 0 then say 'ALTLIB activate failed'

say 'ISPF overrides applied'
