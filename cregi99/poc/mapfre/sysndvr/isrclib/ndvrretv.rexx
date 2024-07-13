<<NDVRRETV>>
:*--------------------------------------------------------------------*
:*                                                                    *
:* COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                   *
:*                                                                    *
:* Name: NDVRRETV                                                     *
:*                                                                    *
:* Function: This RPF is used to create the ROSDATA sysin data for    *
:*  all RETRIEVE SCL statments. This RPF is called by NDVR only       *
:*  when RETRIEVE SCL statements are present.                         *
:*                                                                    *
:* LOG:                                                               *
:* P2313 Search for the 'REPLACE' option.  If it is not specified,    *
:*  then check for the existence of the named Roscoe member to which  *
:*  the retrieve is to be done.  If it exists, then disallow its      *
:*  replacement, by setting a return code for the NDVR rpf to test.   *
:*  See also P2313 in the NDVR rpf, for the test of the ndvrretv      *
:*  return code.                                                      *
:*--------------------------------------------------------------------*
DECLARE L1 L2 L3<100> L4 SUB L6
DECLARE L7 L8 L9 L10 L11 L12<100>  SUB1 L14          : Added for P2313
  TRAP ON
  +DELETE +P3+         :Delete the work file
  TRAP OFF
  +UPDATE +P3+         :Update from AWS
:
  LET SUB=0
  TOP
:
  LOOP
    TRAP
    NEXT AWS /TO DDNAME ROSCOER/
    TRAP OFF
    IF S.TC NE 0
        ESCAPE
    ENDIF
:
    LET L6=S.SEQ
    LET SUB=SUB+1
    READ AWS * L1
    LET L2=INDEX(L1 'MEMBER')
    IF L2 GT 0
           LET L4=LTRIM(TRIM(SUBSTR(L1 L2+8)))
           LET L3<SUB>=SUBSTR(L4,1,INDEX(L4,'''')-1)
    ELSE
           LET L3<SUB>=' '
    ENDIF
:
    TRAP
    PREV /ELEMENT/ 10
    TRAP OFF
    IF L3<SUB> EQ ' '
       READ AWS * L1
       LET L2=INDEX(L1 'ELEMENT')
       LET L4=LTRIM(TRIM(SUBSTR(L1 L2+9)))
       LET L3<SUB>=SUBSTR(L4,1,INDEX(L4,'''')-1)
    ENDIF
: P2313 part 1               : Look for 'REPLACE' option
    +POINT +L6+
    TRAP
    NEXT AWS / . /
    TRAP OFF
    IF S.TC EQ 0
        LET L7=S.SEQ         : LINE NO. OF END OF THIS RETRIEVE
     +POINT +L6+
:                            : BACK TO BEGIN OF THIS RETRIEVE
     TRAP
     NEXT AWS / OPTIONS /
     TRAP OFF
    IF S.TC EQ 0
        LET L8=S.SEQ         : LINE NO. OF START OF 'OPTIONS'
    IF L8 LT L7              : CONTINUE IF OPTIONS BEFORE '.'
      POINT *-1
     TRAP
     NEXT AWS / REPLACE /
     TRAP OFF
    IF S.TC EQ 0
        LET L9=S.SEQ         : LINE NO. OF FIRST 'REPLACE'
    IF L9 LT L7              : CONTINUE IF REPLACE IN STATEMENT
      LET L12<SUB> = 'R'
     ELSE
     ENDIF
    ELSE
    ENDIF
   ELSE
   ENDIF
  ELSE
  ENDIF
 ELSE
 ENDIF
: P2313 part 1 end
    +POINT +L6+
    POINT *+1
  ENDLOOP
:
  DELETE              :Clear the AWS
  +FETCH +P3+         :Re-read the JCL
  +DELETE +P3+        :Delete the work file
:
  WRITE AWS B
     '//DD01      DD DSN=&&NDVRRET,                           '
     '//         DISP=(OLD,PASS,DELETE)                       '
  ENDWRITE
:         *---------------------------------------------------------*
:         * Create a ROSDATA SYSIN control card stream.  A $ADD     *
:         * statement is created for each element to be written to  *
:         * the ROSCOE library.                                     *
:         *---------------------------------------------------------*
  WRITE AWS B '//SYSIN DD *'
  LET L2=SUB
  LOOP SUB FROM 1 TO L2 BY 1
:  P2313   - AFTER WE SET L3 ( = MEMBER; OR ELEMENT, IF NO 'MEMBER'),
:            IF 'REPLACE' IS NOT WANTED: TRY TO ATTACH THE MEMBER;
:            IF WE FIND IT, CHANGE THE NAME BY APPENDING THE FIRST
:            DIGIT, STARTING WITH 1, THAT DOES NOT CAUSE A MATCH WITH
:            AN EXISTING MEMBER.
  LET L8 = L3<SUB>                                              : P2313
  IF  L12<SUB> NE 'R'                                           : P2313
    TRAP                                                        : P2313
    +ATTACH LIB +L8+                                            : P2313
    TRAP OFF                                                    : P2313
    LET L10 = STRING(S.TC)                                      : P2313
   IF  S.TC EQ 0          : IF S.TC = 0, MEMBER ALREADY EXISTS  : P2313
    THEN                  : - GIVE AN ERROR MESSAGE.            : P2313
     LET L7 = 8            : Set return code                    : P2313
     RETURN L7 L3<SUB>     : Return the r.c. and member name    : P2313
   ELSE            : IS 'REPLACE'; BUT DOESN'T EXIST            : P2313
     WRITE AWS B                                                : P2313
      '$ADD MEMBER=' | L3<SUB> | ',MAXSIZE=OFF,LIST=CONTROL, '  : P2313
              '  SEQ1=1,INCR=1,SEQ=80,6                      '  : P2313
      '$FROM DD01(' | L3<SUB> | ') '                            : P2313
     ENDWRITE                                                   : P2313
   ENDIF                                                        : P2313
  ELSE            : 'R' = 'REPLACE'                             : P2313
    WRITE AWS B
      '$ADD MEMBER=' | L3<SUB> | ',MAXSIZE=OFF,LIST=CONTROL, '
              '  SEQ1=1,INCR=1,SEQ=80,6                      '
      '$FROM DD01(' | L3<SUB> | ') '
    ENDWRITE
  ENDIF                                                         : P2313
  ENDLOOP
