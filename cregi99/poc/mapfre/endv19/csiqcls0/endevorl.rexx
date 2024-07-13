/* rexx */

/* Sample Rexx exec to run ENdevor API to list stages and build    */
/* a graphic version of a simple Endevor lifecycle.                */
/* Note: this program is provided as a sample only and will work   */
/*       "as is" only for a C1DEFLTS with simple mapping.          */

address ISPEXEC


/* Build request to list all stages */
drop sysin.
sysin.1 = 'AACTLYMESSAGE LIST'
sysin.2 = 'ALSTGPAN '
sysin.3 = 'RUN'
sysin.0 = 3

call API

/* Handle not found... */
if maxrc >= 12 ,
 | list.0 = 0 then ,
  do
    zedsmsg = 'No Stages Found'
    zedlmsg = 'Nothing found searching for stages, do you have access?'
    "SETMSG MSG(ISRZ001)"
    exit 4
  end

drop mapstgid
drop maptitle
drop mappreve
drop mapprevs
drop mapentry
drop maptypes
listenvs = ''                        /* List of Environments */
listtops = ''
mappreve. = ''                       /* Mapped FROM Environment */
mapprevs. = ''                       /*   "     "   StageID  */

/* Parse response from LIST STAGES API request
   Building structure using stem variables to make navigation easier
   */

do i = 1 to list.0
  parse value list.i with,
    14 thisenv 22,
    22 thisstg 30,
    30 thissid 31,
    31 thissno 32,
    32 thistit 52,
    97 thisent 98,
    98 thisstp 99,
   101 thisnxe 109,
   109 thisnxs 110

  sa= right(i,2,' ') ,
       thisenv,
       thisstg,
       thissid,
       thissno,
       thistit,
       thisent,
       thisstp,
       thisnxe,
       thisnxs

  thisenv = strip(thisenv)
  thisnxe = strip(thisnxe)

  if thissno = 1 then do             /* for each environment */
     listenvs = listenvs thisenv
     if thisent == 'Y' then
        mapentry.thisenv = 1
     else
        mapentry.thisenv = 2
  end
  mapstgid.thisenv.thissno=thissid
  maptitle.thisenv.thissno=thistit
  if thisnxe = '' then
     listtops = listtops thisenv
  else
  if thisnxe \= thisenv then do      /* don't track physical map */
     mappreve.thisnxe.thisnxs=mappreve.thisnxe.thisnxs thisenv
     mapprevs.thisnxe.thisnxs=mapprevs.thisnxe.thisnxs thissno
  end
end

say=" "
say="Types:" Listenvs

/* Decide how to DRAW each Environment diagram; using one of:
   skinny:   When only entry stage 2 is used
   Vertical: When both stages are used but lower stages map to stage 2
   Wide:     When both stages are used but lower stages map to stage 1
   */
do i = 1 to words(listenvs)
   thisenv = word(listenvs,i)
   select
      when mapentry.thisenv   == '2' ,
       &   mapprevs.thisenv.1 == ''  then
             maptypes.thisenv = 'Skinny'
      when mapentry.thisenv   == '1' ,
       &   mapprevs.thisenv.1 == ''  then
             maptypes.thisenv = 'Vertical'
      otherwise
             maptypes.thisenv = 'Wide'
   end
end

say=" "
say="Envs:" Listenvs

do i = 1 to words(listenvs)
   thisenv = word(listenvs,i)
   say=right(i,2,' ') right(thisenv,8),
               value('mapstgid.'||thisenv||'.1'),
               value('maptitle.'||thisenv||'.1'),
               value('mapstgid.'||thisenv||'.2'),
               value('maptitle.'||thisenv||'.2'),
               right(mappreve.thisenv.1,8),
               left(mappreve.thisenv.2,8),
               maptypes.thisenv
end

say=" "
say="Maps:" Listtops

/* Decide on drawing character set to use                       */
"VGET (ZTERM QEPEVNME VAREVNME) ASIS"   /* get term & ENV Names */

