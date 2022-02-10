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
      SUBROUTINE DIAGRO(CI,SGM,CBUF,SBUF,DBUF,AREF,EREF,                &
     &              CSECT,RSECT,XI1,XI2,CNEW,SCR,ICI)
      IMPLICIT REAL*8 (A-H,O-Z)
#include "SysDef.fh"
#include "warnings.h"
#include "mrci.fh"
#include "WrkSpc.fh"
      DIMENSION CI(NCONF),SGM(NCONF)
      DIMENSION CBUF(MBUF,MXVEC),SBUF(MBUF,MXVEC),DBUF(MBUF)
      DIMENSION AREF(NREF,NREF),EREF(NREF)
      DIMENSION CSECT(NSECT,MXVEC),RSECT(NSECT,MXVEC)
      DIMENSION XI1(NSECT,NRROOT),XI2(NSECT,NRROOT)
      DIMENSION CNEW(NSECT,NRROOT),SCR(*)
      DIMENSION ICI(MBUF)
      DIMENSION IDC(MXVEC),IDS(MXVEC)
      DIMENSION HCOPY(MXVEC,MXVEC),SCOPY(MXVEC,MXVEC)
      DIMENSION PCOPY(MXVEC,MXVEC)
      DIMENSION ELAST(MXROOT),PSEL(MXVEC),RNRM(MXROOT)
!      DIMENSION EPERT(MXROOT)
!
      WRITE(6,*)
      WRITE(6,*)('-',I=1,60)
      IF (ICPF.EQ.0) THEN
         WRITE(6,*)'   MR SDCI CALCULATION.'
      ELSE
         WRITE(6,*)'   MR ACPF CALCULATION.'
      END IF
      WRITE(6,*)('-',I=1,60)
      WRITE(6,*)
      WRITE(6,*)'         CONVERGENCE STATISTICS:'
      WRITE(6,'(1X,A)')'ITER NVEC     ENERGIES    LOWERING'//           &
     & ' RESIDUAL SEL.WGT CPU(S) CPU TOT'
      ITER=0
      CALL SETTIM
      CALL TIMING(CPTNOW,DUM,DUM,DUM)
      CPTOLD=CPTNOW
      CPTSTA=CPTNOW
! LOOP HEAD FOR CI ITERATIONS:
1000  CONTINUE
      ITER=ITER+1
! -------------------------------------------------------------------
! CALCULATE SIGMA ARRAYS FOR SHIFTED HAMILTONIAN IN MCSF BASIS:
      DO 100 I=1,NNEW
         IVEC=1+MOD(NVTOT-NNEW+I-1,MXVEC)
         IDISK=IDISKC(IVEC)
         DO 110 ISTA=1,NCONF,MBUF
            NN=MIN(MBUF,NCONF+1-ISTA)
            CALL iDAFILE(LUEIG,2,ICI,NN,IDISK)
            CALL UPKVEC(NN,ICI,CI(ISTA))
110      CONTINUE
         CALL GETMEM('BMN','ALLO','REAL',LBMN,NBMN)
         CALL GETMEM('IBMN','ALLO','INTE',LIBMN,NBMN)
         CALL GETMEM('BIAC2','ALLO','REAL',LBIAC2,ISMAX)
         CALL GETMEM('BICA2','ALLO','REAL',LBICA2,ISMAX)
         CALL GETMEM('BFIN3','ALLO','REAL',LBFIN3,KBUFF1)
         CALL GETMEM('AC1','ALLO','REAL',LAC1,ISMAX)
         CALL GETMEM('AC2','ALLO','REAL',LAC2,ISMAX)
         CALL GETMEM('BFIN4','ALLO','REAL',LBFIN4,KBUFF1)
         CALL GETMEM('ABIJ','ALLO','REAL',LABIJ,NVSQ)
         CALL GETMEM('AIBJ','ALLO','REAL',LAIBJ,NVSQ)
         CALL GETMEM('AJBI','ALLO','REAL',LAJBI,NVSQ)
         CALL GETMEM('ASCR1','ALLO','REAL',LASCR1,NVMAX**2)
         CALL GETMEM('BSCR1','ALLO','REAL',LBSCR1,NVMAX**2)
         CALL GETMEM('FSCR1','ALLO','REAL',LFSCR1,NVSQ)
         CALL GETMEM('FSEC','ALLO','REAL',LFSEC,2*NVSQ)
         CALL GETMEM('BFIN5','ALLO','REAL',LBFIN5,KBUFF1)
         CALL GETMEM('ASCR2','ALLO','REAL',LASCR2,NVMAX**2)
         CALL GETMEM('BSCR2','ALLO','REAL',LBSCR2,NVMAX**2)
         CALL GETMEM('FSCR2','ALLO','REAL',LFSCR2,NVSQ)
         CALL GETMEM('DBK','ALLO','REAL',LDBK,2*NVSQ)
