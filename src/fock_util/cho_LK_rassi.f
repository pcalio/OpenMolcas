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
* Copyright (C) Francesco Aquilante                                    *
************************************************************************
      SUBROUTINE CHO_LK_RASSI(ipDLT,ipMSQ1,ipMSQ2,ipFLT,ipK,ipInt,
     &                              Ash,nScreen,dmpk)

**********************************************************************
*  Author : F. Aquilante
*
*  Note: this routine should be used only to compute the FI matrix
*        for cases in which the 2 sets of MOs are identical and
*        therefore FI is symmetric and stored as LT matrix.
*        For historical reasons, the routine is written as if it
*        could handle the more general case of different MOs.
*
*        Please, for that purpose, use CHO_LK_RASSI_X instead!
*
C *************** INACTIVE AO-BASIS FOCK MATRIX **********************
C
C   FI(ab) = 2 * sum_J  Lab,J * U(J)  -  sum_Jk  Xka,J * Ykb,J
C
C      U(J) = sum_gd  Lgd,J * DI(gd)
C
C      a,b,g,d:  AO-index
C      k:        MO-index   belonging to (Inactive)
C      v,w,x,y:  MO-indeces belonging to (Active)
C
**********************************************************************
      use ChoArr, only: nBasSh, nDimRS
      use ChoSwp, only: nnBstRSh, iiBstRSh, InfVec, IndRed
      use Data_Structures, only: DSBA_Type, SBA_Type
      use Data_Structures, only: Allocate_SBA, Deallocate_SBA
      use Data_Structures, only: twxy_Type
      use Data_Structures, only: Allocate_twxy, Deallocate_twxy
#if defined (_MOLCAS_MPP_)
      Use Para_Info, Only: nProcs, Is_Real_Par
#endif
      Implicit Real*8 (a-h,o-z)
#include "warnings.fh"
      Integer   kOff(8)
      Integer   ISTLT(8),ISTK(8),ISSQ(8,8)
      Real*8    tread(2),tcoul(2),texch(2),tintg(2)
      Real*8    tmotr(2),tscrn(2)

      Type (DSBA_Type) Ash(2)
      Type (SBA_Type) Laq(2)
      Type (twxy_Type) Scr

      Integer   ipMO(2),ipYk(2),ipMLk(2),ipIndsh(2),ipSk(2)
      Integer   ipMSQ(2),ipCM(2),ipY(2),ipML(2),ipIndx(2),ipSksh(2)
#ifdef _DEBUGPRINT_
      Logical   Debug
#endif
      Logical   DoReord,DoScreen, add
      Real*8    dmpk
      Character*50 CFmt
      Character(LEN=12), Parameter :: SECNAM = 'CHO_LK_RASSI'
#include "chotime.fh"
#include "lkscreen.fh"
#include "cho_jobs.fh"
#include "real.fh"

      Logical, Parameter ::  DoRead = .false.
      Real*8, Parameter :: FactCI = One, FactXI = -One, xone = -One

#include "rassi.fh"
#include "cholesky.fh"
#include "choorb.fh"
#include "WrkSpc.fh"
#include "stdalloc.fh"

      Character*6 mode
      Real*8   LKThr
      Integer, External :: Cho_F2SP
      Integer, External :: Cho_LK_MaxVecPerBatch
      Real*8,  External :: Cho_LK_ScreeningThreshold

      Real*8, Allocatable:: Lrs(:,:), Drs(:), Frs(:), VJ(:)

      Integer, Allocatable:: nnBfShp(:,:), ipLab(:,:), kOffSh(:,:)
************************************************************************
      MulD2h(i,j) = iEOR(i-1,j-1) + 1
******
      iTri(i,j) = max(i,j)*(max(i,j)-3)/2 + i + j
******
      iShp_rs(i) = iWork(ip_iShp_rs+i-1)
******
      SvShp(i) = Work(ip_SvShp+i-1)
****** next is a trick to save memory. Memory in "location 2" is used
******      to store this offset array defined later on
      iOffShp(i,j) = iiBstRSh(i,j,2)
************************************************************************

#ifdef _DEBUGPRINT_
      Debug=.false.! to avoid double printing in CASSCF-debug
#endif
      DoReord = .false.
      IREDC = -1  ! unknown reduced set in core
      ipMSQ(1)=ipMSQ1
      ipMSQ(2)=ipMSQ2

      nDen = 2  ! the two bi-orthonormal sets of orbitals
      If (Fake_CMO2) nDen = 1  ! MO1 = MO2
      kDen=nDen

      CALL CWTIME(TOTCPU1,TOTWALL1) !start clock for total time

      do i=1,2            ! 1 --> CPU   2 --> Wall
         tread(i) = zero  !time read/transform vectors
         tcoul(i) = zero  !time for computing Coulomb
         texch(i) = zero  !time for computing Exchange
         tintg(i) = zero  !time for computing (tw|xy) integrals
         tmotr(i) = zero  !time for the half-transf of vectors
         tscrn(i) = zero  !time for screening overhead
      end do

C ==================================================================

c --- Various offsets
c --------------------
      nnO=0
      kOff(1)=0
      MaxB=nBas(1)
      nsBB=nBas(1)**2
      ISTLT(1)=0
      ISTK(1)=0
      DO ISYM=2,NSYM
        MaxB=Max(MaxB,nBas(iSym))
        nsBB = nsBB + nBas(iSym)**2
        NBB=NBAS(ISYM-1)*(NBAS(ISYM-1)+1)/2
        ISTLT(ISYM)=ISTLT(ISYM-1)+NBB ! Inactive D and F matrices
        nK = nIsh(iSym-1) + nAsh(iSym-1)
        ISTK(ISYM)=ISTK(ISYM-1)+nBas(iSym-1)*nK ! Inact. MO coeff.
        nnO = nnO + nIsh(iSym-1)
        kOff(iSym)=nnO
      END DO
      nnO = nnO + nIsh(nSym)

      nnBSQ=0
      DO LSYM=1,NSYM
         DO KSYM=LSYM,NSYM
            ISSQ(KSYM,LSYM) = nnBSQ
            ISSQ(LSYM,KSYM) = nnBSQ ! symmetrization
            nnBSQ = nnBSQ + nBas(kSym)*nBas(lSym)
         END DO
      END DO

**************************************************
      If (Deco) Then

         Call GetMem('ChoMOs','Allo','Real',ipCM(1),nsBB*nDen)
         ipCM(2)=ipCM(1)+(nDen-1)*nsBB

         If (PseudoChoMOs) Then
            Call cho_get_MO(iOK,nDen,nSym,nBas,nIsh,ipMSQ,
     &                          ISTLT,ISTK,ipCM)
         Else
            Call cho_lr_MOs(iOK,nDen,nSym,nBas,nIsh,ipMSQ,
     &                          ISTLT,ISTK,ipCM)
         EndIf

         If (iOK.eq.0) Then ! point to the "generalized" Cholesky MOs
           do jden=1,nDen
              ipMSQ(jden)=ipCM(jden)
           end do
c           write(6,*)'Cholesky MOs used for state A'
c           If(nDen.eq.2)write(6,*)'Pseudo Cholesky MOs used for state B'
         Else
           write(6,*)'*******************************'
           write(6,*)'*** Resort to Canonical MOs ***'
           write(6,*)'*******************************'
         EndIf

      EndIf
**************************************************

