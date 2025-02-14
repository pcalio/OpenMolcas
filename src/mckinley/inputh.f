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
*               1996, Anders Bernhardsson                              *
************************************************************************
      SubRoutine Inputh(Run_MCLR)
************************************************************************
*                                                                      *
* Object: input module for the gradient code                           *
*                                                                      *
*     Author: Roland Lindh, Dept. of Theoretical Chemistry,            *
*             University of Lund, SWEDEN                               *
*             September 1991                                           *
*                                                                      *
*             Modified to complement GetInf, January 1992              *
************************************************************************
      use Basis_Info
      use Center_Info
      use Symmetry_Info, only: nIrrep, iChTbl, iOper, lIrrep, lBsFnc
      use Gateway_global, only: Onenly, Test
      use Gateway_Info, only: CutInt
      Implicit Real*8 (A-H,O-Z)
#include "itmax.fh"
#include "Molcas.fh"
#include "real.fh"
#include "disp.fh"
#include "disp2.fh"
#include "iavec.fh"
#include "stdalloc.fh"
#include "print.fh"
#include "SysDef.fh"
      Logical TstFnc, Type, Slct
c      Logical DoCholesky
      Character*1 xyz(0:2)
      Character*8 Label,labelop
      Character*32 Label2
      Logical Run_MCLR
      Character*80  KWord, Key
      Integer iSym(3), iTemp(3*MxAtom)
      Integer, Allocatable:: ATDisp(:), DEGDisp(:), TDisp(:), Car(:)
      Real*8, Allocatable:: AM(:,:), Tmp(:,:), C(:,:), Scr(:,:)
      Data xyz/'x','y','z'/
      Interface
        Subroutine datimx(TimeStamp) Bind(C,name='datimx_')
          Use, Intrinsic :: iso_c_binding, Only: c_char
          Character(kind=c_char) :: TimeStamp(*)
        End Subroutine
      End Interface
*
c      Call DecideOnCholesky(DoCholesky)
c      If (DoCholesky) Then
c       write(6,*)'** Cholesky or RI/DF not yet implemented in McKinley '
c       call abend()
c      EndIf

      iRout=99
      Do i = 1, nRout
         nPrint(i) = 5
      End Do
      show=.false.
      Onenly = .False.
      nmem=0
      Test   = .False.
      TRSymm = .false.
      lEq    = .False.
      Slct   = .False.
      PreScr   = .true.
      lGrd=.True.
      lHss=.True.
      Nona=.false.
      Run_MCLR=.True.
      CutInt = 1.0D-07
      ipert=2
      iCntrl=1
      Call lCopy(mxpert,[.true.],0,lPert,1)
      sIrrep=.false.
      iprint=0
      Do 109 i = 1, 3*MxAtom
         IndxEq(i) = i
 109  Continue
*
*     KeyWord directed input
*
      LuRd=5
      Call RdNLst(LuRd,'MCKINLEY')
 998  Read(5,'(A72)',END=977,ERR=988) Key
      KWord = Key
      Call UpCase(KWord)
      If (KWord(1:1).eq.'*')    Go To 998
      If (KWord.eq.'')       Go To 998
*     If (KWord(1:4).eq.'EQUI') Go To 935
*     If (KWord(1:4).eq.'NOTR') Go To 952
*     If (KWord(1:4).eq.'NOIN') Go To 953
      If (KWord(1:4).eq.'SHOW') Go To 992
      If (KWord(1:4).eq.'MEM ') Go To 697
*
      If (KWord(1:4).eq.'CUTO') Go To 942
      If (KWord(1:4).eq.'VERB') Go To 912
      If (KWord(1:4).eq.'NOSC') Go To 965
      If (KWord(1:4).eq.'ONEO') Go To 990
      If (KWord(1:4).eq.'SELE') Go To 960
      If (KWord(1:4).eq.'REMO') Go To 260
      If (KWord(1:4).eq.'PERT') Go To 975
      If (KWord(1:4).eq.'TEST') Go To 991
      If (KWord(1:4).eq.'EXTR') Go To 971
      If (KWord(1:4).eq.'NONA') Go To 972
      If (KWord(1:4).eq.'NOMC') Go To 973
      If (KWord(1:4).eq.'END ') Go To 997
      Write (6,*) 'InputH: Illegal keyword'
      Write (6,'(A,A)') 'KWord=',KWord
      Call Abend()
 977  Write (6,*) 'InputH: end of input file.'
      Write (6,'(A,A)') 'Last command=',KWord
      Call Abend()
 988  Write (6,*) 'InputH: error reading input file.'
      Write (6,'(A,A)') 'Last command=',KWord
      Call Abend()
