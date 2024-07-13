)CM *----------------------------------------------------------------*
)CM *                                                                *
)CM *  COPYRIGHT (C) 2022 BROADCOM. ALL RIGHTS RESERVED.             *
)CM *                                                                *
)CM * NAME: ENDES010                                                 *
)CM *                                                                *
)CM * PURPOSE: THIS SKELETON IS USED BY THE QUICK-EDIT DIALOG TO     *
)CM *  INCLUDE A TABLE OF SCL INTO THE MAIN ENDES000 IS THE QUEUE    *
)CM *  BATCH ACTIONS FEATURE IS ENABLED.                             *
)CM *                                                                *
)CM *----------------------------------------------------------------*
)CM
)CM  IF CD18101 QE QUEUE BATCH ACTION OPTION IS ENABLED THEN
)CM  QUICK EDIT CAN SUBMIT BATCH JOBS WITH MULTIPLE REQUESTS
)CM  FROM A TABLE (ENZIESCL, WHERE Z IS THE SCREEN NUMBER)
)CM  IF MULTIPLE REQUESTS ARE PRESENT THEY ARE FORMATED AS USUAL
)CM  BUT WITH THE REQUEST SEQUENCE NUMBER IN COLS 73-80
)CM
)DOT &EEVQUTAB
&EEVQUSCL.
)ENDDOT
