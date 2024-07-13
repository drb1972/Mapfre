/* rexx to build wizard copy statements based on dsnlist     */

parse arg change c1system
  address ispexec
  "ISPEXEC CONTROL NONDISPL ENTER" /* simulate ENTER on next panel */
  ZDLPVL = ''
  "ISPEXEC VPUT ZDLPVL"

  vget (zprefix)
  if zprefix ^= 'TTOS' then /* For the DBAs */
    zdldsnlv = 'TT'right(zprefix,2)'.'change
  else /* For Batch Services */
    zdldsnlv = 'TT'c1system'.'change

  "ISPEXEC VPUT ZDLDSNLV"                   /* VPUT the dsname mask */
  "ISPEXEC SELECT PGM(ISRUDL) PARM(ISRUDLP)"   /* invoke normal 3.4 */
  exit