*                                                                      *
****** MEM  ************************************************************
*                                                                      *
 697  Read(5,*) nmem
      nmem=nmem*1048576/rtob
      goto 998
*                                                                      *
****** PERT ************************************************************
*                                                                      *
*     Select which part of the Hessian will be compiuted.
*
975   Read(5,'(A)',Err=988) KWord
      If (KWord(1:1).eq.'*') Go To 975
      If (KWord.eq.'')    Go To 975
      Call UpCase(KWord)
      If (KWORD(1:4).eq.'HESS') Then
         ipert=2
      Else If (KWORD(1:4).eq.'GEOM') Then
         ipert=1
      Else
         Write (6,*) 'InputH: Illegal perturbation keyword'
         Write (6,'(A,A)') 'KWord=',KWord
         Call Abend()
      End If

      Goto 998
*                                                                      *
****** EQUI ************************************************************
*                                                                      *
*     Equivalence option
*
*935  Continue
*     lEq=.True.
*936  Read(5,'(A)',Err=988) KWord
*     If (KWord(1:1).eq.'*') Go To 936
*     If (KWord.eq.'')    Go To 936
*     Read(KWord,*) nGroup
*     Do 937 iGroup = 1, nGroup
*938     Read(5,'(A)',Err=988) KWord
*        If (KWord(1:1).eq.'*') Go To 938
*        If (KWord.eq.'')    Go To 938
*        Read(KWord,*) nElem,(iTemp(iElem),iElem=1,nElem)
*        Do 939 iElem=2,nElem
*           IndxEq(iTemp(iElem)) = iTemp(1)
*           Direct(iTemp(iElem)) = .False.
*939      Continue
*937   Continue
*     Go To 998
*                                                                      *
****** CUTO ************************************************************
*                                                                      *
*     Cuttoff for computing primitive gradients
*
 942  Read(5,*) Cutint
*     If (KWord(1:1).eq.'*') Go To 942
*     If (KWord.eq.'')    Go To 942
*     Read(KWord,*,Err=988) CutInt
      CutInt = Abs(CutInt)
      Go To 998
*                                                                      *
****** NOIN ************************************************************
*                                                                      *
*     Disable the utilization of translational and
*     rotational invariance of the energy in the
*     computation of the molecular gradient.
*
*953  TRSymm=.False.
*     Go To 998
*                                                                      *
****** SELE ************************************************************
*                                                                      *
*     selection option
*
 960  Continue
      slct=.true.
      Call lCopy(mxpert,[.false.],0,lPert,1)
*962  Continue
      Read(5,*) nslct
*     If (KWord(1:1).eq.'*') Go To 962
*     If (KWord.eq.'')    Go To 962
*     Read(KWord,*) nSlct
*
      Read(5,*) (iTemp(iElem),iElem=1,nSlct)
      Do 964 iElem=1,nSlct
         lpert(iTemp(iElem)) = .True.
964   Continue
      Go To 998
*                                                                      *
****** REMO ************************************************************
*                                                                      *
 260  Continue
      Slct=.true.
      Read(5,*) nslct
*
      Read(5,*) (iTemp(iElem),iElem=1,nSlct)
      Do 264 iElem=1,nSlct
         lpert(iTemp(iElem)) = .false.
264   Continue
      Go To 998
*                                                                      *
****** NOSC ************************************************************
*                                                                      *
*     Change default for the prescreening.
*
 965  PreScr  = .False.
      Go To 998
*                                                                      *
****** ONEO ************************************************************
*                                                                      *
*     Do not compute two electron integrals.
*
 990  Onenly = .TRUE.
      Go To 998
*                                                                      *
****** TEST ************************************************************
*                                                                      *
*     Process only the input.
*
 991  Test = .TRUE.
      Go To 998
*                                                                      *
****** SHOW ************************************************************
*                                                                      *
*-----Raise the printlevel to show gradient contributions
*
 992  Continue
      Show=.true.
      Go To 998
