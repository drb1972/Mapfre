//*********************************************************************
//** SKELETON CMSNDRC                                                **
//*********************************************************************
//DESTINFO DD DISP=SHR,                        /* INPUT DSN          */
//             DSN=&DESTDSN
//DESTSYS  DD DISP=SHR,                        /* INPUT DSN          */
//             DSN=&ENDVDSN
//SYSTSIN  DD DUMMY
//*
//*********************************************************************
//** SPWARN - ABEND IF DESTCPY RETURN CODE NOT EQUAL TO ZERO         **
//*********************************************************************
//CHECKIT  IF EVDESTCP.RC NE 0 THEN
//*
//SPWARN   EXEC @SPWARN,COND=EVEN
//CHECKIT  ENDIF
//*
