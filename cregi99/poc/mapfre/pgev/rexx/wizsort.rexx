/* Rexx------------------------------------------------------------+ */
/* |                                                               | */
/* |  This routine Builds Sort parameter based on the run date.    | */
/* |  the Year and Month for the previous month is used. If run    | */
/* |  in April 2007 the Sort parms would look like;                | */
/* |                                                               | */
/* |      INCLUDE   COND=(31,4,CH,EQ,C'0703')                      | */
/* |      SORT FIELDS=(42,7,CH,A,13,8,CH,A)                        | */
/* |      SUM FIELDS=(25,4,ZD)                                     | */
/* |                                                               | */
/* |  Name    : PGEV.BASE.REXX(WIZSORT)                            | */
/* |  Author  : John Lewis                                         | */
/* |  Date    : 10th December 2007                                 | */
/* |                                                               | */
/* |  Input Parms  : None                                          | */
/* |                                                               | */
/* |  DDNAME SPARM : Temporary dataset to contain the newly        | */
/* |                 built Sort parameters.                        | */
/* |                                                               | */
/* +---------------------------------------------------------------+ */
Sort_Month = substr(DATE('S'),5,2)
Sort_Year  = substr(DATE('S'),3,2)

If Sort_Month = 1 then do
   Sort_Month = 12
   Sort_Year  = Sort_Year - 1
   end
  else Sort_Month = Sort_Month - 1

Queue " INCLUDE   COND=(31,4,CH,EQ,C'"||,
   right(Sort_year,2,0)||right(Sort_Month,2,0)||"')"
Queue " SORT FIELDS=(42,7,CH,A,13,8,CH,A)"
Queue " SUM FIELDS=(25,4,ZD)"
"EXECIO 5 DISKW SPARM (FINIS"