*                                                                      *
****** EXTR ************************************************************
*                                                                      *
*     Put the program name and the time stamp onto the extract file
*
971   Write (6,*) 'InputH: EXTRACT option is redundant and is ignored!'
      Go To 998
*                                                                      *
****** VERB ************************************************************
*                                                                      *
*     Verbose output
*
 912  nPrint( 1)=6
      nPrint(99)=6
      Go To 998
*                                                                      *
****** NONA ************************************************************
*                                                                      *
*     Compute the anti-symmetric overlap gradient only.
*
972   Nona=.true.
      Run_MCLR=.False.
      Go To 998
*                                                                      *
****** NOMC ************************************************************
*                                                                      *
*     Request no automatic run of MCLR
*
973   Run_MCLR=.False.
      Go To 998
************************************************************************
*                                                                      *
*                          End of input section.                       *
*                                                                      *
************************************************************************
 997  Continue
*
      iPrint=nPrint(iRout)
*
      iOpt = 1
      if (onenly) iopt=0
      iRC = -1
      Lu_Mck=35
      Call OpnMck(irc,iOpt,'MCKINT',Lu_Mck)
      If (iRC.ne.0) Then
         Write (6,*) 'InputH: Error opening MCKINT'
         Call Abend()
      End If
      If (ipert.eq.1) Then
        Label2='Geometry'
        LabelOp='PERT    '
        irc=-1
        iopt=0
        Call cWrMck(iRC,iOpt,LabelOp,1,Label2,iDummer)
        sIrrep=.true.
        iCntrl=1
      Else If (ipert.eq.2) Then
        Label2='Hessian'
        LabelOp='PERT    '
        Call cWrMck(iRC,iOpt,LabelOp,1,Label2,iDummer)
        iCntrl=1
      Else If (ipert.eq.3) Then
        LabelOp='PERT    '
        Label2='Magnetic'
        Call cWrMck(iRC,iOpt,LabelOp,1,Label2,iDummer)
        Write (6,*) 'InputH: Illegal perturbation option'
        Write (6,*) 'iPert=',iPert
        Call Abend()
      Else If (ipert.eq.4) Then
        LabelOp='PERT    '
        Label2='Relativistic'
        Call cWrMck(iRC,iOpt,LabelOp,1,Label2,iDummer)
        Write (6,*) 'InputH: Illegal perturbation option'
        Write (6,*) 'iPert=',iPert
        Call Abend()
      Else
        Write (6,*) 'InputH: Illegal perturbation option'
        Write (6,*) 'iPert=',iPert
        Call Abend()
      End If

*     If (lEq)  TRSymm=.False.
*     If (Slct) TRSymm=.False.
*
      mDisp = 0
      mdc = 0
      Do 10 iCnttp = 1, nCnttp
         Do 20 iCnt = 1, dbsc(iCnttp)%nCntr
            mdc = mdc + 1
            mDisp = mDisp + 3*(nIrrep/dc(mdc)%nStab)
 20      Continue
 10   Continue
*
      Write (6,*)
      Write (6,'(20X,A,E10.3)')
     &  ' Threshold for contributions to the gradient or Hessian:',
     &   CutInt
      Write (6,*)
*
      If (Nona) Then
         Write (6,*)
         Write (6,'(20X,A)')
     &   ' McKinley only is computing the antisymmetric gradient '//
     &   ' of the overlap integrals for the NonAdiabatic Coupling.'
         Write (6,*)
      End If
*
      If (iCntrl.eq.1) Then
*
*
*     Generate symmetry adapted cartesian displacements
*
      If (iPrint.ge.6) Then
      Write (6,*)
      Write (6,'(20X,A)')
     &           '********************************************'
      Write (6,'(20X,A)')
     &           '* Symmetry Adapted Cartesian Displacements *'
      Write (6,'(20X,A)')
     &           '********************************************'
      Write (6,*)
      End If
      Call ICopy(MxAtom*8,[0],0,IndDsp,1)
      Call ICopy(MxAtom*3,[0],0,InxDsp,1)
      Call mma_allocate(ATDisp,mDisp,Label='ATDisp')
      Call mma_allocate(DEGDisp,mDisp,Label='DEGDisp')
      nDisp = 0
      Do 100 iIrrep = 0, nIrrep-1
         lDisp(iIrrep) = 0
         Type = .True.