C --- Define the max number of vectors to be treated in core at once

      MaxVecPerBatch=Cho_LK_MaxVecPerBatch()

C --- Define the screening threshold

C threshold for max BLB matrix element
C Note: must be consistent with threshold in subroutine rasscf/rasscf_init.f
      THRSX=1.D-04
      LKThr=Cho_LK_ScreeningThreshold(THRSX)
      tau = (LKThr/Max(1,nnO))*dmpk

      MaxRedT=MaxRed
      Call GAIGOP_SCAL(MaxRedT,'+')

      If (Estimate) tau=tau/MaxRedT

      xtau = sqrt(tau)

C --- Vector MO transformation screening thresholds
      NumVT=NumChT
      Call GAIGOP_SCAL(NumVT,'+')
      thrv = (sqrt(LKThr/(Max(1,nnO)*NumVT)))*dmpk

      CALL GETMEM('diagI','Allo','Real',ipDIAG,NNBSTRT(1))

#if defined (_MOLCAS_MPP_)
      If (nProcs.gt.1 .and. Update .and. Is_Real_Par()) Then
         NNBSTMX=0
         Do i=1,nSym
            NNBSTMX = Max(NNBSTMX,NNBSTR(i,1))
         End Do
         CALL GETMEM('diagJ','Allo','Real',ipjDIAG,NNBSTMX)
         Call FZero(Work(ipjDIAG),NNBSTMX)
      EndIf
#endif
C *************** Read the diagonal integrals (stored as 1st red set)
      If (Update) CALL CHO_IODIAG(Work(ipDIAG),2) ! 2 means "read"

c --- allocate memory for sqrt(D(a,b)) stored in full (squared) dim
      CALL GETMEM('diahI','Allo','Real',ipDIAH,NNBSQ)
      CALL FZERO(Work(ipDIAH),NNBSQ)

c --- allocate memory for the abs(C(l)[k])
      Call GetMem('absc','Allo','Real',ipAbs,MaxB)

      Do jDen=1,nDen
c --- allocate memory for the Y(l)[k] vectors
         Call GetMem('yc','Allo','Real',ipY(jDen),MaxB*nnO)
c --- allocate memory for the ML[k] lists of largest elements
c --- in significant shells
         Call GetMem('MLk','Allo','Real',ipML(jDen),nShell*nnO)
c --- allocate memory for the lists of  S:= sum_l abs(C(l)[k])
c --- for each shell
         Call GetMem('SKsh','Allo','Real',ipSKsh(jDen),nShell*nnO)
c --- allocate memory for the Index arrays
         Call GetMem('Indx','Allo','Inte',ipIndx(jDen),(nShell+1)*nnO)
      End Do

c --- allocate memory for ipLab
      Call mma_allocate(ipLab,nShell,nDen,Label='ipLab')

c --- allocate memory for kOffSh
      Call mma_allocate(kOffSh,nShell,nSym,Label='kOffSh')

c --- allocate memory for nnBfShp
      Call mma_allocate(nnBfShp,nnShl_tot,nSym,Label='nnBfShp')

c --- allocate memory for iShp_rs
      Call GetMem('ip_iShp_rs','Allo','Inte',ip_iShp_rs,nnShl_tot)

c --- allocate memory for the shell-pair Frobenius norm of the vectors
      Call GetMem('ip_SvShp','Allo','Real',ip_SvShp,2*nnShl)


C *** Compute Shell Offsets ( MOs and transformed vectors)

      MxBasSh = 0

      Do iSyma=1,nSym

         LKsh=0

         Do iaSh=1,nShell    ! kOffSh(iSh,iSym)

            kOffSh(iaSh,iSyma) = LKsh

            LKsh = LKsh + nBasSh(iSyma,iaSh)

            MxBasSh = Max(MxBasSh,nBasSh(iSyma,iaSh))

         End Do

      End Do


C --- allocate memory for the diagonal elements of the Fock matrix
      Call GetMem('F(k)ss','Allo','Real',ipFk,MxBasSh+nShell)
      Call FZero(Work(ipFk),MxBasSh+nShell)

C *** Determine S:= sum_l C(l)[k]^2  in each shell of C(a,k)
      Do jDen=1,nDen
         Do kSym=1,nSym

            Do jK=1,nIsh(kSym)

               ipMO(jDen) = ipMSQ(jDen) + ISTK(kSym) + nBas(kSym)*(jK-1)

               ipSk(jDen) = ipSKsh(jDen) + nShell*(kOff(kSym) + jK - 1)

               Do iaSh=1,nShell

                  ipMsh = ipMO(jDen) + kOffSh(iaSh,kSym)

                  SKsh=zero
                  Do ik=0,nBasSh(kSym,iaSh)-1
                     SKsh = SKsh + Work(ipMsh+ik)**2
                  End Do

                  Work(ipSk(jDen)+iaSh-1) = SKsh

               End Do

            End Do
         End Do
      End Do

C *** Compute Shell-pair Offsets in the K-matrix

         Do iSyma=1,nSym

            LKshp=0

            Do iaSh=1,nShell

             Do ibSh=1,iaSh

               iShp = iaSh*(iaSh-1)/2 + ibSh

              nnBfShp(iShp,iSyma) = LKShp

               LKShp = LKShp + nBasSh(iSyma,iaSh)*nBasSh(iSyma,ibSh)
     &                       - (1-Min((iaSh-ibSh),1))*nBasSh(iSyma,iaSh)
     &                       * (nBasSh(iSyma,iaSh) - 1)/2

             End Do

            End Do

         End Do

C *** Mapping shell pairs from the full to the reduced set

      Do iaSh=1,nShell
         Do ibSh=1,iaSh
            iShp = iaSh*(iaSh-1)/2 + ibSh
            iWork(ip_iShp_rs+iShp-1) = Cho_F2SP(iShp)
         End Do
      End Do



C *************** BIG LOOP OVER VECTORS SYMMETRY *******************
      DO jSym=1,nSym


         NumCV=NumCho(jSym)
         Call GAIGOP_SCAL(NumCV,'max')
         If (NumCV .lt. 1) GOTO 1000

C *** Compute Shell pair Offsets   iOffShp(iSyma,iShp)

         LFULL=0

         Do iaSh=1,nShell

          Do ibSh=1,iaSh

           iShp = iaSh*(iaSh-1)/2 + ibSh

           If (iShp_rs(iShp).gt.0) Then

            If (nnBstRSh(Jsym,iShp_rs(iShp),1).gt.0) Then

             Do iSymb=1,nSym

              iSyma=MulD2h(iSymb,Jsym)

              If (iSyma.ge.iSymb) Then

               iiBstRSh(iSyma,iShp_rs(iShp),2) = LFULL

                 LFULL = LFULL + nBasSh(iSyma,iaSh)*nBasSh(iSymb,ibSh)
     &        + Min(1,(iaSh-ibSh))*nBasSh(iSyma,ibSh)*nBasSh(iSymb,iaSh)

              EndIf

             End Do

            EndIf

           EndIf

          End Do

         End Do


      iCase=0 ! twxy
      Call Allocate_twxy(Scr,nAsh,nAsh,JSYM,nSym,iCase)

      iLoc = 3 ! use scratch location in reduced index arrays

