 MOVE     ELEMENT "        "
)N        THROUGH "<THRUNAME>"
     FROM ENV     "        " STAGE NUM "1"
          SYS     "        " SUBSYSTEM "        " TYPE "        "
)N
)N USE "MD" LINE COMMANDS TO CONVERT REQUIRED OPTIONS TO VALID SCL
)N NOTE: WHERE KEYWORDS ARE GROUPED, PICK ONE LINE ONLY E.G. SPAN
)N
)N  OPTION
)N    CCID    "            "
)N    COMMENT "                                        "
)N
)N    SYNCHRONIZE
)N
)N    WITH HISTORY
)N
)N    JUMP
)N
)N    BYPASS ELEMENT DELETE
)N
)N      SIGNIN
)N      RETAIN SIGNOUT
)N      SIGNOUT TO <USERID>
)N
)N  WHERE
)N    CCID
)N      OF CURRENT  EQUAL <CCID>
)N      OF ALL      EQ   (<CCID1>, <CCID2>, <CCID3>)
)N      OF RETRIEVE =     <CCID>
)N    PROCESSOR GROUP EQUAL <PG>
    .