!vv         CALL SIGMA(HWORK,CI,SGM)
!pam         CALL SIGMA(HWORK)
!PAM04         CALL SIGMA(HWork(LSGM),HWork(LAREF),HWork(LCI),HWork(LINTSY),
!PAM04     &        HWork(LINDX),HWork(LBMN),HWork(LIBMN),HWork(LBIAC2),
         CALL SIGMA(SGM,AREF,CI,IWork(LINTSY),                          &
     &        IWork(LINDX),Work(LBMN),IWork(LIBMN),Work(LBIAC2),        &
!PAM04     &        HWork(LBICA2),HWork(LBFIN3),HWork(LFIJKL),HWork(LISAB),
     &        Work(LBICA2),Work(LBFIN3),IWork(LISAB),                   &
!PAM04     &        HWork(LAC1),HWork(LAC2),HWork(LBFIN4),HWork(LABIJ),
     &        Work(LAC1),Work(LAC2),Work(LBFIN4),Work(LABIJ),           &
!PAM04     &        HWork(LAIBJ),HWork(LAJBI),HWork(LBFIN1),HWork(LASCR1),
     &        Work(LAIBJ),Work(LAJBI),Work(LASCR1),                     &
!PAM04     &        HWork(LBSCR1),HWork(LFSCR1),HWork(LFSEC),HWork(LFOCK),
     &        Work(LBSCR1),Work(LFSCR1),Work(LFSEC),Work(LFOCK),        &
     &        Work(LBFIN5),Work(LASCR2),Work(LBSCR2),                   &
!PAM04     &        HWork(LFSCR2),HWork(LDBK),HWork(LCSPCK))
     &        Work(LFSCR2),Work(LDBK),IWork(LCSPCK))
         CALL GETMEM('BFIN5','FREE','REAL',LBFIN5,KBUFF1)
         CALL GETMEM('ASCR2','FREE','REAL',LASCR2,NVMAX**2)
         CALL GETMEM('BSCR2','FREE','REAL',LBSCR2,NVMAX**2)
         CALL GETMEM('FSCR2','FREE','REAL',LFSCR2,NVSQ)
         CALL GETMEM('DBK','FREE','REAL',LDBK,2*NVSQ)
         CALL GETMEM('ABIJ','FREE','REAL',LABIJ,NVSQ)
         CALL GETMEM('AIBJ','FREE','REAL',LAIBJ,NVSQ)
         CALL GETMEM('AJBI','FREE','REAL',LAJBI,NVSQ)
         CALL GETMEM('ASCR1','FREE','REAL',LASCR1,NVMAX**2)
         CALL GETMEM('BSCR1','FREE','REAL',LBSCR1,NVMAX**2)
         CALL GETMEM('FSCR1','FREE','REAL',LFSCR1,NVSQ)
         CALL GETMEM('FSEC','FREE','REAL',LFSEC,2*NVSQ)
         CALL GETMEM('BMN','FREE','REAL',LBMN,NBMN)
         CALL GETMEM('IBMN','FREE','INTE',LIBMN,NBMN)
         CALL GETMEM('BIAC2','FREE','REAL',LBIAC2,ISMAX)
         CALL GETMEM('BICA2','FREE','REAL',LBICA2,ISMAX)
         CALL GETMEM('BFIN3','FREE','REAL',LBFIN3,KBUFF1)
         CALL GETMEM('AC1','FREE','REAL',LAC1,ISMAX)
         CALL GETMEM('AC2','FREE','REAL',LAC2,ISMAX)
         CALL GETMEM('BFIN4','FREE','REAL',LBFIN4,KBUFF1)
         NSTOT=NSTOT+1
! WRITE IT OUT:
         IVEC=1+MOD(NSTOT-1,MXVEC)
         IDISK=IDISKS(IVEC)
         IF(IDISK.EQ.-1) IDISK=IDFREE
         DO 120 ISTA=1,NCONF,MBUF
            NN=MIN(MBUF,NCONF+1-ISTA)
            CALL dDAFILE(LUEIG,1,SGM(ISTA),NN,IDISK)
