%MACRO MEMS(LOC,ORDER);                                                 00010007
PROC SOURCE INDD=&LOC NODATA NOPRINT DIRDD=D&LOC;                       00020006
DATA &LOC;                                                              00030006
  INFILE D&LOC;                                                         00040006
  INPUT MEMBER $8.;                                                     00050000
  LENGTH LOCATION $4;                                                   00060005
  LOCATION = "&LOC";                                                    00070006
  SORT = &ORDER;                                                        00080000
                                                                        00081011
  M = TRANSLATE(MEMBER,'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAANNNNNNNNNN',      00090008
                       'ABCDEFGHIJKLMNOPQRSTUVWXYZ$¢#@1234567890');     00100009
  IF SUBSTR(M,1,1) ^= 'A'                                               00110010
   | VERIFY(M,'AN ') ^= 0                                               00120013
   | MEMBER = '$$$SPACE'                                                00130010
  THEN DELETE;                                                          00140010
  DROP M;                                                               00150008
PROC APPEND BASE=COPY DATA=&LOC;                                        00160006
%MEND;                                                                  00170000
