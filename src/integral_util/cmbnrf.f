************************************************************************
* This file is part of OpenMolcas.                                     *
*                                                                      *
* OpenMolcas is free software; you can redistribute it and/or modify   *
* it under the terms of the GNU Lesser General Public License, v. 2.1. *
* OpenMolcas is distributed in the hope that it will be useful, but it *
* is provided "as is" and without any express or implied warranties.   *
* For more details see the full text of the license in the file        *
* LICENSE or in <http://www.gnu.org/licenses/>.                        *
*                                                                      *
* Copyright (C) 1991,1992, Roland Lindh                                *
************************************************************************
      SubRoutine CmbnRF(Rnxyz,nZeta,la,lb,lr,Zeta,rKappa,Final,nComp,
     &                  Fact,Temp)
************************************************************************
*     Author: Roland Lindh, Dept. of Theoretical Chemistry,            *
*             University of Lund, SWEDEN                               *
*             Modified for reaction field calculations July '92        *
************************************************************************
      Implicit Real*8 (A-H,O-Z)
#include "print.fh"
#include "real.fh"
      Real*8 Final(nZeta,(la+1)*(la+2)/2,(lb+1)*(lb+2)/2,nComp),
     &       Zeta(nZeta), rKappa(nZeta), Fact(nZeta), Temp(nZeta),
     &       Rnxyz(nZeta,3,0:la,0:lb,0:lr)
*
*     Statement function for Cartesian index
*
      Ind(ixyz,ix,iz) = (ixyz-ix)*(ixyz-ix+1)/2 + iz + 1
      iOff(ixyz) = ixyz*(ixyz+1)*(ixyz+2)/6
*
      iRout = 134
      iPrint = nPrint(iRout)
*     Call GetMem(' Enter CmbnRF','LIST','REAL',iDum,iDum)
*
      Do 130 iZeta = 1, nZeta
         Fact(iZeta) = rKappa(iZeta) * Zeta(iZeta)**(-Three/Two)
130   Continue
      Do 10 ixa = 0, la
         iyaMax=la-ixa
      Do 11 ixb = 0, lb
         iybMax=lb-ixb
         Do 20 iya = 0, iyaMax
            iza = la-ixa-iya
            ipa= Ind(la,ixa,iza)
         Do 21 iyb = 0, iybMax
            izb = lb-ixb-iyb
            ipb= Ind(lb,ixb,izb)
*           If (iPrint.ge.99) Then
*              Write (*,*) ixa,iya,iza,ixb,iyb,izb
*              Write (*,*) ipa,ipb
*           End If
*
*           Combine multipole moment integrals
*
            Do 40 ix = 0, lr
               Do 41 iy = 0, lr-ix
                  Do 42 iZeta = 1, nZeta
                     Temp(iZeta) = Fact(iZeta) *
     &                             Rnxyz(iZeta,1,ixa,ixb,ix)*
     &                             Rnxyz(iZeta,2,iya,iyb,iy)
 42               Continue
                  Do 43 ir = ix+iy, lr
                     iz = ir-ix-iy
                     iComp=Ind(ir,ix,iz)+iOff(ir)
                     Do 30 iZeta = 1, nZeta
                        Final(iZeta,ipa,ipb,iComp) = Temp(iZeta)*
     &                          Rnxyz(iZeta,3,iza,izb,iz)
 30                  Continue
 43               Continue
 41            Continue
 40         Continue
*
 21      Continue
 20      Continue
 11   Continue
 10   Continue
*
      nFinal=nZeta*(la+1)*(la+2)/2*(lb+1)*(lb+2)/2
      If (iPrint.ge.99) Call RecPrt('Final',' ',Final,nFinal,nComp)
*
*     Call GetMem(' Exit CmbnRF','LIST','REAL',iDum,iDum)
      Return
      End