120      CONTINUE
         IF (IDISK.GT.IDFREE) THEN
            IDISKS(IVEC)=IDFREE
            IDFREE=IDISK
         END IF
100   CONTINUE
! -------------------------------------------------------------------
! NR OF VECTORS PRESENTLY RETAINED:
      NVEC=MIN(MXVEC,NVTOT)
! NR OF OLD VECTORS RETAINED:
      NOLD=NVEC-NNEW
! -------------------------------------------------------------------
! COPY HSMALL, SSMALL AND PSMALL IN REORDERED FORM, BY AGE:
      DO 206 L=NNEW+1,NVEC
         LL=1+MOD(NVTOT-L,MXVEC)
         DO 2060 K=NNEW+1,NVEC
            KK=1+MOD(NVTOT-K,MXVEC)
            HCOPY(K,L)=HSMALL(KK,LL)
            SCOPY(K,L)=SSMALL(KK,LL)
            PCOPY(K,L)=PSMALL(KK,LL)
2060     CONTINUE
206   CONTINUE
! CLEAR NEW AREAS TO BE USED:
      DO 207 K=1,NVEC
         DO 2070 L=1,NNEW
            HCOPY(K,L)=0.0D00
            SCOPY(K,L)=0.0D00
            PCOPY(K,L)=0.0D00
2070     CONTINUE
207   CONTINUE
! THEN LOOP OVER BUFFERS. FIRST GET COPIES OF DISK ADDRESSES:
      DO 210 K=1,NVEC
         IDC(K)= IDISKC(K)
         IDS(K)= IDISKS(K)
210   CONTINUE
      DO 200 ISTA=1,NCONF,MBUF
         IEND=MIN(NCONF,ISTA+MBUF-1)
         IBUF=1+IEND-ISTA
         DO 220 K=1,NVEC
            KK=1+MOD(NVTOT-K,MXVEC)
            CALL iDAFILE(LUEIG,2,ICI,IBUF,IDC(KK))
            CALL UPKVEC(IBUF,ICI,CBUF(1,K))
            IF(K.GT.NNEW) GOTO 220
            CALL dDAFILE(LUEIG,2,SBUF(1,K),IBUF,IDS(KK))
220      CONTINUE
! -------------------------------------------------------------------
! NOTE: AT THIS POINT, THE COLUMNS NR 1..NVEC OF CBUF WILL
! CONTAIN THE BUFFERS OF, FIRST, THE NNEW NEWEST PSI ARRAYS,
! THEN, THE NOLD ONES FROM EARLIER ITERATIONS.
! THE COLUMNS 1..NNEW OF SBUF WILL CONTAIN THE NEWEST NNEW
! SIGMA ARRAYS. LEADING DIMENSION OF CBUF AND SBUF IS MBUF. ACTUAL
! BUFFER SIZE IS IBUF, WHICH CAN BE SMALLER. ACCUMULATE:
         CALL DGEMM_('T','N',                                           &
     &               NVEC,NNEW,IBUF,                                    &
     &               1.0d0,CBUF,MBUF,                                   &
     &               CBUF,MBUF,                                         &
     &               0.0d0,SCR,NVEC)
         KL=0
         DO 230 L=1,NNEW
            DO 231 K=1,NVEC
               KL=KL+1
               SCOPY(K,L)=SCOPY(K,L)+SCR(KL)
231         CONTINUE
230      CONTINUE
         CALL DGEMM_('T','N',                                           &
     &               NVEC,NNEW,IBUF,                                    &
     &               1.0d0,CBUF,MBUF,                                   &
     &               SBUF,MBUF,                                         &
     &               0.0d0,SCR,NVEC)
         KL=0
         DO 240 L=1,NNEW
            DO 241 K=1,NVEC
               KL=KL+1
               HCOPY(K,L)=HCOPY(K,L)+SCR(KL)
241         CONTINUE
240      CONTINUE
! ALSO, UPDATE PSMALL, WHICH IS USED FOR SELECTION.
         IF(ISTA.GT.IREFX(NRROOT)) GOTO 200
         DO 250 I=1,NRROOT
            IR=IROOT(I)
            IRR=IREFX(IR)
            IF(IRR.LT.ISTA) GOTO 250
            IF(IRR.GT.IEND) GOTO 250
            IPOS=IRR+1-ISTA
            DO 260 L=1,NNEW
               DO 261 K=1,NVEC
                  PCOPY(K,L)=PCOPY(K,L)+CBUF(IPOS,K)*CBUF(IPOS,L)