*        Loop over basis function definitions
         mdc = 0
         mc = 1
         Do 110 iCnttp = 1, nCnttp
*           Loop over unique centers associated with this basis set.
            Do 120 iCnt = 1, dbsc(iCnttp)%nCntr
               mdc = mdc + 1
               IndDsp(mdc,iIrrep) = nDisp
*              Loop over the cartesian components
               Do 130 iCar = 0, 2
                  iComp = 2**iCar
                  If ( TstFnc(dc(mdc)%iCoSet,
     &                       iIrrep,iComp,dc(mdc)%nStab) ) Then
                      nDisp = nDisp + 1
                      If (nDisp.gt.mDisp) Then
                         Write (6,*) 'nDisp.gt.mDisp'
                         Call Abend
                      End If
                      If (iIrrep.eq.0) InxDsp(mdc,iCar+1) = nDisp
                      lDisp(iIrrep) = lDisp(iIrrep) + 1
                      If (Type) Then
                         If (iPrint.ge.6) Then
                         Write (6,*)
                         Write (6,'(10X,A,A)')
     &                    ' Irreducible representation : ',
     &                      lIrrep(iIrrep)
                         Write (6,'(10X,2A)')
     &                      ' Basis function(s) of irrep: ',
     &                       lBsFnc(iIrrep)
                         Write (6,*)
                         Write (6,'(A)')
     &                   ' Basis Label        Type   Center Phase'
                         End If
                         Type = .False.
                      End If
                      If (iPrint.ge.6)
     &                Write (6,'(I4,3X,A8,5X,A1,7X,8(I3,4X,I2,4X))')
     &                      nDisp,dc(mdc)%LblCnt,xyz(iCar),
     &                      (mc+iCo,iPrmt(
     &                      NrOpr(dc(mdc)%iCoSet(iCo,0)),iComp)*
     &                      iChTbl(iIrrep,NrOpr(dc(mdc)%iCoSet(iCo,0))),
     &                      iCo=0,nIrrep/dc(mdc)%nStab-1 )
                      Write (ChDisp(nDisp),'(A,1X,A1)')
     &                       dc(mdc)%LblCnt,xyz(iCar)
                      ATDisp(ndisp)=icnttp
                      DEGDisp(ndisp)=nIrrep/dc(mdc)%nStab
                  End If
*
 130           Continue
               mc = mc + nIrrep/dc(mdc)%nStab
 120        Continue
 110     Continue
*
 100  Continue
*
      If (nDisp.ne.mDisp) Then
         Write (6,*) 'InputH: nDisp.ne.mDisp'
         Write (6,*) 'nDisp,mDisp=',nDisp,mDisp
         Call Abend()
      End If
      If (sIrrep) Then
         ndisp=ldisp(0)
         Do i= 1,nIrrep-1
            lDisp(i)=0
         End Do
      End If
      Call mma_allocate(TDisp,nDisp,Label='TDisp')
      TDisp(:)=30
      iOpt = 0
      iRC = -1
      labelOp='ndisp   '
      Call iWrMck(iRC,iOpt,labelop,1,[ndisp],iDummer)
      If (iRC.ne.0) Then
         Write (6,*) 'InputH: Error writing to MCKINT'
         Write (6,'(A,A)') 'labelOp=',labelOp
         Call Abend()
      End If
      LABEL='DEGDISP'
      iRc=-1
      iOpt=0
      Call iWrMck(iRC,iOpt,Label,idum,DEGDISP,idum)
      If (iRC.ne.0) Then
         Write (6,*) 'InputH: Error writing to MCKINT'
         Write (6,'(A,A)') 'LABEL=',LABEL
         Call Abend()
      End If
      Call mma_deallocate(DEGDisp)
      LABEL='NRCTDISP'
      iRc=-1
      iOpt=0
      Call iWrMck(iRC,iOpt,Label,idum,ATDisp,idum)
      If (iRC.ne.0) Then
         Write (6,*) 'InputH: Error writing to MCKINT'
         Write (6,'(A,A)') 'LABEL=',LABEL
         Call Abend()
      End If
      Call mma_deallocate(ATDisp)
      LABEL='TDISP'
      iRc=-1
      iOpt=0
      Call iWrMck(iRC,iOpt,Label,idum,TDisp,idum)
      If (iRC.ne.0) Then
         Write (6,*) 'InputH: Error writing to MCKINT'
         Write (6,'(A,A)') 'LABEL=',LABEL
         Call Abend()
      End If
      Call mma_deallocate(TDisp)
