   DEFINE   PACKAGE <PKGID>
      DESCRIPTION "                                                  "
)N
)N          COPY FROM PACKAGE <FROMPKGID>
)N          IMPORT SCL FROM
)N             DDNAME "<DDNAME>"
)N             DSNAME "<DSNAME>"
)N                MEM "<MEMBER>"
)N
)N          DO NOT APPEND
)N          APPEND
)N
)N    OPTION
)N          STANDARD
)N          EMERGENCY
)N
)N          NONSHARABLE
)N             SHARABLE
)N
)N             PROMOTION PACKAGE
)N          NONPROMOTION PACKAGE
)N
)N          BACKOUT IS ENABLED
)N          BACKOUT IS NOT ENABLED
)N
)N          EXECUTION WINDOW
)N                    FROM   DDMMMYY HH:MM
)N                    TO     DDMMMYY HHH:MM
)N
)N          DO NOT VALIDATE SCL
)N
)N   NOTES =
)N     ("PACKAGE NOTES GO HERE...                                    ",
)N      "UP TO 8 LINES OF 60 CHARACTERS EACH...                      ",
)N      "                                                            ",
)N      "                                                            ",
)N      "                                                            ",
)N      "                                                            ",
)N      "                                                            ",
)N      "                                                            ")
   .
