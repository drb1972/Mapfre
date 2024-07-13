/*********************************************************************/
/*                                                                   */
/*  COPYRIGHT (C) 1986-2013 CA. ALL RIGHTS RESERVED.                */
/*                                                                   */
/* NAME: BC1GM100                                                    */
/*                                                                   */
/* FUNCTION: THIS ISPF/PDF EDIT MACRO IS THE INITIAL MACRO INVOKED   */
/* BY THE PDM WIP EDIT FUNCTION.  IT WILL ESTABLISH DEFINITIONS AND  */
/* ALIASES FOR THE STANDARD WIP EDIT MACROS.                         */
/*                                                                   */
/*********************************************************************/

ISREDIT MACRO (PARMS) NOPROCESS

ISREDIT DEFINE BC1GM101 CMD MACRO
ISREDIT DEFINE WIPLDEL ALIAS BC1GM101

ISREDIT DEFINE BC1GM102 CMD MACRO
ISREDIT DEFINE WIPSHOW ALIAS BC1GM102

ISREDIT DEFINE BC1GM103 CMD MACRO
ISREDIT DEFINE WIPCON ALIAS BC1GM103

ISREDIT DEFINE BC1GM104 CMD MACRO
ISREDIT DEFINE WIPCOUNT ALIAS BC1GM104

ISREDIT DEFINE BC1GM105 CMD MACRO
ISREDIT DEFINE WIPCHANG ALIAS BC1GM105

ISREDIT DEFINE BC1GM106 CMD MACRO
ISREDIT DEFINE WIPPARA ALIAS BC1GM106

ISREDIT DEFINE BC1GM107 CMD MACRO
ISREDIT DEFINE WIPUNDEL ALIAS BC1GM107

ISREDIT DEFINE BC1GM108 CMD MACRO
ISREDIT DEFINE WIPHELP ALIAS BC1GM108

ISREDIT DEFINE BC1G1520 PGM MACRO
ISREDIT DEFINE WIPMERGE ALIAS BC1G1520

/*********************************************************************/
/* CALL THE PDM INITIAL EDIT MACRO INSTALLATION CLIST.               */
/*********************************************************************/
%BC1GMU01

