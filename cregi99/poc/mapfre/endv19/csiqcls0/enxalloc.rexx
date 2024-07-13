/* REXX                                                              */
/*-------------------------------------------------------------------*/
/*                                                                   */
/* Copyright (C) 2022 Broadcom. All rights reserved.                 */
/*                                                                   */
/* NAME: ENXALLOC                                                    */
/*                                                                   */
/* PURPOSE: Allocates a data set modeled after another data set.     */
/* The data set names are passed as arguments.                       */
/*-------------------------------------------------------------------*/
/*  TRACE R;   */
PARSE UPPER ARG NEWDSN LIKEDSN .
TEMP = LISTDSI("'"LIKEDSN"'" RECALL)
"ALLOC DA('"NEWDSN"')  BLKSIZE("SYSBLKSIZE") NEW LIKE ('"LIKEDSN"')",
  " DSORG("SYSDSORG") "
"FREE  DA('"NEWDSN"')"
SAY "ALLOCATING " NEWDSN;
EXIT
