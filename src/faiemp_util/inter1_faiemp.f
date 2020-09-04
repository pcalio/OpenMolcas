************************************************************************
* This file is part of OpenMolcas.                                     *
*                                                                      *
* OpenMolcas is free software; you can redistribute it and/or modify   *
* it under the terms of the GNU Lesser General Public License, v. 2.1. *
* OpenMolcas is distributed in the hope that it will be useful, but it *
* is provided "as is" and without any express or implied warranties.   *
* For more details see the full text of the license in the file        *
* LICENSE or in <http://www.gnu.org/licenses/>.                        *
************************************************************************
      Subroutine inter1_faiemp(Label,iBas_Lab,Coor,ZNUC,N_Cent)
************************************************************************
*                                                                      *
* Object: A routine similar to Inter1 but the list of atoms it builds  *
*         includes the expanded fragment's atoms.                      *
*         The original Inter1 routine is not modified as it is called  *
*         from numerous places and this routine is only used for the   *
*         generation of the MOLDEN file during SCF.                    *
*                                                                      *
************************************************************************
      Use Basis_Info
      Implicit None
#include "itmax.fh"
#include "info.fh"
#include "WrkSpc.fh"
      Real*8 A(3),Coor(3,*),ZNUC(*)
      integer Ibas_Lab(*),N_Cent
      Character*(LENIN) Lbl
      Character*(LENIN) Label(*)
      Logical DSCF
      Integer nDiff,mdc,ndc,iCnttp,iCnt,kop,iCo
      Real*8  A1,A2,A3
      Integer NrOpr,iPrmt
      External NrOpr,iPrmt

*
      DSCF=.False.
      nDiff=0
      Call IniSew(DSCF,nDiff)
*
      mdc=0
      ndc=0
      Do iCnttp=1,nCnttp
         If (dbsc(iCnttp)%pChrg.or.dbsc(iCnttp)%Aux.or.
     &       dbsc(iCnttp)%Frag) Then
           mdc = mdc + dbsc(iCnttp)%nCntr
           Go To 99
         End If
         Do iCnt=1,dbsc(iCnttp)%nCntr
            mdc=mdc+1
            Lbl=LblCnt(mdc)(1:LENIN)
            A(1:3)=Dbsc(iCnttp)%Coor(1:3,iCnt)
            Do iCo=0,nIrrep/nStab(mdc)-1
               ndc=ndc+1
               kop=iCoSet(iCo,0,mdc)
               A1=DBLE(iPrmt(NrOpr(kop,iOper,nIrrep),1))*A(1)
               A2=DBLE(iPrmt(NrOpr(kop,iOper,nIrrep),2))*A(2)
               A3=DBLE(iPrmt(NrOpr(kop,iOper,nIrrep),4))*A(3)
               Label(ndc)=Lbl(1:LENIN)
               iBas_Lab(ndc)=icnttp
               Coor(1,ndc)=A1
               Coor(2,ndc)=A2
               Coor(3,ndc)=A3
               ZNUC(ndc)=DBLE(dbsc(iCnttp)%AtmNr)
            End Do
         End Do
 99      Continue
      End Do
      n_cent=ndc
*
      Return
      End