*
      Else If (iCntrl.eq.2) Then
          Write(6,*) 'Svaret aer 48 '
      Else If (iCntrl.eq.3) Then
          Write(6,*) 'Svaret aer 48'
      End If
*
*     Set up the angular index vector
*
      i = 0
      Do 1000 iR = 0, iTabMx
         Do 2000 ix = iR, 0, -1
            Do 3000 iy = iR-ix, 0, -1
               iz = iR-ix-iy
               i = i + 1
               ixyz(1,i) = ix
               ixyz(2,i) = iy
               ixyz(3,i) = iz
 3000       Continue
 2000    Continue
 1000 Continue
*
*     Set up data for the utilization of the translational
*     and rotational invariance of the energy.
*
      If (TRSymm) Then
         Call Abend()
         iSym(1) = 0
         iSym(2) = 0
         iSym(3) = 0
         Do 15 i = 1, Min(nIrrep-1,5)
            j = i
            If (i.eq.3) j = 4
            Do 16 k = 1, 3
               If (iAnd(iOper(j),2**(k-1)).ne.0) iSym(k) = 2**(k-1)
   16       Continue
   15    Continue
         nTR = 0
*--------Translational equations
         Do 150 i = 1, 3
            If (iSym(i).eq.0) nTR = nTR + 1
 150     Continue
         If (iPrint.ge.99) Write (6,*) ' nTR=',nTR
*--------Rotational equations
         Do 160 i = 1,3
            j = i+1
            If (j.gt.3) j = j-3
            k = i+2
            If (k.gt.3) k = k-3
            ijSym = iEor(iSym(j),iSym(k))
            If (ijSym.eq.0) nTR = nTR + 1
 160     Continue
         If (nTR.eq.0) Then
            TRSymm = .False.
            Go To 9876
         End If
         If (iPrint.ge.99) Write (6,*) ' nTR=',nTR
         Call mma_allocate(AM,nTR,lDisp(0),Label='AM')
         Call mma_allocate(Tmp,nTR,nTR,Label='Tmp')
         Call mma_allocate(C,4,lDisp(0),Label='C')
         Call mma_allocate(Car,lDisp(0),Label='Car')
*
         AM(:,:)=Zero
         C(:,:)=Zero
*
*        Generate temporary information of the symmetrical
*        displacements.
*
        ldsp = 0
         mdc = 0
         iIrrep = 0
         Do 2100 iCnttp = 1, nCnttp
            Do 2200 iCnt = 1, dbsc(iCnttp)%nCntr
               mdc = mdc + 1
*              Call RecPrt(' Coordinates',' ',
*    &                     dbsc(iCnttp)%Coor(1,iCnt),1,3)
               Fact = Zero
               iComp = 0
               If (dbsc(iCnttp)%Coor(1,iCnt).ne.Zero)
     &            iComp = iOr(iComp,1)
               If (dbsc(iCnttp)%Coor(2,iCnt).ne.Zero)
     &            iComp = iOr(iComp,2)
               If (dbsc(iCnttp)%Coor(3,iCnt).ne.Zero)
     &            iComp = iOr(iComp,4)
               Do 2250 jIrrep = 0, nIrrep-1
                  If ( TstFnc(dc(mdc)%iCoSet,
     &                        jIrrep,iComp,dc(mdc)%nStab) ) Then
                     Fact = Fact + One
                  End If
 2250          Continue
               Do 2300 iCar = 0, 2
                  iComp = 2**iCar
                  If ( TstFnc(dc(mdc)%iCoSet,
     &                        iIrrep,iComp,dc(mdc)%nStab) ) Then
                     ldsp = ldsp + 1
*--------------------Transfer the coordinates
                     call dcopy_(3,dbsc(iCnttp)%Coor(:,iCnt),1,
     &                          C(1:3,ldsp),1)
