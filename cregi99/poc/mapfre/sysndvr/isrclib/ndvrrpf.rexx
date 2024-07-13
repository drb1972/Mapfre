<<NDVRRPF>>
:*--------------------------------------------------------------------*
:*                                                                    *
:* COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                   *
:*                                                                    *
:* Name: NDVRRPF                                                      *
:*                                                                    *
:* Function: This RPF is executed as part of the ENDEVOR/ROSCOE       *
:*  installation process.  It will load the ENDEVOR/ROSCOE panel      *
:*  definitions from the installation library to the appropriate      *
:*  ROSCOE directory                                                  *
:*                                                                    *
:* Note: Before executing this RPF, change the assignment statement   *
:*  identified below to the appropriate installation panel dataset    *
:*  name.                                                             *
:*                                                                    *
:*--------------------------------------------------------------------*
PUSH
SET ATTACH NOPAUSE
:*--------------------------------------------------------------------*
:* Change this assignment statement to the appropraite ENDEVOR/ROSCOE *
:* panel library dataset name.                                        *
:*--------------------------------------------------------------------*
LET L16 = 'TSOXX4.ENDEVOR.V16.CSIQPENU'
+IMP DSN=+L16+(*)
FILL 10 255 / /
TRAP
DELX 1 3 /C1R/
TRAP OFF
R 1 1
S @@@@DIR
A @@@@DIR
LET L2 = HIGHSEQ
LOOP L1 FROM 1 TO L2 BY 1
  +READ LIB +L1+ L3
  +IMP DSN=+L16+(+L3+)
  +S +L3+ E
ENDLOOP
DEL @@@@DIR
POP