261            CONTINUE
260         CONTINUE
250      CONTINUE
200   CONTINUE
! TRANSFER ELEMENTS BACK TO HSMALL, ETC.
       DO 256 L=1,NNEW
          LL=1+MOD(NVTOT-L,MXVEC)
          DO 2560 K=1,NVEC
             KK=1+MOD(NVTOT-K,MXVEC)
             H=HCOPY(K,L)
             S=SCOPY(K,L)
             P=PCOPY(K,L)
             HCOPY(L,K)=H
             SCOPY(L,K)=S
             PCOPY(L,K)=P
             HSMALL(KK,LL)=H
             SSMALL(KK,LL)=S
             PSMALL(KK,LL)=P
             HSMALL(LL,KK)=H
             SSMALL(LL,KK)=S
             PSMALL(LL,KK)=P
2560     CONTINUE
256   CONTINUE
      IF(IPRINT.GE.10) THEN
        WRITE(6,*)
        WRITE(6,*)' HSMALL MATRIX:'
        DO 251 I=1,NVEC
          WRITE(6,'(1X,5F15.6)')(HSMALL(I,J),J=1,NVEC)
251     CONTINUE
        WRITE(6,*)
        WRITE(6,*)' SSMALL MATRIX:'
        DO 252 I=1,NVEC
          WRITE(6,'(1X,5F15.6)')(SSMALL(I,J),J=1,NVEC)
252     CONTINUE
        WRITE(6,*)
         WRITE(6,*)' PSMALL MATRIX:'
         DO 253 I=1,NVEC
           WRITE(6,'(1X,5F15.6)')(PSMALL(I,J),J=1,NVEC)
253      CONTINUE
!        WRITE(6,*)
!        WRITE(6,*)
!        WRITE(6,*)' HCOPY MATRIX:'
!        DO 1251 I=1,NVEC
!          WRITE(6,'(1X,5F15.6)')(HCOPY(I,J),J=1,NVEC)
!1251    CONTINUE
!        WRITE(6,*)
!        WRITE(6,*)' SCOPY MATRIX:'
!        DO 1252 I=1,NVEC
!          WRITE(6,'(1X,5F15.6)')(SCOPY(I,J),J=1,NVEC)
!1252    CONTINUE
!        WRITE(6,*)
      END IF
! -------------------------------------------------------------------
! THE UPPER-LEFT NVEC*NVEC SUBMATRICES OF HSMALL AND SSMALL NOW
! CONTAINS THE CURRENT HAMILTONIAN AND OVERLAP MATRICES, IN THE
! BASIS OF PRESENTLY RETAINED PSI VECTORS. DIAGONALIZE, BUT USE
! THE REORDERED MATRICES IN SCOPY, HCOPY,DCOPY. THERE THE BASIS
! FUNCTIONS ARE ORDERED BY AGE.
      THR=1.0D-06
      CALL SECULAR(MXVEC,NVEC,NRON,HCOPY,SCOPY,                         &
     &                VSMALL,ESMALL,SCR,THR)
! REORDER THE ELEMENTS OF VSMALL TO GET EIGENVECTORS OF HSMALL. NOTE:
! THIS IS NOT THE SAME AS IF WE DIAGONALIZED HSMALL DIRECTLY.
! THE DIFFERENCE OCCURS WHENEVER VECTORS ARE THROWN OUT OF THE
! CALCULATION IN SECULAR BECAUSE OF LINEAR DEPENDENCE. THE RESULT
! WILL DEPEND SLIGHTLY BUT CRITICALLY ON THE ORDER BY WHICH THE
! VECTORS WERE ORTHONORMALIZED.
      DO 259 I=1,NRON
        DO 257 K=1,NVEC
          KK=1+MOD(NVTOT-K,MXVEC)
          SCR(KK)=VSMALL(K,I)
257     CONTINUE
        DO 258 K=1,NVEC
          VSMALL(K,I)=SCR(K)
258     CONTINUE
259   CONTINUE
      IF(NRON.LT.NRROOT) THEN
        WRITE(6,*)'DIAGRO Error: Linear dependence has reduced'
        WRITE(6,*)' the number of solutions to NRON, but you'
        WRITE(6,*)' wanted NRROOT soultions.'
        WRITE(6,'(1X,A,I3)')'  NRON=',NRON
        WRITE(6,'(1X,A,I3)')'NRROOT=',NRROOT
        CALL QUIT(_RC_INTERNAL_ERROR_)
      END IF