C ****************     MEMORY MANAGEMENT SECTION    *****************
C ------------------------------------------------------------------
C --- compute memory needed to store at least 1 vector of JSYM
C --- and do all the subsequent calculations
C ------------------------------------------------------------------
         mTvec1= 0
         mTvec2= 0
         MxB=0
         do l=1,nSym
            k=Muld2h(l,JSYM)
            Mmax = Max(0,nIsh(k))
            If (Mmax.gt.0) MxB = Max(MxB,nBas(l))
            mTvec1= mTvec1+ nAsh(k)*nBas(l)
            mTvec2= mTvec2+ nAsh(k)*nAsh(l)
         end do
         mTvec = mTvec1 + mTvec2

         LFMAX = Max(mTvec,LFULL) ! re-use memory for the active vec
         mTvec = nDen*Max(MxB,1) ! mem for storing half-transformed vec

C ------------------------------------------------------------------
C ------------------------------------------------------------------

         JRED1 = InfVec(1,2,jSym)  ! red set of the 1st vec
         JRED2 = InfVec(NumCho(jSym),2,jSym) !red set of the last vec
#if defined (_MOLCAS_MPP_)
         myJRED1=JRED1 ! first red set present on this node
         ntv0=0
#endif
         myJRED2=JRED2 ! last  red set present on this node

c --- entire red sets range for parallel run
         Call GAIGOP_SCAL(JRED1,'min')
         Call GAIGOP_SCAL(JRED2,'max')

         kscreen=1
         DoScreen=.true.

         Do JRED=JRED1,JRED2

            CALL Cho_X_nVecRS(JRED,JSYM,iVrs,nVrs)

            If (nVrs.eq.0) GOTO 999  ! no vectors in that (jred,jsym)

            if (nVrs.lt.0) then
               Write(6,*)SECNAM//': Cho_X_nVecRS returned nVrs<0. STOP!'
               call Abend
            endif

            Call Cho_X_SetRed(irc,iLoc,JRED)
c           !set index arrays at iLoc
            if(irc.ne.0)then
              Write(6,*)SECNAM//'cho_X_setred non-zero return code.'//
     &                          ' rc= ',irc
              call Abend
            endif

            IREDC=JRED

            nRS = nDimRS(JSYM,JRED)

            If(JSYM.eq.1)Then
               Call mma_allocate(Drs,nRS,Label='Drs')
               Call mma_allocate(Frs,nRS,Label='Frs')
               Drs(:)=Zero
               Frs(:)=Zero
            EndIf

            Call mma_maxDBLE(LWORK)

            nVec = min(LWORK/(nRS+mTvec+LFMAX),min(nVrs,MaxVecPerBatch))

            If (nVec.lt.1) Then
               WRITE(6,*) SECNAM//': Insufficient memory for batch'
               WRITE(6,*) 'LWORK= ',LWORK
               WRITE(6,*) 'min. mem. need= ',nRS+mTvec+LFMAX
               WRITE(6,*) 'nRS= ',nRS
               WRITE(6,*) 'mTvec= ',mTvec
               WRITE(6,*) 'LFMAX= ',LFMAX
               WRITE(6,*) 'jsym= ',jsym
               CALL Quit(_RC_MEMORY_ERROR_)
               nBatch = -9999  ! dummy assignment
            End If

            LREAD = nRS*nVec

            Call mma_allocate(Lrs,nRS,nVec,Label='Lrs')

            If(JSYM.eq.1)Then
C --- Transform the density to reduced storage
               mode = 'toreds'
               add = .False.
               nMat=1
               Call swap_rs2full(irc,iLoc,nRS,nMat,JSYM,
     &                           [ipDLT],Drs,mode,add)
            EndIf

C --- BATCH over the vectors ----------------------------

            nBatch = (nVrs-1)/nVec + 1

            DO iBatch=1,nBatch

               If (iBatch.eq.nBatch) Then
                  JNUM = nVrs - nVec*(nBatch-1)
               else
                  JNUM = nVec
               endif

               JVEC = nVec*(iBatch-1) + iVrs
               IVEC2 = JVEC - 1 + JNUM

               CALL CWTIME(TCR1,TWR1)

               CALL CHO_VECRD(Lrs,LREAD,JVEC,IVEC2,JSYM,
     &                        NUMV,IREDC,MUSED)

               If (NUMV.le.0 .or.NUMV.ne.JNUM ) then
                  RETURN
               End If

               CALL CWTIME(TCR2,TWR2)
               tread(1) = tread(1) + (TCR2 - TCR1)
               tread(2) = tread(2) + (TWR2 - TWR1)

               If(JSYM.eq.1)Then