*--------------------Transfer the multiplicity factor
                     C(4,ldsp) = Fact
                     Car(ldsp) = iCar + 1
                  End If
 2300          Continue
 2200       Continue
 2100    Continue
         If (iPrint.ge.99) Then
            Call RecPrt(' Information',' ',C,4,lDisp(0))
            Write (6,*) (Car(i),i=1,lDisp(0))
         End If
*
*--------Set up coefficient for the translational equations
*
         iTR = 0
         Do 1110 i = 1,3
            If (iSym(i).ne.0) Go To 1110
            iTR = iTR + 1
            Do 1120 ldsp = 1, lDisp(0)
               If (Car(ldsp).eq.i) Then
                  AM(iTR,ldsp) = C(4,ldsp)
               End If
 1120       Continue
 1110    Continue
*
*--------Set up coefficient for the rotational invariance
*
         Do 1210 i = 1, 3
            j = i + 1
            If (j.gt.3) j = j - 3
            k = i + 2
            If (k.gt.3) k = k - 3
            ijSym = iEor(iSym(j),iSym(k))
            If (ijSym.ne.0) Go To 1210
            iTR = iTR + 1
            Do 1220 ldsp = 1, lDisp(0)
               If (Car(ldsp).eq.j) Then
                  Fact = C(4,ldsp) * C(k,ldsp)
               Else If (Car(ldsp).eq.k) Then
                  Fact =-C(4,ldsp) * C(j,ldsp)
               Else
                  Fact=Zero
                  Write (6,*) 'Inputh: Error'
                  Call Abend()
               End If
               AM(iTR,ldsp) = Fact
 1220       Continue
 1210    Continue
         If (iPrint.ge.99)
     &      Call RecPrt(' The A matrix',' ',AM,nTR,lDisp(0))
*
*--------Now, transfer the coefficient of those gradients which will
*        not be computed directly.
*        The matrix to compute the inverse of is determined via
*        a Gram-Schmidt procedure.
*
*--------Pick up the other vectors
         Do 1230 iTR = 1, nTR
*           Write (*,*) ' Looking for vector #',iTR
            ovlp = Zero
            kTR = 0
*-----------Check all the remaining vectors
            Do 1231 ldsp = 1, lDisp(0)
               Do 1235 jTR = 1, iTR-1
                  If (iTemp(jTR).eq.ldsp) Go To 1231
 1235          Continue
*              Write (*,*) ' Checking vector #', ldsp
               call dcopy_(nTR,AM(:,ldsp),1,Tmp(:,iTR),1)
*              Call RecPrt(' Vector',' ',Tmp(:,iTR),nTR,1)
*--------------Gram-Schmidt orthonormalize against accepted vectors
               Do 1232 lTR = 1, iTR-1
                  alpha = DDot_(nTR,Tmp(:,iTR),1,Tmp(:,lTR),1)
*                 Write (*,*) ' <x|y> =', alpha
                  Call DaXpY_(nTR,-alpha,Tmp(:,lTR),1,Tmp(:,iTR),1)
 1232          Continue
*              Call RecPrt(' Remainings',' ',Tmp(:,iTR),nTR,1)
               alpha = DDot_(nTR,Tmp(:,iTR),1,Tmp(:,iTR),1)
*              Write (*,*) ' Remaining overlap =', alpha
*--------------Check the remaining magnitude of vector after Gram-Schmidt
               If (alpha.gt.ovlp) Then
                  kTR = ldsp
                  ovlp = alpha
               End If
 1231       Continue
            If (kTR.eq.0) Then
               Write (6,*) ' No Vector found!'
               Call Abend
            End If
*           Write (*,*) ' Selecting vector #', kTR
*-----------Pick up the "best" vector
            call dcopy_(nTR,AM(:,kTR),1,Tmp(:,iTR),1)
            Do 1233 lTR = 1, iTR-1
               alpha = DDot_(nTR,Tmp(:,iTR),1,Tmp(:,lTR),1)
               Call DaXpY_(nTR,-alpha,Tmp(:,lTR),1,Tmp(:,iTR),1)
 1233       Continue
            alpha = DDot_(nTR,Tmp(:,iTR),1,Tmp(:,iTR),1)
            Call DScal_(nTR,One/Sqrt(alpha),Tmp(:,iTR),1)
            iTemp(iTR) = kTR
 1230    Continue
         Do 1234 iTR = 1, nTR
            call dcopy_(nTR,AM(:,iTemp(iTR)),1,Tmp(:,iTR),1)
            AM(:,iTemp(iTR))=Zero
 1234    Continue
         If (iPrint.ge.99) Then
            Call RecPrt(' The A matrix',' ',AM,nTR,lDisp(0))
            Call RecPrt(' The T matrix',' ',Tmp,nTR,nTR)
            Write (6,*) (iTemp(iTR),iTR=1,nTR)
         End If