/* set drawing chrs according to terminal type */
select
   when ZTERM = "3278T" then do /* If we have Text Drawing Chrs */
      TL = 'AC'x                   /* Top Left         Ð      */
      TM = 'CC'x                   /* Top middle       ö      */
      TR = 'BC'x                   /* Top Right        ¯      */
      MR = 'EB'x                   /* Mid Left         Ô      */
      MM = '8F'x                   /* Mid Mid          ±      */
      MR = 'EC'x                   /* Mid Right        Ö      */
      BL = 'AB'x                   /* Bot Left         ¿      */
      BM = 'CB'x                   /* Bot middle       ô      */
      BR = 'BB'x                   /* Bot Right        ¨      */
      HL = 'BF'x                   /* Horizontal Line  ×      */
      VL = 'FA'x                   /* Vertical Line    ³      */
      AR = '6E'x                   /* Arrow Right      >      */
      AU = 'EF'x                   /* Arrow Up         Õ      */
   end
   otherwise do
      TL = '+'                     /* Top Left         +      */
      TM = '+'                     /* Top middle       +      */
      TR = '+'                     /* Top Right        +      */
      MR = '+'                     /* Mid Left         +      */
      MM = '+'                     /* Mid Mid          +      */
      MR = '+'                     /* Mid Right        +      */
      BL = '+'                     /* Bot Left         +      */
      BM = '+'                     /* Bot middle       +      */
      BR = '+'                     /* Bot Right        +      */
      HL = '-'                     /* Horizontal Line  -      */
      VL = '|'                     /* Vertical Line    |      */
      AR = '>'                     /* Arrow Right      >      */
      AU = "'"                     /* Arrow Up         '      */
   end
end

/* Build Thumbnail version of LifeCycle */

map. = ''

do i = 1 to words(listtops)
   thisenv = word(listtops,i)
   arrow = '   '                            /* no arrow first time */
   color = 'P'                              /* top of map in pink  */

   do while thisenv /= ''
      s1 = mapstgid.thisenv.1
      s2 = mapstgid.thisenv.2
      if maptypes.thisenv == 'Wide' then do
         map.t.i.1 = centre(strip(right(thisenv,8)),8,' ') || ' ',
                                                || map.t.i.1 /* _Dev__ */
         map.t.i.2 = '   'S1||AR||s2 || arrow   || map.t.i.2 /*  1×2××>*/
         map.t.i.3 = '   'AU'     '             || map.t.i.3 /*  Õ     */
         map.t.i.4 = '         '                || map.t.i.4 /*        */
         map.s.i.1 = '   'copies(' ',3)'   '    || map.S.i.1 /*        */
         map.s.i.2 = '   'copies(color,3)'   '  || map.S.i.2 /*  CCC   */
         map.s.i.3 = '   'copies(' ',3)'   '    || map.S.i.3 /*        */
         map.s.i.4 = '         '                || map.S.i.4 /*        */
         thisenv = word(mappreve.thisenv.1,1)
      end
      else do
         map.t.i.1 = centre(strip(right(thisenv,8)),8,' ')  || ' ',
                                                || map.t.i.1 /* WRK_   */
         map.t.i.2 = '     'S2  || arrow        || map.t.i.2 /*  2××>  */
         map.s.i.1 = '     'copies(' ',1)'   '  || map.S.i.1 /*  x     */
         map.s.i.2 = '     'copies(color,1)'   '|| map.S.i.2 /*  x     */
         if maptypes.thisenv == 'Vertical' then do
            map.t.i.3 = '    'AR||S1'   '       || map.t.i.3 /* >1     */
            map.t.i.4 = '     'AU'   '          || map.t.i.4 /*  Õ     */
            map.s.i.3 = '     'copies(color,1)'   ',
                                                || map.s.i.3 /*  x     */
            map.s.i.4 = '         '             || map.s.i.4 /*        */
         end
         else do
            map.t.i.3 = '     'AU'   '          || map.t.i.3 /*  Õ     */
            map.t.i.4 = '         '             || map.t.i.4 /*        */
            map.s.i.3 = '     'copies(' ',1)'   ',
                                                || map.s.i.3 /*        */
            map.s.i.4 = '         '             || map.s.i.4 /*        */
         end
         thisenv = word(mappreve.thisenv.2,1)
      end
      arrow = HL||HL||AR                       /* use -->   or hyphen */
      if color = 'T' then                      /* alternate colours   */
         color = 'B'
      else
         color = 'T'
      if thisenv = QEPEVNME then               /* if Environment matches Q/E  */
         color = 'Y'                           /* Env highlight it in yellow  */
   end