C ************ (alpha+beta) COULOMB CONTRIBUTION  ****************
C
C --- Contraction with the density matrix
C ---------------------------------------
C --- V{#J} <- V{#J}  +  sum_rs  L(rs,{#J}) * DI(rs)
C==========================================================
C
                  CALL CWTIME(TCC1,TWC1)

                  Call mma_allocate(VJ,JNUM,Label='VJ')

                  CALL DGEMV_('T',nRS,JNUM,
     &                 ONE,Lrs,nRS,
     &                 Drs,1,ZERO,VJ,1)

C --- FI(rs){#J} <- FI(rs){#J} + FactCI * sum_J L(rs,{#J})*V{#J}
C===============================================================

                  Fact = dble(min(jVec-iVrs,1))

                  CALL DGEMV_('N',nRS,JNUM,
     &                 FactCI,Lrs,nRS,
     &                 VJ,1,Fact,Frs,1)

                  Call mma_deallocate(VJ)

                  CALL CWTIME(TCC2,TWC2)
                  tcoul(1) = tcoul(1) + (TCC2 - TCC1)
                  tcoul(2) = tcoul(2) + (TWC2 - TWC1)

               EndIf  ! Coulomb contribution

               Call GetMem('ChoT','Allo','Real',ipChoT,mTvec*nVec)
               CALL GETMEM('FullV','Allo','Real',ipLF,LFMAX*nVec)

C *************** EXCHANGE CONTRIBUTIONS  ***********************

               CALL CWTIME(TCS1,TWS1)
C ---------------------------------------------------------------------
C --- Estimate the diagonals :   D(a,b) = sum_J (Lab,J)^2
C
               If (Estimate) Then

                  Call Fzero(Work(ipDiag+iiBstR(jSym,1)),NNBSTR(jSym,1))

                  Do krs=1,nRS

                     mrs = iiBstR(JSYM,iLoc) + krs
                     jrs = IndRed(mrs,iLoc) ! address in 1st red set

                     Do jvc=1,JNUM

                        Work(ipDiag+jrs-1) = Work(ipDiag+jrs-1)
     &                                  + Lrs(krs,jvc)**2

                     End Do

                  End Do

               EndIf

               CALL CWTIME(TCS2,TWS2)
               tscrn(1) = tscrn(1) + (TCS2 - TCS1)
               tscrn(2) = tscrn(2) + (TWS2 - TWS1)

               CALL CWTIME(TCX1,TWX1)

C *** Reorder vectors to Full-dimensions
C ***
C *** Vectors are returned in the storage LaJ,b with the restriction:
C ***
C ***    Sym(a).ge.Sym(b)
C ***
C *** and blocked in shell pairs

               CALL FZero(Work(ipLF),LFULL*JNUM)
               CALL FZero(Work(ip_SvShp),2*nnShl)

               CALL CHO_getShFull(Lrs,lread,JNUM,JSYM,
     &                            IREDC,ipLF,Work(ip_SvShp),
     &                            iWork(ip_iShp_rs))


               CALL CWTIME(TCX2,TWX2)
               texch(1) = texch(1) + (TCX2 - TCX1)
               texch(2) = texch(2) + (TWX2 - TWX1)


               IF (DoScreen) THEN

                   CALL CWTIME(TCS1,TWS1)

c --- Compute DH(a,b)=sqrt(D(a,b)) from the updated diagonals.
c ---                              Only the symmetry blocks with
c ---                              compound symmetry JSYM are computed
c --------------------------------------------------------------------
                   mode = 'tosqrt'
                   add = .False.
                   ired1 = 1 ! location of the 1st red set
                   nMat=1
                   Call swap_rs2full(irc,ired1,NNBSTRT(1),nMat,JSYM,
     &                               [ipDIAH],Work(ipDIAG),mode,add)

                   CALL CWTIME(TCS2,TWS2)
                   tscrn(1) = tscrn(1) + (TCS2 - TCS1)
                   tscrn(2) = tscrn(2) + (TWS2 - TWS1)

               ENDIF


               Do kSym=1,nSym

                  lSym=MulD2h(JSYM,kSym)

                  Do jK=1,nIsh(kSym)

                   CALL FZero(Work(ipChoT),nDen*nBas(lSym)*JNUM)

                   Do jDen=1,nDen

                    ipMO(jDen) = ipMSQ(jDen) + ISTK(kSym)
     &                         + nBas(kSym)*(jK-1)

                    ipYk(jDen) = ipY(jDen) + MaxB*(kOff(kSym)+jK-1)

                    ipMLk(jDen) = ipML(jDen) + nShell*(kOff(kSym)+jK-1)
                    ipIndSh(jDen) = ipIndx(jDen)
     &                            + (nShell+1)*(kOff(kSym) + jK - 1)
                    ipSk(jDen) = ipSKsh(jDen) + nShell*(kOff(kSym)+jK-1)

                   End Do

                   IF (DoScreen) THEN

                     CALL CWTIME(TCS1,TWS1)
C------------------------------------------------------------------
C --- Setup the screening
C------------------------------------------------------------------
                     ipDIH = ipDIAH + ISSQ(lSym,kSym)

                     Do jDen=1,nDen

                        Do ik=0,nBas(kSym)-1
                           Work(ipAbs+ik) = abs(Work(ipMO(jDen)+ik))
                        End Do

                        If (lSym.ge.kSym) Then
c --------------------------------------------------------------
C --- Y(l)[k] = sum_n  DH(l,n) * |C(n)[k]|
C===============================================================
                           nBs = Max(1,nBas(lSym))

                           CALL DGEMV_('N',nBas(lSym),nBas(kSym),
     &                                ONE,Work(ipDIH),nBs,
     &                                    Work(ipAbs),1,
     &                               ZERO,Work(ipYk(jDen)),1)

                        Else
c --------------------------------------------------------------
C --- Y(l)[k] = sum_n  DH(n,l) * |C(n)[k]|
C===============================================================
                           nBs = Max(1,nBas(kSym))

                           CALL DGEMV_('T',nBas(kSym),nBas(lSym),
     &                                ONE,Work(ipDIH),nBs,
     &                                    Work(ipAbs),1,
     &                               ZERO,Work(ipYk(jDen)),1)

                        EndIf

c            write(6,*)'Y(k)= ',(Work(ipYk(jDen)+i-1),i=1,nBas(lSym))
c            write(6,*)'|C(k)|= ',(Work(ipAbs+i-1),i=1,nBas(kSym))

                     End Do

c            Call recprt('DH','',Work(ipDIH),nBas(lSym),nBas(kSym))

C --- List the shells present in Y(l)[k] by the largest element
                     Do jDen=1,nDen
                        Do ish=1,nShell
                           YshMax=zero
                           Do ibs=1,nBasSh(lSym,ish)
                              YshMax = Max(YshMax,
     &                          Work(ipYk(jDen)+koffSh(ish,lSym)+ibs-1))
                           End Do
                           Work(ipMLk(jDen)+ish-1) = YshMax
                        End Do
                     End Do


C --- Sort the lists ML[k]
                     Do jDen=1,nDen
                        Do ish=1,nShell
                           iWork(ipIndSh(jDen)+ish) = ish
                        End Do
                     End Do

C ****  The Max in the MO set 1 is used as reference
                     numSh1=0  ! # of significant shells in MO set 1
                     YMax=Work(ipMLk(1))
                     jmlmax=1
                     Do iml=2,nShell  ! get the max in the MO set 1
                        If (Work(ipMLk(1)+iml-1).gt.YMax) then
                           YMax = Work(ipMLk(1)+iml-1)
                           jmlmax = iml
                        Endif
                     End Do
                     If (jmlmax.ne.1) then  ! swap positions
                        xTmp = Work(ipMLk(1))
                        iTmp = iWork(ipIndSh(1)+1)
                        Work(ipMLk(1)) = YMax
                        iWork(ipIndSh(1)+1) = iWork(ipIndSh(1)+jmlmax)
                        Work(ipMLk(1)+jmlmax-1) = xTmp
                        iWork(ipIndSh(1)+jmlmax) = iTmp
                     Endif

C **** Sort the list for the MO set 2   iff  MOs1.ne.MOs2
                     If (.not.Fake_CMO2) Then
                       numSh2=0  ! # of significant shells in MO set 2
                       jml=1
                       Do while (jml.le.nShell)

                         YMax=Work(ipMLk(2)+jml-1)
                         jmlmax=jml

                         Do iml=jml+1,nShell  ! get the max
                           If (Work(ipMLk(2)+iml-1).gt.YMax) then
                              YMax = Work(ipMLk(2)+iml-1)
                              jmlmax = iml
                           Endif
                         End Do

                         If(jmlmax.ne.jml) then  ! swap positions
                          xTmp = Work(ipMLk(2)+jml-1)
                          iTmp = iWork(ipIndSh(2)+jml)
                          Work(ipMLk(2)+jml-1) = YMax
                          iWork(ipIndSh(2)+jml)=iWork(ipIndSh(2)+jmlmax)
                          Work(ipMLk(2)+jmlmax-1) = xTmp
                          iWork(ipIndSh(2)+jmlmax) = iTmp
                         Endif

c --- Exact bounds (quadratic scaling of the MO transformation)
c --- Note that in true RASSI the exchange matrix is not
c --- positive definite.
c
                         If(Work(ipMLk(2)+jml-1)*Work(ipMLk(1))
     &                                         .ge.tau)then
                           numSh2 = numSh2 + 1
                         else
                           jml=nShell  ! exit the loop
                         endif

                         jml=jml+1

                       End Do

                       iWork(ipIndSh(2)) = numSh2
                       numSh1 = 1

                     Else ! fake biorthonormal basis

                       numSh2 = 6669666 ! dummy assignement

                       If (Work(ipMLk(1)) .ge. xtau)  numSh1 = 1

                     EndIf

C **** Sort the list for the MO set 1 only if needed
                     If(numSh2.gt.0) then
                       jml=2 ! the 1st element has already been treated
                       Do while (jml.le.nShell)

                          YMax=Work(ipMLk(1)+jml-1)
                          jmlmax=jml
                          Do iml=jml+1,nShell  ! get the max
                             If (Work(ipMLk(1)+iml-1).gt.YMax) then
                                YMax = Work(ipMLk(1)+iml-1)
                                jmlmax = iml
                             Endif
                          End Do

                          If(jmlmax.ne.jml) then  ! swap positions
                            xTmp = Work(ipMLk(1)+jml-1)
                            iTmp = iWork(ipIndSh(1)+jml)
                            Work(ipMLk(1)+jml-1) = YMax
                            iWork(ipIndSh(1)+jml) =
     &                                      iWork(ipIndSh(1)+jmlmax)
                            Work(ipMLk(1)+jmlmax-1) = xTmp
                            iWork(ipIndSh(1)+jmlmax) = iTmp
                          Endif

                          If( .not.Fake_CMO2  .and.
     &                       Work(ipMLk(1)+jml-1)*Work(ipMLk(kDen))
     &                                             .ge.tau)then
                             numSh1 = numSh1 + 1

c --- Here we use a non-exact bound for the exchange matrix because a
c     fake rassi (MOs1=MOs2) has a positive definite exchange
                          ElseIf ( Fake_CMO2  .and.
     &                             Work(ipMLk(1)+jml-1) .ge. xtau ) then
                             numSh1 = numSh1 + 1
                          Else
                             jml=nShell  ! exit the loop
                          Endif

                          jml=jml+1

                       End Do
                     Else
                       numSh1 = 0
                     EndIf

                     iWork(ipIndSh(1)) = numSh1

c      Do jDen=1,nDen
c         write(6,*)'ord-ML(k)= ',(Work(ipMLk(jDen)+i-1),i=1,nShell)
c         write(6,*)'Ind-ML(k)= ',(iWork(ipIndSh(jDen)+i-1),i=1,nShell+1)
c      End Do
c         write(6,*)'lSym,kSym,jSym,jk,nShell,numSh1,numSh2= ',lSym,
c     &              kSym,jSym,jk,nShell,numSh1,numSh2

                     CALL CWTIME(TCS2,TWS2)
                     tscrn(1) = tscrn(1) + (TCS2 - TCS1)
                     tscrn(2) = tscrn(2) + (TWS2 - TWS1)
C------------------------------------------------------------------
                   ENDIF    ! Screening setup

C --- Transform vectors for shells in the lists ML[k]
C
C --- Screening based on the Frobenius norm: sqrt(sum_ij A(i,j)^2)
C
C ---  || La,J[k] ||  .le.  || Lab,J || * || Cb[k] ||

                      CALL CWTIME(TCT1,TWT1)

                      Do jDen=1,nDen

                         IF (lSym.ge.kSym) Then


                            Do iSh=1,iWork(ipIndSh(jDen))

                               iaSh = iWork(ipIndSh(jDen)+iSh)

                               iOffSha = kOffSh(iaSh,lSym)

                               ipLab(iaSh,jDen) = ipChoT + iOffSha*JNUM
     &                                        + (jDen-1)*nBas(lSym)*JNUM

                               ibcount=0

                               Do ibSh=1,nShell

                                  iOffShb = kOffSh(ibSh,kSym)

                                  iShp = iTri(iaSh,ibSh)

                                  If (iShp_rs(iShp) .gt. 0) Then

                                   If(nnBstRSh(JSym,iShp_rs(iShp),iLoc)*
     &                                nBasSh(lSym,iaSh)*
     &                                nBasSh(kSym,ibSh) .gt. 0
     &                           .and. sqrt(abs(Work(ipSk(jDen)+ibSh-1)*
     &                           SvShp(iShp_rs(iShp)) )) .ge. thrv )Then

                                    ibcount = ibcount + 1

c                                   jOff = iOffShp(lSym,iShp)

c                                   if (iaSh.lt.ibSh) jOff = jOff +
c     &                               nBasSh(lSym,ibSh)*nBasSh(kSym,iaSh)

                                    jOff = iOffShp(lSym,iShp_rs(iShp)) -
     &                                             nBasSh(lSym,ibSh)*
     &                                             nBasSh(kSym,iaSh)*
     &                             Min(0,(iaSh-ibSh))/Max(1,(ibSh-iaSh))


C ---  LaJ,[k] = sum_b  L(aJ,b) * C(b)[k]
C ---------------------------------------

                                 CALL DGEMV_('N',nBasSh(lSym,iaSh)*JNUM,
     &                                        nBasSh(kSym,ibSh),
     &                                    ONE,Work(ipLF+jOff*JNUM),
     &                                        nBasSh(lSym,iaSh)*JNUM,
     &                                     Work(ipMO(jDen)+ioffShb),1,
     &                                    ONE,Work(ipLab(iaSh,jDen)),1)


                                   EndIf

                                  EndIf

                               End Do

c --- The following re-assignement is used later on to check if the
c --- iaSh vector LaJ[k] can be neglected because identically zero

                               ipLab(iash,jDen) =
     &                               ipLab(iaSh,jDen)*Min(1,ibcount)
     &                             + ipAbs*(1-Min(1,ibcount))


                            End Do


                         Else   ! lSym < kSym


                            Do iSh=1,iWork(ipIndSh(jDen))

                               iaSh = iWork(ipIndSh(jDen)+iSh)

                               iOffSha = kOffSh(iaSh,lSym)

                               ipLab(iaSh,jDen) = ipChoT + iOffSha*JNUM
     &                                     + (jDen-1)*nBas(lSym)*JNUM

                               ibcount=0

                               Do ibSh=1,nShell

                                  iOffShb = kOffSh(ibSh,kSym)

                                  iShp = iTri(iaSh,ibSh)

                                  If (iShp_rs(iShp) .gt. 0) Then

                                   If(nnBstRSh(JSym,iShp_rs(iShp),iLoc)*
     &                                nBasSh(lSym,iaSh)*
     &                                nBasSh(kSym,ibSh) .gt. 0
     &                           .and. sqrt(abs(Work(ipSk(jDen)+ibSh-1)*
     &                           SvShp(iShp_rs(iShp)) )) .ge. thrv )Then

                                   ibcount = ibcount + 1

                                   jOff = iOffShp(kSym,iShp_rs(iShp)) -
     &                                      nBasSh(kSym,iaSh)*
     &                                      nBasSh(lSym,ibSh)*
     &                             Min(0,(ibSh-iaSh))/Max(1,(iaSh-ibSh))


C ---  LJa,[k] = sum_b  L(b,Ja) * C(b)[k]
C ---------------------------------------

                                    CALL DGEMV_('T',nBasSh(kSym,ibSh),
     &                                       JNUM*nBasSh(lSym,iaSh),
     &                                    ONE,Work(ipLF+jOff*JNUM),
     &                                        nBasSh(kSym,ibSh),
     &                                     Work(ipMO(jDen)+ioffShb),1,
     &                                    ONE,Work(ipLab(iaSh,jDen)),1)


                                    EndIf

                                  Endif

                               End Do

c --- The following re-assignement is used later on to check if the
c --- iaSh vector LaJ[k] can be neglected because identically zero

                               ipLab(iaSh,jDen) =
     &                               ipLab(iaSh,jDen)*Min(1,ibcount)
     &                             + ipAbs*(1-Min(1,ibcount))


                            End Do

                         EndIf


                      End Do

                      CALL CWTIME(TCT2,TWT2)
                      tmotr(1) = tmotr(1) + (TCT2 - TCT1)
                      tmotr(2) = tmotr(2) + (TWT2 - TWT1)

C --- Prepare the J-screening

                      CALL CWTIME(TCS1,TWS1)

                      IF (lSym.ge.kSym) Then


                         Do iSh=1,iWork(ipIndSh(1))

                            iaSh = iWork(ipIndSh(1)+iSh)

                            ipFaa = ipFk + MxBasSh + iaSh - 1

                            iaSkip=Min(1,Max(0,
     &                             abs(ipLab(iaSh,1)-ipAbs))) ! = 1 or 0

                            jaSkip=Min(1,Max(0,
     &                             abs(ipLab(iaSh,kDen)-ipAbs)))

                            Do i=1,iaSkip*jaSkip  ! 0 or 1

C ---  Faa,[k] = sum_J  LaJ[k1]*LaJ[k2]
C -------------------------------------
                               Do jv=1,JNUM

                                  xfjv = dble(min(1,jv-1))

                                  Do ia=1,nBasSh(lSym,iaSh)

                                     ipFia = ipFk + ia - 1

                                     ipLai = ipLab(iaSh,1)
     &                                     + nBasSh(lSym,iaSh)*(jv-1)
     &                                     + ia - 1

                                     ipLaj = ipLab(iaSh,kDen)
     &                                     + nBasSh(lSym,iaSh)*(jv-1)
     &                                     + ia - 1

                                     Work(ipFia) = xfjv*Work(ipFia)
     &                                        + Work(ipLai)*Work(ipLaj)
                                  End Do
                               End Do

                               CALL FindMax(ipFk,'N',
     &                                      nBasSh(lSym,iaSh),
     &                                      1,ipFaa)

                            End Do

                         End Do

                      Else   ! lSym < kSym


                         Do iSh=1,iWork(ipIndSh(1))

                            iaSh = iWork(ipIndSh(1)+iSh)

                            ipFaa = ipFk + MxBasSh + iaSh - 1

                            iaSkip=Min(1,Max(0,
     &                             abs(ipLab(iaSh,1)-ipAbs))) ! = 1 or 0

                            jaSkip=Min(1,Max(0,
     &                             abs(ipLab(iaSh,kDen)-ipAbs)))

                            Do i=1,iaSkip*jaSkip

C ---  Faa,[k] = sum_J  LJa[k1]*LJa[k2]
C -------------------------------------
                               Do ia=1,nBasSh(lSym,iaSh)

                                  ipFia = ipFk + ia - 1

                                  Do jv=1,JNUM

                                     xfjv = dble(min(1,jv-1))

                                     ipLai = ipLab(iaSh,1)
     &                                     + JNUM*(ia-1)
     &                                     + jv - 1

                                     ipLaj = ipLab(iaSh,kDen)
     &                                     + JNUM*(ia-1)
     &                                     + jv - 1

                                     Work(ipFia) = xfjv*Work(ipFia)
     &                                        + Work(ipLai)*Work(ipLaj)
                                  End Do
                               End Do

                               CALL FindMax(ipFk,'N',
     &                                      nBasSh(lSym,iaSh),
     &                                      1,ipFaa)

                            End Do

                         End Do


                      EndIf

                      CALL CWTIME(TCS2,TWS2)
                      tscrn(1) = tscrn(1) + (TCS2 - TCS1)
                      tscrn(2) = tscrn(2) + (TWS2 - TWS1)


C------------------------------------------------------------
C --- Compute exchange matrix for the interacting shell pairs
C------------------------------------------------------------

                      CALL CWTIME(TCX1,TWX1)

                      IF (lSym.ge.kSym) Then

                         Do lSh=1,iWork(ipIndSh(1))

                            iaSh = iWork(ipIndSh(1)+lSh)

                            ipFaa = ipFk + MxBasSh + iaSh - 1

                            iaSkip=Min(1,Max(0,
     &                            abs(ipLab(iaSh,1)-ipAbs))) ! = 1 or 0

                            iOffSha = kOffSh(iaSh,lSym)

                            mSh = 1

                            Do while (mSh.le.iWork(ipIndSh(kDen)))

                               ibSh = iWork(ipIndSh(kDen)+mSh)

                               ipFbb = ipFk + MxBasSh + ibSh - 1

                               ibSkip = Min(1,Max(0,
     &                                  abs(ipLab(ibSh,kDen)-ipAbs)))

                               iShp = iTri(iaSh,ibSh)

                               iOffShb = kOffSh(ibSh,lSym)

                               iOffAB = nnBfShp(iShp,lSym)

                               ipKI = ipK + ISTLT(lSym) + iOffAB

                               xFab = sqrt(abs(Work(ipFaa)*Work(ipFbb)))

                               If (Work(ipMLk(1)+lSh-1)*
     &                             Work(ipMLk(kDen)+mSh-1).lt.tau) Then


                                   mSh = iWork(ipIndSh(kDen)) !skip rest


                               ElseIf (iaSh.eq.ibSh
     &                                 .and. xFab.ge.tau/MaxRedT
     &                                 .and. iaSkip*ibSkip.eq.1) Then

C ---  F(a,b)[k] = F(a,b)[k] + FactXI * sum_J  X1(a,J)[k] * X2(b,J)[k]
C --------------------------------------------------------------------
                               nBs = Max(1,nBasSh(lSym,iaSh))

                               CALL DGEMM_Tri('N','T',nBasSh(lSym,iaSh),
     &                                           nBasSh(lSym,ibSh),JNUM,
     &                                      FActXI,Work(ipLab(iaSh,1)),
     &                                           nBs,
     &                                           Work(ipLab(ibsh,kDen)),
     &                                           nBs,
     &                                       ONE,Work(ipKI),
     &                                               nBs)

                               ElseIf (iaSh.gt.ibSh
     &                                 .and. xFab.ge.tau/MaxRedT
     &                                 .and. iaSkip*ibSkip.eq.1) Then

C ---  F(a,b)[k] = F(a,b)[k] + FactXI * sum_J  X1(a,J)[k] * X2(b,J)[k]
C --------------------------------------------------------------------
                                  nBsa = Max(1,nBasSh(lSym,iaSh))
                                  nBsb = Max(1,nBasSh(lSym,ibSh))

                                  CALL DGEMM_('N','T',nBasSh(lSym,iaSh),
     &                                           nBasSh(lSym,ibSh),JNUM,
     &                                      FactXI,Work(ipLab(iaSh,1)),
     &                                           nBsa,
     &                                           Work(ipLab(ibsh,kDen)),
     &                                           nBsb,
     &                                       ONE,Work(ipKI),
     &                                               nBsa)

                               EndIf


                               mSh = mSh + 1  ! update shell counter


                            End Do

                         End Do


                      ELSE   ! lSym < kSym


                         Do lSh=1,iWork(ipIndSh(1))

                            iaSh = iWork(ipIndSh(1)+lSh)

                            ipFaa = ipFk + MxBasSh + iaSh - 1

                            iaSkip=Min(1,Max(0,
     &                            abs(ipLab(iaSh,1)-ipAbs))) ! = 1 or 0

                            iOffSha = kOffSh(iaSh,lSym)

                            mSh = 1

                            Do while (mSh.le.iWork(ipIndSh(kDen)))

                               ibSh = iWork(ipIndSh(kDen)+mSh)

                               ipFbb = ipFk + MxBasSh + ibSh - 1

                               ibSkip = Min(1,Max(0,
     &                                  abs(ipLab(ibSh,kDen)-ipAbs)))

                               iShp = iTri(iaSh,ibSh)

                               iOffShb = kOffSh(ibSh,lSym)

                               iOffAB = nnBfShp(iShp,lSym)

                               ipKI = ipK + ISTLT(lSym) + iOffAB

                               xFab = sqrt(abs(Work(ipFaa)*Work(ipFbb)))

                               If (Work(ipMLk(1)+lSh-1)*
     &                             Work(ipMLk(kDen)+mSh-1).lt.tau) Then


                                   mSh = iWork(ipIndSh(kDen))
c                                  ! skip rest


                               ElseIf (iaSh.eq.ibSh
     &                                 .and. xFab.ge.tau/MaxRedT
     &                                 .and. iaSkip*ibSkip.eq.1) Then

C ---  F(a,b)[k] = F(a,b)[k] + FactXI * sum_J  X1(J,a)[k] * X2(J,b)[k]
C --------------------------------------------------------------------

                               nBs = Max(1,nBasSh(lSym,iaSh))

                               CALL DGEMM_Tri('T','N',nBasSh(lSym,iaSh),
     &                                           nBasSh(lSym,ibSh),JNUM,
     &                                      FActXI,Work(ipLab(iaSh,1)),
     &                                             JNUM,
     &                                           Work(ipLab(ibsh,kDen)),
     &                                           JNUM,
     &                                           ONE,Work(ipKI),
     &                                                nBs)


                               ElseIf (iaSh.gt.ibSh
     &                                 .and. xFab.ge.tau/MaxRedT
     &                                 .and. iaSkip*ibSkip.eq.1) Then

C ---  F(a,b)[k] = F(a,b)[k] + FactXI * sum_J  X1(J,a)[k] * X2(J,b)[k]
C --------------------------------------------------------------------

                                  nBs = Max(1,nBasSh(lSym,iaSh))

                                  CALL DGEMM_('T','N',nBasSh(lSym,iaSh),
     &                                           nBasSh(lSym,ibSh),JNUM,
     &                                     FactXI,Work(ipLab(iaSh,1)),
     &                                           JNUM,
     &                                           Work(ipLab(ibsh,kDen)),
     &                                           JNUM,
     &                                       ONE,Work(ipKI),
     &                                               nBs)

                               EndIf


                               mSh = mSh + 1  ! update shell counter


                            End Do

                         End Do


                      ENDIF

                      CALL CWTIME(TCX2,TWX2)
                      texch(1) = texch(1) + (TCX2 - TCX1)
                      texch(2) = texch(2) + (TWX2 - TWX1)


                  End Do  ! loop over k MOs


               End Do   ! loop over MOs symmetry


               DoScreen=.false. ! avoid redo screening inside batch loop

C --- Diagonals updating. It only makes sense if Nscreen > 0

               If (Update .and. Nscreen .gt. 0) Then

                  CALL CWTIME(TCS1,TWS1)
C ---------------------------------------------------------------------
C --- update the diagonals :   D(a,b) = D(a,b) - sum_J (Lab,J)^2
C
C --- subtraction is done in the 1st reduced set
#if defined (_MOLCAS_MPP_)
                  If (nProcs .gt. 1 .and. Is_Real_Par()) then

                   Do krs=1,nRS

                     mrs = iiBstR(JSYM,iLoc) + krs
                     jrs = IndRed(mrs,iLoc) - iiBstR(JSYM,1)

                     Do jvc=1,JNUM

                        Work(ipjDiag+jrs-1) = Work(ipjDiag+jrs-1)
     &                                      + Lrs(krs,jvc)**2
                     End Do

                   End Do

                  Else

                   Do krs=1,nRS

                     mrs = iiBstR(JSYM,iLoc) + krs
                     jrs = IndRed(mrs,iLoc) ! address in 1st red set

                     Do jvc=1,JNUM

                        Work(ipDiag+jrs-1) = Work(ipDiag+jrs-1)
     &                                     - Lrs(krs,jvc)**2
                     End Do

                   End Do

                  EndIf

#else
                  Do krs=1,nRS

                     mrs = iiBstR(JSYM,iLoc) + krs
                     jrs = IndRed(mrs,iLoc) ! address in 1st red set

                     Do jvc=1,JNUM

                        Work(ipDiag+jrs-1) = Work(ipDiag+jrs-1)
     &                                     - Lrs(krs,jvc)**2
                     End Do

                  End Do
#endif

                  CALL CWTIME(TCS2,TWS2)
                  tscrn(1) = tscrn(1) + (TCS2 - TCS1)
                  tscrn(2) = tscrn(2) + (TWS2 - TWS1)

               EndIf

C ************  END EXCHANGE CONTRIBUTION  ****************
               Call GetMem('ChoT','Free','Real',ipChoT,mTvec*nVec)
               CALL GETMEM('FullV','Free','Real',ipLF,LFMAX*nVec)

               iSwap = 0  ! Lvb,J are returned
               Call Allocate_SBA(Laq(1),nAsh,nBas,nVec,JSYM,nSym,iSwap)
               Call Allocate_SBA(Laq(2),nAsh,nAsh,nVec,JSYM,nSym,iSwap)
C --------------------------------------------------------------------
C --- First half Active transformation  Lvb,J = sum_a  C1(v,a) * Lab,J
C --------------------------------------------------------------------

               CALL CWTIME(TCINT1,TWINT1)

C --- The memory used before for the full-dimension AO-vectors
C ---     is now re-used to store half and full transformed
C ---     vectors in the active space
C -------------------------------------------------------------

               kMOs = 1  !
               nMOs = 1  ! Active MOs (1st set)

               CALL CHO_X_getVtra(irc,Lrs,LREAD,jVEC,JNUM,
     &                           JSYM,iSwap,IREDC,nMOs,kMOs,Ash,
     &                           Laq,DoRead)


               if (irc.ne.0) then
                  RETURN
               endif

C --------------------------------------------------------------------
C --- Active-Active transformation  Lvw,J = sum_b  Lvb,J * C2(w,b)
C --------------------------------------------------------------------
                  Do iSymb=1,nSym

                     iSymv = MulD2h(JSYM,iSymb)
                     NAv = nAsh(iSymv)
                     NAw = nAsh(iSymb) ! iSymb=iSymw

                     If(NAv*NAw.ne.0)Then

                      Do JVC=1,JNUM


                       CALL DGEMM_('N','T',NAv,NAw,NBAS(iSymb),
     &                            One,Laq(1)%SB(iSymv)%A3(:,:,JVC),NAv,
     &                                Ash(kDen)%SB(iSymb)%A2,NAw,
     &                           Zero,Laq(2)%SB(iSymv)%A3(:,:,JVC),NAv)

                      End Do

                     EndIf

                  End Do

C
C
C *************** EVALUATION OF THE (TW|XY) INTEGRALS ***********

               DoReord = JRED.eq.myJRED2.and.iBatch.eq.nBatch

               CALL CHO_rassi_twxy(irc,Scr,Laq(2),ipInt,nAsh,
     &                                 JSYM,JNUM,DoReord)

               CALL CWTIME(TCINT2,TWINT2)
               tintg(1) = tintg(1) + (TCINT2 - TCINT1)
               tintg(2) = tintg(2) + (TWINT2 - TWINT1)

               if (irc.ne.0) then
                  RETURN
               endif

C ---------------- END (TW|XY) EVALUATION -----------------------

               Call Deallocate_SBA(Laq(2))
               Call Deallocate_SBA(Laq(1))

            END DO  ! end batch loop


            If(JSYM.eq.1)Then
c --- backtransform fock matrix to full storage
               mode = 'tofull'
               add =.True.
               nMat = 1
               Call swap_rs2full(irc,iLoc,nRS,nMat,JSYM,
     &                           [ipFLT],Frs,mode,add)
            EndIf

C --- free memory
            Call mma_deallocate(Lrs)

            If(JSYM.eq.1)Then
              Call mma_deallocate(Frs)
              Call mma_deallocate(Drs)
            EndIf


999         Continue

C --- Screening control section
            DoScreen = kscreen.eq.Nscreen

            if (.not.DoScreen) then
                kscreen = kscreen + 1
            else
                kscreen = 1
            endif

#if defined (_MOLCAS_MPP_)
            If (nProcs.gt.1 .and. Update .and. DoScreen
     &          .and. Is_Real_Par()) Then
               Call GaDsum(Work(ipjDiag),nnBSTR(JSYM,1))
               Call Daxpy_(nnBSTR(JSYM,1),xone,Work(ipjDiag),1,
     &                    Work(ipDiag+iiBstR(JSYM,1)),1)
               Call Fzero(Work(ipjDiag),nnBSTR(JSYM,1))
            EndIf
C--- Need to activate the screening to setup the contributing shell
C--- indeces the first time the loop is entered .OR. whenever other nodes
C--- have performed screening in the meanwhile
            If (nProcs.gt.1 .and. .not.DoScreen .and. nVrs.eq.0
     &          .and. Is_Real_Par()) Then
               ntv0=ntv0+1
               DoScreen = (JRED.lt.myJRED1 .or. ntv0.ge.Nscreen)
               if (DoScreen) ntv0=0
            EndIf
#endif

         END DO   ! loop over red sets


         Call Deallocate_twxy(Scr)

1000  CONTINUE


      END DO  ! loop over JSYM

* --- Accumulate Coulomb and Exchange contributions
      Do iSym=1,nSym

         ipFI = ipFLT + ISTLT(iSym)
         ipKI = ipK   + ISTLT(iSym)

         Do iaSh=1,nShell

            ioffa = kOffSh(iaSh,iSym)

c --- ibSh < iaSh
c ---------------
            Do ibSh=1,iaSh-1

               iShp = iaSh*(iaSh-1)/2 + ibSh

               iOffAB = nnBfShp(iShp,iSym)

               ioffb = kOffSh(ibSh,iSym)

               Do ib=1,nBasSh(iSym,ibSh)

                Do ia=1,nBasSh(iSym,iaSh)

                  iab = nBasSh(iSym,iaSh)*(ib-1) + ia

                  jK = ipKI - 1 + iOffAB + iab

                  iag = ioffa + ia
                  ibg = ioffb + ib

                  jF = ipFI - 1 + iTri(iag,ibg)

                  Work(jF) = Work(jF) + Work(jK)

                End Do

               End Do

            End Do

c --- ibSh = iaSh
c ---------------
            iShp = iaSh*(iaSh+1)/2

            iOffAB = nnBfShp(iShp,iSym)

            Do ib=1,nBasSh(iSym,iaSh)

              Do ia=ib,nBasSh(iSym,iaSh)

                 iab = ia*(ia-1)/2 + ib

                 jK = ipKI - 1 + iOffAB + iab

                 iag = ioffa + ia
                 ibg = ioffa + ib

                 jF = ipFI - 1 + iag*(iag-1)/2 + ibg

                 Work(jF) = Work(jF) + Work(jK)

              End Do

            End Do

         End Do

      End Do


      Call GetMem('F(k)ss','Free','Real',ipFk,MxBasSh+nShell)
      Call GetMem('ip_SvShp','Free','Real',ip_SvShp,2*nnShl)
      Call GetMem('ip_iShp_rs','Free','Inte',ip_iShp_rs,nnShl_tot)
      Call mma_deallocate(nnBfShp)
      Call mma_deallocate(kOffSh)
      Call mma_deallocate(ipLab)
      Do jDen=nDen,1,-1
         Call GetMem('Indx','Free','Inte',ipIndx(jDen),(nShell+1)*nnO)
         Call GetMem('SKsh','Free','Real',ipSKsh(jDen),nShell*nnO)
         Call GetMem('MLk','Free','Real',ipML(jDen),nShell*nnO)
         Call GetMem('yc','Free','Real',ipY(jDen),MaxB*nnO)
      End Do
      Call GetMem('absc','Free','Real',ipAbs,MaxB)
      CALL GETMEM('diahI','Free','Real',ipDIAH,NNBSQ)
#if defined (_MOLCAS_MPP_)
      If (nProcs.gt.1 .and. Update .and. Is_Real_Par())
     &    CALL GETMEM('diagJ','Free','Real',ipjDIAG,NNBSTMX)
#endif
      CALL GETMEM('diagI','Free','Real',ipDIAG,NNBSTRT(1))

      If (Deco) Call GetMem('ChoMOs','Free','Real',ipCM(1),nsBB*nDen)

      CALL CWTIME(TOTCPU2,TOTWALL2)
      TOTCPU = TOTCPU2 - TOTCPU1
      TOTWALL= TOTWALL2 - TOTWALL1


*
*---- Write out timing information
      if(timings)then

      CFmt='(2x,A)'
      Write(6,*)
      Write(6,CFmt)'Cholesky RASSI timing from '//SECNAM
      Write(6,CFmt)'----------------------------------------'
      Write(6,*)
      Write(6,CFmt)'- - - - - - - - - - - - - - - - - - - - - - - - -'
      Write(6,CFmt)'Fock matrix construction        CPU       WALL   '
      Write(6,CFmt)'- - - - - - - - - - - - - - - - - - - - - - - - -'

         Write(6,'(2x,A26,2f10.2)')'READ VECTORS                     '
     &                           //'         ',tread(1),tread(2)
         Write(6,'(2x,A26,2f10.2)')'COULOMB                          '
     &                           //'         ',tcoul(1),tcoul(2)
         Write(6,'(2x,A26,2f10.2)')'EXCHANGE                         '
     &                           //'         ',texch(1),texch(2)
         Write(6,'(2x,A26,2f10.2)')'(TW|XY) INTEGRALS                '
     &                           //'         ',tintg(1),tintg(2)
         Write(6,*)
         Write(6,'(2x,A26,2f10.2)')'TOTAL                            '
     &                           //'         ',TOTCPU,TOTWALL
      Write(6,CFmt)'- - - - - - - - - - - - - - - - - - - - - - - - -'
      Write(6,*)

      endif


c Print the Fock-matrix
#ifdef _DEBUGPRINT_
      if(Debug) then !to avoid double printing in RASSI-debug

      WRITE(6,'(6X,A)')'TEST PRINT FROM '//SECNAM
      WRITE(6,'(6X,A)')
      WRITE(6,'(6X,A)')'***** INACTIVE FOCK MATRIX ***** '
      DO ISYM=1,NSYM
        ISFI=ipFLT+ISTLT(ISYM)
        IF( NBAS(ISYM).GT.0 ) THEN
          WRITE(6,'(6X,A)')
          WRITE(6,'(6X,A,I2)')'SYMMETRY SPECIES:',ISYM
          call TRIPRT('','',Work(ISFI),NBAS(ISYM))
        ENDIF
      END DO

      endif

#endif

      Return
      END
