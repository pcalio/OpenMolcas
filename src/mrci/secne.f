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
      SUBROUTINE SECNE(A,B,C,NAL,NBL,NSIJ,IFT)
      IMPLICIT REAL*8 (A-H,O-Z)
      DIMENSION A(NAL,NBL),B(NBL,NAL),C(NBL,NAL)
      IF(IFT.EQ.0) THEN
        DO 20 NA=1,NAL
          DO 10 NB=1,NBL
          C(NB,NA)=B(NB,NA)+A(NA,NB)
10        CONTINUE
20      CONTINUE
      ELSE
        DO 40 NA=1,NAL
          DO 30 NB=1,NBL
          C(NB,NA)=B(NB,NA)-A(NA,NB)
30        CONTINUE
40      CONTINUE
      END IF
      RETURN
! Avoid unused argument warnings
      IF (.FALSE.) CALL Unused_integer(NSIJ)
      END