! ORDER THE EIGENFUNCTIONS BY DECREASING OVERLAP WITH THE SPACE
! SPANNED BY THE ORIGINALLY SELECTED REFCI ROOTS.
      CALL DGEMM_('N','N',                                              &
     &            NVEC,NRON,NVEC,                                       &
     &            1.0d0,PSMALL,MXVEC,                                   &
     &            VSMALL,MXVEC,                                         &
     &            0.0d0,SCR,NVEC)
      II=1
      DO 350 I=1,NRON
        PSEL(I)=DDOT_(NVEC,VSMALL(1,I),1,SCR(II),1)
        II=II+NVEC
350   CONTINUE
! PSEL(I) NOW CONTAINS EXPECTATION VALUE OF PMAT FOR I-TH EIGENVECTOR.
!     WRITE(6,*)' ARRAY OF SELECTION AMPLITUDES IN SCR:'
!     WRITE(6,'(1X,5F15.6)')(PSEL(I),I=1,NRON)
      DO 380 I=1,NRON-1
        IMAX=I
        PMAX=PSEL(I)
        DO 360 J=I+1,NRON
          IF(PSEL(J).LT.PMAX) GOTO 360
          PMAX=PSEL(J)
          IMAX=J
360     CONTINUE
        IF(IMAX.EQ.I) GOTO 380
        PSEL(IMAX)=PSEL(I)
        PSEL(I)=PMAX
        TMP=ESMALL(IMAX)
        ESMALL(IMAX)=ESMALL(I)
        ESMALL(I)=TMP
        DO 370 K=1,NVEC
          TMP=VSMALL(K,IMAX)
          VSMALL(K,IMAX)=VSMALL(K,I)
          VSMALL(K,I)=TMP
370     CONTINUE
380   CONTINUE
! FINALLY, REORDER THE SELECTED ROOTS BY ENERGY:
      DO 1380 I=1,NRROOT-1
        IMIN=I
        EMIN=ESMALL(I)
        DO 1360 J=I+1,NRROOT
          IF(ESMALL(J).GE.EMIN) GOTO 1360
          EMIN=ESMALL(J)
          IMIN=J
1360    CONTINUE
        IF(IMIN.EQ.I) GOTO 1380
        ESMALL(IMIN)=ESMALL(I)
        ESMALL(I)=EMIN
        TMP=PSEL(IMIN)
        PSEL(IMIN)=PSEL(I)
        PSEL(I)=TMP
        DO 1370 K=1,NVEC
          TMP=VSMALL(K,IMIN)
          VSMALL(K,IMIN)=VSMALL(K,I)
          VSMALL(K,I)=TMP
1370    CONTINUE
1380  CONTINUE
!     WRITE(6,*)' EIGENVALUES OF HSMALL. NRON=',NRON
!     WRITE(6,'(1X,5F15.6)')(ESMALL(I),I=1,NRON)
!     WRITE(6,*)' SELECTION WEIGHTS:'
!     WRITE(6,'(1X,5F15.6)')(   PSEL(I),I=1,NRON)
!     WRITE(6,*)' SELECTED EIGENVECTORS:'
!     DO 381 I=1,NRROOT
!       WRITE(6,'(1X,5F15.6)')(VSMALL(K,I),K=1,NVEC)
!381  CONTINUE
!     WRITE(6,*)
! -------------------------------------------------------------------
! CALCULATE RESIDUAL ARRAYS FOR THE NRROOTS EIGENFUNCTIONS OF HSMALL.
! ALSO, USE THE OPPORTUNITY TO FORM MANY OTHER SMALL ARRAYS.
      CALL GETMEM('ARR','ALLO','REAL',LARR,11*NRROOT**2)
      CALL HZLP1(CBUF,SBUF,DBUF,WORK(LARR),CSECT,RSECT,XI1,XI2,ICI)
! USE THESE SMALLER ARRAYS TO FORM HZERO AND SZERO. THIS IS
! OVERLAP AND HAMILTONIAN IN THE BASIS (PSI,RHO,XI1,XI2), WHERE
! PSI ARE THE EIGENFUNCTIONS OF HSMALL, RHO ARE RESIDUALS, ETC.
      CALL HZ(WORK(LARR))
      CALL GETMEM('ARR','FREE','REAL',LARR,11*NRROOT**2)
      NZ=4*NRROOT
