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
      Subroutine Angular_Prune(Radius,nR,iAngular_Grid,Crowding,Fade,
     &                         R_BS,L_Quad,R_Min,lAng,nAngularGrids)
      use nq_Structure, only: Info_Ang
      Implicit Real*8 (a-h,o-z)
      Real*8 Radius(2,nR), R_Min(0:lAng)
      Integer iAngular_Grid(nR)
#include "real.fh"
*                                                                      *
************************************************************************
*                                                                      *
*define _DEBUGPRINT_
*                                                                      *
************************************************************************
*                                                                      *
      R_Test=R_BS/Crowding
#ifdef _DEBUGPRINT_
      Write (6,*) 'lAng=',lAng
      Write (6,*) 'Crowding=',Crowding
      Write (6,*) 'R_BS=',R_BS
      Write (6,*) 'L_Quad=',L_Quad
      Write (6,*) 'LMax_NQ=',SIZE(Info_Ang)
      Write (6,*) 'nAngularGrids=',nAngularGrids
      Write (6,*) 'R_Test=',R_Test
      Write (6,'(A,10G10.3)') 'R_Min=',R_Min
      Write (6,*) 'Info_Ang(*)%L_Eff=',
     &            (Info_Ang(i)%L_Eff,i=1,nAngularGrids)
#endif
      Do iR = 1, nR
*
         R_Value=Radius(1,iR)
#ifdef _DEBUGPRINT_
         Write (6,'(A,G10.3)') 'R_Value=',R_Value
#endif
*
*------- Establish L_Eff according to the crowding factor.
*
c        Avoid overflow by converting to Int at the end
         iAng=Int(Half*Min(L_Quad*R_Value/R_Test,DBLE(L_Quad)))
#ifdef _DEBUGPRINT_
         Write (6,*) 'iAng=',iAng
#endif
*
*------- Close to the nuclei we can use the alternative formula
*        given by the LMG radial grid.
*
         iAng=Max(iAng,lAng)
         Do jAng = lAng,1,-1
            If (R_Value.lt.R_Min(jAng)) iAng=Min(iAng,jAng-1)
         End Do
#ifdef _DEBUGPRINT_
         Write (6,*) 'iAng=',iAng
#endif
*
*       Fade the outer part
*
        R_Test2=Fade*R_BS
        If (R_Value.gt.R_Test2)
c          Avoid overflow by converting to Int at the end
     &     iAng=Int(Half*Min(L_Quad*R_Test2/R_Value,DBLE(L_Quad)))
*
*------- Since the Lebedev grid is not defined for any L_Eff
*        value we have to find the closest one, i.e. of the same
*        order or higher. Start loop from low order!
*
         kSet = 0
         Do jSet = 1, nAngularGrids
            If (Info_Ang(jSet)%L_Eff.ge.2*iAng+1.and.kSet.eq.0) Then
               kSet=jSet
               iAng=Info_Ang(kSet)%L_Eff/2
            End If
         End Do
         If (kSet.eq.0) Then
            kSet = nAngularGrids
            iAng=Info_Ang(kSet)%L_Eff/2
         End If
*
         iAngular_Grid(iR)=kSet
*
      End Do
#ifdef _DEBUGPRINT_
      Write (6,*)
      Write (6,*) 'iAngular_Grid:'
      Write (6,*) 'R_Min     R_Max    kSet  nR   nPoints'
      RStart=Radius(1,1)
      kSet=iAngular_Grid(1)
      nTot=Info_Ang(1)%nPoints
      mR=1
      Do iR = 2, nR
         nTot=nTot+Info_Ang(iAngular_Grid(iR))%nPoints
         If (iAngular_Grid(iR).ne.kSet.or.iR.eq.nR) Then
            jR=iR-1
            If (iR.eq.nR) Then
               jR=nR
               mR = mR + 1
            End If
            Write (6,'(2G10.3,I3,2I5)') RStart,Radius(1,jR),kSet,
     &                                 mR,Info_Ang(kSet)%nPoints
            RStart=Radius(1,iR)
            kSet=iAngular_Grid(iR)
            mR = 0
         End If
         mR = mR + 1
      End Do
      Write (6,*) 'Total grid size:',nTot
      Write (6,*)
#endif
*
      Return
      End
