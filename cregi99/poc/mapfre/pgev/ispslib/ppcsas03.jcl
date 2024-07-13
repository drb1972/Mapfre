%MACRO RITE(LOC);                                                       00010006
DATA _NULL_;                                                            00020000
  SET COPY;                                                             00030000
  WHERE LOCATION = "&LOC";                                              00040006
  FILE C&LOC;                                                           00050006
  PUT '    SELECT MEMBER=' MEMBER;                                      00060004
%MEND;                                                                  00070000
