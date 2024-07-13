PROC SORT DATA=COPY; BY MEMBER SORT;                                    00010000
DATA COPY;                                                              00020000
  SET COPY;                                                             00030000
  BY MEMBER SORT;                                                       00040001
  IF FIRST.MEMBER;                                                      00050007
TITLE 'LIST OF MEMBERS COPIED AND FROM WHICH LOCATION';                 00060005
PROC PRINT DATA=COPY N NOOBS;                                           00070004
  VAR MEMBER LOCATION;                                                  00080006
PROC SORT DATA=COPY; BY LOCATION MEMBER;                                00090006
TITLE 'LIST OF MEMBERS COPIED BY LOCATION';                             00100005
PROC PRINT DATA=COPY N NOOBS;                                           00110003
  BY LOCATION;                                                          00120006
  VAR LOCATION MEMBER;                                                  00130006
