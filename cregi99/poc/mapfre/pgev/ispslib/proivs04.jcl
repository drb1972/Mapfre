ADD ELEMENT '&C1ELE'
  FROM DSNAME '&TEMPDSN2'
  TO   ENVIRONMENT '&C1ENV' SYSTEM 'MT' SUBSYSTEM '&C1SUB'
    TYPE '&C1TY'
  OPTIONS CCID '&C1CCID' COMMENTS "#"
  UPDATE OVE PROCESSOR GROUP = '&C1PRCGRP'
 .
)SEL &TYPE = FUN AND &USEDB2 = Y
ADD ELEMENT '&C1ELE'
  FROM DSNAME 'PREV.PEV1.DATA' MEMBER 'BIND'
  TO   ENVIRONMENT '&C1ENV' SYSTEM 'MT' SUBSYSTEM '&C1SUB'
    TYPE 'BIND'
  OPTIONS CCID '&C1CCID' COMMENTS 'PRO IV AUTOBIND'
  UPDATE OVE PROCESSOR GROUP = 'XAYXXBXX'
  BYPASS GENERATE PROCESSOR
 .
)ENDSEL