!      WRITE(6,*)
!      WRITE(6,*)' AFTER HZ CALL. HZERO HAMILTONIAN:'
!      DO 391 I=1,NZ
!        WRITE(6,'(1X,5F15.6)')(HZERO(I,J),J=1,NZ)
! 391  CONTINUE
!      WRITE(6,*)' SZERO:'
!      DO 392 I=1,NZ
!        WRITE(6,'(1X,5F15.6)')(SZERO(I,J),J=1,NZ)
! 392  CONTINUE
      DO 393 I=1,NRROOT
        RNRM(I)=SQRT(SZERO(NRROOT+I,NRROOT+I))
!        EPERT(I)=ESMALL(I)-SZERO(3*NRROOT+I,NRROOT+I)
393   CONTINUE
!      WRITE(6,*)
!      WRITE(6,*)' PERTURBATION ESTIMATES TO ENERGY:'
!      WRITE(6,'(1X,5F15.6)')(ESHIFT+EPERT(I),I=1,NRROOT)
! ------------------------------------------------------------------
      NCONV=0
      CALL TIMING(CPTNOW,DUM,DUM,DUM)
      CPTIT=CPTNOW-CPTOLD
      CPTOLD=CPTNOW
      CPTOT=CPTNOW-CPTSTA
      IF(ITER.EQ.1) THEN
        EDISP=ESMALL(1)+ESHIFT
        WRITE(6,1234) ITER,NVEC,EDISP,RNRM(1),PSEL(1),CPTIT,CPTOT
      ELSE
          ELOW=ESMALL(1)-ELAST(1)
          IF((ELOW.LT.0.0D00).AND.(ABS(ELOW).LE.ETHRE)) NCONV=1
          EDISP=ESMALL(1)+ESHIFT
        WRITE(6,1235) ITER,NVEC,EDISP,ELOW,RNRM(1),PSEL(1),CPTIT,CPTOT
      END IF
      IF(NRROOT.GT.1) THEN
        DO 1240 I=2,NRROOT
          EDISP=ESMALL(I)+ESHIFT
          IF(ITER.EQ.1) THEN
            WRITE(6,1236) EDISP,RNRM(I),PSEL(I)
          ELSE
            ELOW=ESMALL(I)-ELAST(I)
            IF((ELOW.LT.0.0D00).AND.(ABS(ELOW).LE.ETHRE)) NCONV=NCONV+1
            WRITE(6,1237) EDISP,ELOW,RNRM(I),PSEL(I)
          END IF
1240    CONTINUE
        WRITE(6,*)
      END IF
      DO 1241 I=1,NRROOT
        ELAST(I)=ESMALL(I)
1241  CONTINUE
1234  FORMAT(1X,I4,1X,I4,1X,F15.8,9X  ,D9.2,1X,F6.3,2(1X,F7.1))
1235  FORMAT(1X,I4,1X,I4,1X,F15.8,D9.2,D9.2,1X,F6.3,2(1X,F7.1))
1236  FORMAT(11X,           F15.8,9X  ,D9.2,1X,F6.3)
1237  FORMAT(11X,           F15.8,D9.2,D9.2,1X,F6.3)
      IF(NCONV.EQ.NRROOT) THEN
        WRITE(6,*)' CONVERGENCE IN ENERGY.'
        GOTO 2000
      END IF
! ------------------------------------------------------------------
      THR=1.0D-06
      CALL SECULAR(MXZ,NZ,NRON,HZERO,SZERO,VZERO,EZERO,SCR,THR)
!     WRITE(6,*)' AFTER SECULAR CALL. NRON=',NRON
!     WRITE(6,*)' EIGENVALUES & -VECTORS:'
!     DO 395 I=1,NRON
!       WRITE(6,'(1X,5F15.6)') EZERO(I)
!       WRITE(6,'(1X,5F15.6)')(VZERO(K,I),K=1,NZ)
!395  CONTINUE
! ORDER THE EIGENFUNCTIONS BY DECREASING SIZE OF PSI PART.
        CALL DGEMM_('T','N',                                            &
     &              NRON,NRROOT,NZ,                                     &
     &              1.0d0,VZERO,MXZ,                                    &
     &              SZERO,MXZ,                                          &
     &              0.0d0,SCR(1+NRON),NRON)
      DO 450 I=1,NRON
        II=I
        SUM=0.0D00
        DO 440 K=1,NRROOT
          II=II+NRON
          SUM=SUM+SCR(II)**2