*
*        Compute the inverse of the T matrix
*
         Call MatInvert(Tmp,nTR)
         If (IPrint.ge.99)
     &      Call RecPrt(' The T-1 matrix',' ',Tmp,nTR,nTR)
         Call DScal_(nTR**2,-One,Tmp,1)
*
*        Generate the complete matrix
*
         Call mma_allocate(Scr,nTR,lDisp(0),Label='Scr')
         Call DGEMM_('N','N',
     &               nTR,lDisp(0),nTR,
     &               1.0d0,Tmp,nTR,
     &               AM,nTR,
     &               0.0d0,Scr,nTR)
         If (IPrint.ge.99)
     &      Call RecPrt(' A-1*A',' ',Scr,nTR,lDisp(0))
         Call mma_deallocate(AM)
         Call mma_allocate(AM,lDisp(0),lDisp(0),Label='AM')
         AM(:,:)=Zero
         Do i = 1, lDisp(0)
            AM(i,i)=One
         End Do
         Do 1250 iTR = 1, nTR
            ldsp = iTemp(iTR)
            call dcopy_(lDisp(0),Scr(iTR,1),nTR,AM(ldsp,1),lDisp(0))
 1250    Continue
         If (iPrint.ge.99)
     &      Call RecPrt('Final A matrix',' ',AM,lDisp(0),lDisp(0))
*
*
         Call mma_deallocate(Scr)
         Call mma_deallocate(Car)
         Call mma_deallocate(C)
         Call mma_deallocate(Tmp)
         Do 1501 iTR = 1, nTR
            ldsp = iTemp(iTR)
            LPert(ldsp)=.False.
 1501    Continue
*
         Write (6,*)
         Write (6,'(20X,A,A)')
     &      ' Automatic utilization of translational and',
     &      ' rotational invariance of the energy is employed.'
         Write (6,*)
         Do 7000 i = 1, lDisp(0)
            If (lpert(i)) Then
               Write (6,'(25X,A,A)') Chdisp(i), ' is independent'
            Else
               Write (6,'(25X,A,A)') Chdisp(i), ' is dependent'
            End If
 7000    Continue
         Write (6,*)
*
      Else
         nTR = 0
         If (iPrint.ge.6) Then
         Write (6,*)
         Write (6,'(20X,A,A)')
     &      ' No automatic utilization of translational and',
     &      ' rotational invariance of the energy is employed.'
         Write (6,*)
         End If
      End If
*
      If (Slct) Then
         Write (6,*)
         Write (6,'(20X,A)') ' The Selection option is used'
         Write (6,*)
         Do 7100 i = 1, lDisp(0)
            If (lpert(i)) Then
               Write (6,'(25X,A,A)') Chdisp(i), ' is computed'
            Else
               Write (6,'(25X,A,A)') Chdisp(i), ' is set to zero'
            End If
 7100    Continue
         Write (6,*)
      End If
*
 9876 Continue
      Call Datimx(KWord)
      Call ICopy(nIrrep,[0],0,nFck,1)
      Do iIrrep=0,nIrrep-1
        If (iIrrep.ne.0) Then
          Do jIrrep=0,nIrrep-1
           kIrrep=NrOpr(iEOR(ioper(jIrrep),ioper(iIrrep)))
           If (kIrrep.lt.jIrrep)
     &     nFck(iIrrep)=nFck(iIrrep)+nBas(jIrrep)*nBas(kIrrep)
          End Do
        Else
           Do jIrrep=0,nIrrep-1
             nFck(0)=nFck(0)+nBas(jIrrep)*(nBas(jIrrep)+1)/2
           End Do
        End If
      End Do
*
      Return
      End
