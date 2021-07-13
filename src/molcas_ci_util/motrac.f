!***********************************************************************
! This file is part of OpenMolcas.                                     *
!                                                                      *
! OpenMolcas is free software; you can redistribute it and/or modify   *
! it under the terms of the GNU Lesser General Public License, v. 2.1. *
! OpenMolcas is distributed in the hope that it will be useful, but it *
! is provided "as is" and without any express or implied warranties.   *
! For more details see the full text of the license in the file        *
! LICENSE or in <http://www.gnu.org/licenses/>.                        *
!***********************************************************************
      SUBROUTINE MOTRAC(CMO,F,X1,X2)
!
!     RASSCF PROGRAM IBM-3090 VERSION: CI SECTION
!     PURPOSE: TRANSFORMS A MATRIX F WITH THE TRANSFORMATION MATRIX CMO
!              NORMALLY FROM AO TO MO BASIS. THE RESULT OVERWRITES THE
!              INITIAL MATRIX. SYMMETRY BLOCKED.
!              THE MATRIX F IS TRANSFORMED FROM FULL AO BASIS TO
!              ACTIVE ORBITAL MO BASIS.
!              INPUT AND OUTPUT MATRICES IN LOWER TRIANGULAR FORM.
!              CALLED FROM FCIN
!
!     ********** IBM-3090 RELEASE 86 12 05 **********
!
      IMPLICIT REAL*8 (A-H,O-Z)

#include "rasdim.fh"
#include "rasscf.fh"
#include "general.fh"
      DIMENSION CMO(*),F(*),X1(*),X2(*)
!
      LMOP=1
      ISTFA=1
      ISTFP=1
      DO 100 ISYM=1,NSYM
      NB=NBAS(ISYM)
      NA=NASH(ISYM)
      LMOP1=LMOP+NB*(NISH(ISYM)+NFRO(ISYM))
      IF(NA.EQ.0) GO TO 99
!
      CALL SQUARE(F(ISTFP),X1,1,NB,NB)
!      CALL MXMA(X1,1,NB,CMO(LMOP1),1,NB,X2,1,NB,NB,NB,NA)
      CALL DGEMM_('N','N',NB,NA,NB,                                     &
     &             1.0d0,X1,NB,                                         &
     &             CMO(LMOP1),NB,                                       &
     &             0.0d0,X2,NB)
      CALL MXMT(X2,NB,1,CMO(LMOP1),1,NB,F(ISTFA),NA,NB)
!
      ISTFA=ISTFA+ITRI(NA+1)
99    LMOP=LMOP+NB**2
      ISTFP=ISTFP+ITRI(NB+1)
100   CONTINUE
!
      RETURN
      END
