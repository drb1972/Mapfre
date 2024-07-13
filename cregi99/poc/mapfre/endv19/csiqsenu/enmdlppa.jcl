)N DEFINE   PACKAGE <PKGID>
)N    DESCRIPTION "                                                  "
)N
)N          COPY FROM PACKAGE <FROMPKGID>
)N          IMPORT SCL FROM
)N             DSNAME "<DSNAME>"
)N                MEM "<MEMBER>"
)N          DDNAME "<DDNAME>"
)N
)N          DO NOT APPEND
)N          APPEND
)N
)N    OPTION
)N          EXECUTION WINDOW
)N                    FROM   DDMMMYY HH:MM
)N                    TO     DDMMMYY HHH:MM
)N
)N          DO NOT VALIDATE SCL
)N
)N          PROMOTION PACKAGE
)N          NONPROMOTION PACKAGE
)N
)N CAST     PACKAGE <PKGID>
)N
)N    OPTION
)N           BACKOUT IS ENABLED
)N           BACKOUT IS NOT ENABLED
)N
)N           VALIDATE COMPONENT
)N           VALIDATE COMPONENT WITH WARNING
)N           DO NOT VALIDATE COMPONENT
)N
)N           EXECUTION WINDOW
)N                     FROM   DDMMMYY HH:MM
)N                     TO     DDMMMYY HHH:MM
)N
)N INSPECT  PACKAGE <PKGID>
)N
)N RESET    PACKAGE <PKGID>
)N
)N APPROVE  PACKAGE <PKGID>
)N
)N DENY     PACKAGE <PKGID>
)N
)N EXECUTE  PACKAGE <PKGID>
)N    OPTION
)N       WHERE PACKAGE STATUS IS APPROVED OR EXECFAILED
)N
)N SUBMIT   PACKAGE <PKGID>
)N    JOBCARD DDNAME JCLIN
)N            DSNAME "<JOBCARD.DSNAME>" MEMBER "<MEM>"
)N    TO      INTERNAL READER DDNAME JCLOUT
)N    OPTION
)N       WHERE PACKAGE STATUS IS APPROVED OR EXECFAILED
)N       MULTIPLE JOBSTREAMS
)N          INCREMENT JOBNAME
)N          DO NOT INCREMENT JOBNAME
)N       JCL PROCEDURE NAME IS <PROCNAME>
)N
)N BACKIN   PACKAGE <PKGID>
)N        STATEMENT <NUMBER>
)N          ELEMENT "<ELEMENT>"
)N
)N BACKOUT  PACKAGE <PKGID>
)N        STATEMENT <NUMBER>
)N          ELEMENT "<ELEMENT>"
)N
)N COMIT    PACKAGE <PKGID>
)N
)N DELETE   PACKAGE <PKGID>
)N
)N COMMON OPTION TEMPLATES FOLLOW AND CAN BE USED FOR MULTIPLE CLAUSES.
)N
)N
)N OPTION
)N   NOTES =
)N     ("PACKAGE NOTES GO HERE...                                    ",
)N      "UP TO 8 LINES OF 60 CHARACTERS EACH...                      ",
)N      "                                                            ",
)N      "                                                            ",
)N      "                                                            ",
)N      "                                                            ",
)N      "                                                            ",
)N      "                                                            ")
)N
)N   WHERE OLDER THAN <NN> DAYS
)N
)N   DELETE AFTER ARCHIVE
)N   DELETE PROMOTIOIN HISTORY
