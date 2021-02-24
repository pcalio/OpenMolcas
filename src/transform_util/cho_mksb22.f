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
* Copyright (C) 2005, Giovanni Ghigo                                   *
************************************************************************
      Subroutine MkExSB22(AddSB,iSymI,iSymJ,iSymA,iSymB, iI,iJ, numV)
************************************************************************
* Author :  Giovanni Ghigo                                             *
*           Lund University, Sweden & Torino University, Italy         *
*           February 2005                                              *
*----------------------------------------------------------------------*
* Purpuse:  Generation of the SubBlock(2,2) (p,q active) of the        *
*           two-electron integral matrix for each i,j occupied couple. *
************************************************************************
      use Cho_Tra
      Implicit Real*8 (a-h,o-z)
      Implicit Integer (i-n)
      Real*8, Allocatable:: AddSB(:)
      Integer iSymI,iSymJ,iSymA,iSymB, iI,iJ, numV
#include "rasdim.fh"
#include "stdalloc.fh"
#include "SysDef.fh"
      Logical SameLx

      Real*8, Allocatable:: Lx0(:), Ly0(:)

*   - SubBlock 2 2
      LenSB = nAsh(iSymA) * nAsh(iSymB)
      Call mma_allocate(AddSB,LenSB,Label='AddSB')

*     Build Lx
      Call mma_allocate(Lx0,nAsh(iSymA)*numV,Label='Lx0')
      LxType=0
      iIx=0
      SameLx=.False.
      Call MkL2(iSymA,iSymI,iI,numV, LxType,iIx, Lx0,SameLx)

*     Build Ly
      Call mma_allocate(Ly0,nAsh(iSymB)*numV,Label='Ly0')
      If(iSymA.EQ.iSymB) SameLx=.True.
      Call MkL2(iSymB,iSymJ,iJ,numV, LxType,iIx, Ly0,SameLx)

*     Generate the SubBlock
      If (.NOT.SameLx) then
        Call DGEMM_('N','T',nAsh(iSymB),nAsh(iSymA),numV,
     &              1.0d0,Ly0,nAsh(iSymB),
     &                    Lx0,nAsh(iSymA),
     &              0.0d0,AddSB,nAsh(iSymB) )
      else
        Call DGEMM_('N','T',nAsh(iSymA),nAsh(iSymA),numV,
     &              1.0d0,Lx0,nAsh(iSymA),
     &                    Lx0,nAsh(iSymA),
     &              0.0d0,AddSB,nAsh(iSymA) )
      EndIf

      Call mma_deallocate(Ly0)
      Call mma_deallocate(Lx0)

      Return
      End

      Subroutine MkCouSB22(AddSB,iSymI,iSymJ,iSymA,iSymB, iI,iJ, numV)
************************************************************************
* Author :  Giovanni Ghigo                                             *
*           Lund University, Sweden & Torino University, Italy         *
*           July 2005                                                  *
*----------------------------------------------------------------------*
* Purpuse:  Generation of the SubBlock(2,2) (p,q active) of the        *
*           two-electron integral matrix for each i,j occupied couple. *
************************************************************************
      use Cho_Tra
      Implicit Real*8 (a-h,o-z)
      Implicit Integer (i-n)
      Real*8, Allocatable:: AddSB(:)
#include "rasdim.fh"
#include "stdalloc.fh"
#include "SysDef.fh"

      Real*8, Allocatable:: Lij(:)

*   - SubBlock 2 2
      LenSB = nAsh(iSymA) * nAsh(iSymB)
      Call mma_allocate(AddSB,LenSB,Label='AddSB')

*     Define Lab
      LenAB  = LenSB
CGG   ------------------------------------------------------------------
c      If(IfTest) then
c      Write(6,*)'     MkCouSB22: TCVD(',iSymA,',',iSymB,')'
c      Write(6,'(8F10.6)')TCVX(4,iSymA,iSymB)%A(:,:)
c      Call XFlush(6)
c      EndIf
CGG   ------------------------------------------------------------------

*     Build Lij
      Call mma_allocate(Lij,NumV,Label='Lij')
      Call MkLij(iSymI,iSymJ,iI,iJ,numV,Lij)

*     Generate the SubBlock
      Call DGEMM_('N','N',LenAB,1,numV,
     &            1.0d0,TCVX(4,iSymA,iSymB)%A,LenAB,
     &                  Lij,NumV,
     &            0.0d0,AddSB,LenSB )

      Call mma_deallocate(Lij)

      Return
      End
