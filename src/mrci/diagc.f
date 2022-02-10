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
      SUBROUTINE DIAGC(INTSYM,C,S)
      IMPLICIT REAL*8 (A-H,O-Z)
#include "SysDef.fh"
#include "mrci.fh"
      DIMENSION INTSYM(*),C(*),S(*)
!
      JSYM(L)=JSUNP(INTSYM,L)
!
      IADD25=IAD25S
      CALL dDAFILE(Lu_25,2,COP,nCOP,IADD25)
      IIC=0
      IND=0
      ILIM=4
      IF(IFIRST.NE.0)ILIM=2
      IRL=IRC(ILIM)
      DO 100 INDA=1,IRL
      NSS=MUL(JSYM(INDA),LSYM)
      IF(INDA.GT.IRC(1))GO TO 120
      IIC=IIC+1
      IND=IND+1
      S(IND)=S(IND)+COP(IIC)*C(IND)
      IF(IIC.LT.nCOP)GO TO 100
      CALL dDAFILE(Lu_25,2,COP,nCOP,IADD25)
      IIC=0
      GO TO 100
120   IF(INDA.GT.IRC(2))GO TO 130
      NA1=NVIRP(NSS)+1
      NA2=NVIRP(NSS)+NVIR(NSS)
      IF(NA2.LT.NA1)GO TO 100
      DO 121 NA=NA1,NA2
      IIC=IIC+1
      IND=IND+1
      S(IND)=S(IND)+COP(IIC)*C(IND)
      IF(IIC.LT.nCOP)GO TO 121
      CALL dDAFILE(Lu_25,2,COP,nCOP,IADD25)
      IIC=0
121   CONTINUE
      GO TO 100
130   DO 141 NA=1,NVIRT
      NSA=MUL(NSS,NSM(LN+NA))
      NB1=NVIRP(NSA)+1
      NB2=NVIRP(NSA)+NVIR(NSA)
      IF(NB2.GT.NA)NB2=NA
      IF(NB2.LT.NB1)GO TO 141
      DO 142 NB=NB1,NB2
      IIC=IIC+1
      IND=IND+1
      S(IND)=S(IND)+COP(IIC)*C(IND)
      IF(IIC.LT.nCOP)GO TO 142
      CALL dDAFILE(Lu_25,2,COP,nCOP,IADD25)
      IIC=0
142   CONTINUE
141   CONTINUE
100   CONTINUE
      RETURN
      END