440     CONTINUE
        SCR(I)=SUM
450   CONTINUE
!     WRITE(6,*)
!     WRITE(6,*)' SELECTION CRITERION VECTOR, BEFORE ORDERING:'
!     WRITE(6,'(1X,5F15.6)')(SCR(I),I=1,NRON)
      DO 480 I=1,NRON-1
        IMAX=I
        PMAX=SCR(I)
        DO 460 J=I+1,NRON
          IF(SCR(J).LT.PMAX) GOTO 460
          PMAX=SCR(J)
          IMAX=J
460     CONTINUE
        IF(IMAX.EQ.I) GOTO 480
        SCR(IMAX)=SCR(I)
        SCR(I)=PMAX
        TMP=EZERO(IMAX)
        EZERO(IMAX)=EZERO(I)
        EZERO(I)=TMP
        DO 470 K=1,NZ
          TMP=VZERO(K,IMAX)
          VZERO(K,IMAX)=VZERO(K,I)
          VZERO(K,I)=TMP
470     CONTINUE
480   CONTINUE
!PAM 94-10-30, must reorder as before (DO 1380 etc):
! REORDER THE SELECTED ROOTS BY ENERGY:
      DO 1480 I=1,NRROOT-1
        IMIN=I
        EMIN=EZERO(I)
        DO 1460 J=I+1,NRROOT
          IF(EZERO(J).GE.EMIN) GOTO 1460
          EMIN=EZERO(J)
          IMIN=J
1460    CONTINUE
        IF(IMIN.EQ.I) GOTO 1480
        EZERO(IMIN)=EZERO(I)
        EZERO(I)=EMIN
        TMP=SCR(IMIN)
        SCR(IMIN)=SCR(I)
        SCR(I)=TMP
        DO 1470 K=1,NZ
          TMP=VZERO(K,IMIN)
          VZERO(K,IMIN)=VZERO(K,I)
          VZERO(K,I)=TMP
1470    CONTINUE
1480  CONTINUE
!PAM 94-10-30, end of update.
! NOTE: IF THE UPDATE PART IS SMALL ENOUGH FOR ALL THE FIRST NRROOT
! ARRAY, THE CALCULATION HAS CONVERGED.
      NNEW=0
!     WRITE(6,*)' CONVERGENCE CRITERION: SIZE OF UPDATE PART.'
      DO 490 I=1,NRROOT
        SQNRM=1.0D00-SCR(I)
!       WRITE(6,*)' ROOT NR, SQNRM:',I,SQNRM
        IF(SQNRM.LT.SQNLIM) GOTO 490
        NNEW=NNEW+1
490   CONTINUE
!      WRITE(6,*)
!      WRITE(6,*)' EIGENVALUES OF THE HZERO HAMILTONIAN:'
!      WRITE(6,'(1X,5F15.6)')(EZERO(I),I=1,NRON)
!      WRITE(6,*)' SELECTION WEIGHTS:'
!      WRITE(6,'(1X,5F15.6)')(  SCR(I),I=1,NRON)
!      WRITE(6,*)' EIGENVECTORS:'
!      DO 394 I=1,NRON
!        WRITE(6,'(1X,5F15.6)')(VZERO(K,I),K=1,NZ)
! 394  CONTINUE
!      WRITE(6,*)' NR OF NEW VECTORS SELECTED, NNEW:',NNEW
      IF(NNEW.EQ.0) THEN
        WRITE(6,*)' CONVERGENCE IN NORM.'
        GOTO 2000
      END IF
! NOTE: A CHANGE HERE. ALWAYS USE ALL THE NRROOT UPDATED VECTORS TO
! AVOID OVERWRITING AN EARLY CONVERGED VECTOR (WHICH HAS NEVER BEEN
! OUTDATED BY A LATER) BY A VECTOR BELONGING TO ANOTHER ROOT.
      NNEW=NRROOT
