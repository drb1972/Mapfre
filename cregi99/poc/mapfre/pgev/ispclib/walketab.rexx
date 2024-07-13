PROC 0 PREF(PREV) TAB(DOP)
/********************************************************************/
/*     ADD ISPF TABLE WALKT&TAB TO &PREF.BASE.ISPTLIB               */
/********************************************************************/
  CONTROL SYMLIST CONLIST LIST PROMPT
  ISPEXEC LIBDEF USRTABL DATASET ID ('&PREF..BASE.ISPTLIB')
  ISPEXEC TBCREATE WALKT&TAB KEYS(ELE) NAMES(DESC NDVELE) WRITE
  ISPEXEC TBCLOSE  WALKT&TAB LIBRARY(USRTABL)
  EXIT CODE(0)