end

   /* debug - uncomment the following lines
   do i = 1 to 2
      do j = 1 to 4
         say i '~'map.t.i.j'~'
      end
      do j = 1 to 4
         say i '×'map.s.i.j'×'
      end
   end
   */

/* prepare for display */
THUMBA = ''
THUMBS = ''
do i = 1 to 3                                  /* up to three rows of 4 lines */
   do j = 1 to 3                               /* put data into thumbnail     */
      THUMBA = THUMBA || right(map.t.i.j,45)
      THUMBS = THUMBS || right(map.s.i.j,45)
   end                                         /* then divider - spaces       */
      THUMBA = THUMBA || copies(' ',45)
      THUMBS = THUMBS || copies(' ',45)
end

address ispexec "VPUT (THUMBA,THUMBS) PROFILE"

/* Display Panel       */
/*
"VGET (ZTERM) ASIS"                /* get current terminal type */
"SELECT PGM(ISPTTDEF) PARM(3278T)" /* set terminal to 3278T     */

   do while RC = 0                 /* let user scroll around... */
     address ispexec "display panel(ENDEVORV)"
   end

"SELECT PGM(ISPTTDEF) PARM("ZTERM")" /* restore terminal type   */

*/
return

/* Call Endevor API */
API:

trace o
address TSO
"ALLOCATE FILE(SYSPRINT) NEW DELETE CYLINDER SPACE(1 25) REUSE"
"ALLOCATE FILE(MESSAGE) NEW DELETE CYLINDER SPACE(1 25) " ,
    "RECFM(F B) LRECL(133) REUSE"
"ALLOCATE FILE(LIST) NEW DELETE CYLINDER SPACE(5 50) " ,
    "RECFM(V B) LRECL(2048) REUSE"
"ALLOCATE FILE(SYSIN) NEW DELETE CYLINDER SPACE(1 25) ",
    "RECFM(F B) LRECL(80) REUSE"
"ALLOCATE FILE(BSTIPT01) NEW DELETE CYLINDER SPACE(1 25) ",
    "RECFM(F B) LRECL(80) REUSE"
"ALLOCATE FILE(ENPSCLIN) NEW DELETE CYLINDER SPACE(1 25) ",
    "RECFM(F B) LRECL(80) REUSE"
"ALLOCATE FILE(C1MSGS1) NEW DELETE CYLINDER SPACE(1 25) ",
    "RECFM(F B) LRECL(133) REUSE"
"EXECIO * DISKW SYSIN (STEM SYSIN. FINIS"

"ENTBJAPI"

myrc = rc
if myrc > 0 then ,
  do
    address ISPEXEC
    "LMINIT DATAID(ID) DDNAME(MESSAGE)"
    "BROWSE DATAID("id")"
    "LMFREE DATAID("id")"
    maxrc = max(maxrc, 12)
    return
  end

address TSO
"EXECIO * DISKR LIST (STEM LIST. FINIS"

"FREE FILE(SYSPRINT MESSAGE SYSIN BSTIPT01 ENPSCLIN C1MSGS1)"

return

/* ×××××××××××××××××××××××××× */


/* ×××××××××××××××××××××××××× */

/* Browse the listing */

browse_listing:

address ISPEXEC
"VGET (VARBRWVW)"

zedsmsg = ' '
zedlmsg = 'Listing displayed from' eenv '/' esys '/' esub '/' estg
"SETMSG MSG(ISRZ000)"

"LMINIT DATAID(MYID) DDNAME(OUT)"

if varbrwvw = 'V' then ,
  do
    "VIEW DATAID("MYID") MEMBER("ELEMENT")"
  end
else ,
  do
    "BROWSE DATAID("MYID") MEMBER("ELEMENT")"
  end

"LMFREE DATAID("MYID")"

address TSO "FREE FILE(OUT)"
"CONTROL ERRORS CANCEL"
return