! -------------------------------------------------------------------
! FORM NEW UPDATED VECTORS: SKIP THE FIRST NRROOT-NNEW VECTORS,
! WHICH MAKE NO ESSENTIAL IMPROVEMENT.
!     WRITE(6,*)' RESET VZERO TO (0,0,0,1) FOR CONVENTIONAL DAVIDSON.'
!     CALL DCOPY_(NRROOT*MXZ,[0.0D00],0,VZERO,1)
!     CALL DCOPY_(NRROOT,[1.0D00],0,VZERO(3*NRROOT+1,1),MXZ+1)
      CALL HZLP2(CBUF,SBUF,DBUF,CSECT,RSECT,XI1,XI2,CNEW,ICI)
      IF(ITER.LT.MAXIT) GOTO 1000
      WRITE(6,*)' UNCONVERGED.'
2000  CONTINUE
      WRITE(6,*)' ',('*',III=1,70)
! WRITE CI VECTORS TO LUREST -- CI RESTART FILE.
      IDREST=0
      DO 2220 I=1,NRROOT
        IVEC=1+MOD(NVTOT-NRROOT+I-1,MXVEC)
        IDISK=IDISKC(IVEC)
        DO 2210 ISTA=1,NCONF,MBUF
          NN=MIN(MBUF,NCONF+1-ISTA)
          CALL iDAFILE(LUEIG,2,ICI,NN,IDISK)
          CALL UPKVEC(NN,ICI,CI(ISTA))
2210    CONTINUE
        CALL CSFTRA(' CSF',CI,AREF)
        C2REF=0.0D00
        DO 2215 IR=1,NREF
          ICSF=IREFX(IR)
          C=CI(ICSF)
          C2REF=C2REF+C**2
2215    CONTINUE
        IR=IROOT(I)
        ECI=ESMALL(I)+ESHIFT
        ENREF=ECI-EREF(IR)
        C2NREF=1.0D00-C2REF
! WRITE ENERGIES TO PRINTED OUTPUT, AND SAVE TOTAL ENERGIES TO ENGY
! FOR LATER PRINTOUT WITH PROPERTIES:
        WRITE(6,'(A,I3)')'               FINAL RESULTS FOR STATE NR ',I
        WRITE(6,'(A,I3)')' CORRESPONDING ROOT OF REFERENCE CI IS NR:',IR
        WRITE(6,'(A,F15.8)')'            REFERENCE CI ENERGY:',EREF(IR)
        WRITE(6,'(A,F15.8)')'         EXTRA-REFERENCE WEIGHT:',C2NREF
        IF(ICPF.EQ.1) THEN
          WRITE(6,'(A,F15.8)')'        ACPF CORRELATION ENERGY:',ENREF
          WRITE(6,'(A,F15.8)')'                    ACPF ENERGY:',ECI
          ENGY(I,1)=ECI
          ENGY(I,2)=0.0D00
          ENGY(I,3)=0.0D00
          Call Add_Info('E_MRACPF',[ECI],1,8)
        ELSE
          WRITE(6,'(A,F15.8)')'          CI CORRELATION ENERGY:',ENREF
          WRITE(6,'(A,F15.8)')'                      CI ENERGY:',ECI
! APPROXIMATE CORRECTIONS FOR UNLINKED QUADRUPLES:
          QDAV=ENREF*C2NREF/C2REF
          EDAV=ECI+QDAV
          QACPF=ENREF*(C2NREF*(1.0D00-GFAC))/(C2REF+GFAC*C2NREF)
          EACPF=ECI+QACPF
          WRITE(6,'(A,F15.8)')'            DAVIDSON CORRECTION:',QDAV
          WRITE(6,'(A,F15.8)')'               CORRECTED ENERGY:',EDAV
          WRITE(6,'(A,F15.8)')'                ACPF CORRECTION:',QACPF
          WRITE(6,'(A,F15.8)')'               CORRECTED ENERGY:',EACPF
          ENGY(I,1)=ECI
          ENGY(I,2)=QDAV
          ENGY(I,3)=QACPF
          Call Add_Info('E_MRSDCI',[ECI],1,8)
        END IF
        WRITE(6,*)
!PAM04        CALL PRWF_MRCI (HWORK(LCSPCK),HWORK(LINTSY),HWORK(LINDX),
!PAM04     &             CI,HWORK(LJREFX) )
        CALL PRWF_MRCI (IWORK(LCSPCK),IWORK(LINTSY),IWORK(LINDX),       &
     &             CI,IWORK(LJREFX) )
        WRITE(6,*)' ',('*',III=1,70)
        CALL dDAFILE(LUREST,1,CI,NCONF,IDREST)
2220  CONTINUE
      Call XFlush(6)
      RETURN
      END
