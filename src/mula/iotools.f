!***********************************************************************
! This file is part of OpenMolcas.                                     *
!                                                                      *
! OpenMolcas is free software; you can redistribute it and/or modify   *
! it under the terms of the GNU Lesser General Public License, v. 2.1. *
! OpenMolcas is distributed in the hope that it will be useful, but it *
! is provided "as is" and without any express or implied warranties.   *
! For more details see the full text of the license in the file        *
! LICENSE or in <http://www.gnu.org/licenses/>.                        *
!                                                                      *
! Copyright (C) 1993, Markus P. Fuelscher                              *
!               1993, Per-Olof Widmark                                 *
!               1999, Niclas Forsberg                                  *
!               Per Ake Malmqvist                                      *
!***********************************************************************
!!----------------------------------------------------------------------!
!!
      Subroutine MulaRdNLst(iUnit,NameIn)
!!
!!  Locate the beginning of an input stream
!!  (similar to FORTRAN NAMELIST read known to some systems)
!!
!!  Calling arguments:
!!    iUnit  : Type integer, input
!!             FORTRAN unit number
!!    NameIn : Type character string, input
!!             Character string marking the beginning of the input
!!
!!  Written by:
!!    M.P. Fuelscher and P.O. Widmark
!!    University of Lund, Sweden, 1993
!!
!!  Slightly modified by:
!!    Niclas Forsberg, 1999
!!
!!
#include "inputdata.fh"
      Character NameIn*(*)
      Character*8 StdNam
      Character*80 Line
      Integer StrnLn
!!
!!---- Convert the Name to internal standard format.
      Call StdFmt(NameIn,StdNam)
      lStdNam = StrnLn(StdNam)
!!
!!---- Read until an input Line is located which starts with
!!     the string, Name, not before the second column
      Do while(.true.)
      Read(iUnit,'(A80)',End=900) Line
      Call LeftAd(Line)
      Call UpCase(Line)
      If (( Line(1:1).eq.'&' ).and.                                     &
     &                ( Line(2:lStdNam+1).eq.                           &
     &     StdNam(1:lStdNam) )) Then
      Return
      End If
      End Do
!!
!!---- Error exit
 900   Continue
      Write(6,*)'MulaRdNLst error: Could not locate input.'
      Write(6,*)'Looking for:','&'//StdNam
      Call Quit_OnUserError()
!!
      End
!!
!!----------------------------------------------------------------------!
!!-----------------------------------------------------------------------!
!!
      Subroutine WordPos(k,InLine,iStart,iStop)
!!
!!  Purpose:
!!    Return the position (iStart,iStop) of the first word after
!!    position k in InLine.
!!
!!  Input:
!!    k        : Integer - the first position after keyword in the
!!               string InLine.
!!    InLine   : Character string.
!!
!!  Output:
!!    iStart   : Integer - the position of the first non-blank
!!               character after position k in InLine.
!!    iStop,k  : Integer - the position of the first blank character
!!               after position iStart in InLine.
!!
#include "inputdata.fh"
      Character*1   Ch
      Character InLine*(*)
!!
      Length = Len(InLine)
      Ch = InLine(k:k)
      Do While (( Ch.eq.' ' ).and.( k.lt.Length ))
      k = k+1
      Ch = InLine(k:k)
      End Do
      If ( k+1.ge.Length ) Then
      iStart = Length
      iStop  = Length
      Return
      End If
      iStart = k
      k = k+1
      Ch = InLine(k:k)
      Do While (( Ch.ne.' ' ).and.( k.lt.Length ))
      k = k+1
      Ch = InLine(k:k)
      End Do
      iStop = k-1
!!
      End
!!
!!-----------------------------------------------------------------------!
!!-----------------------------------------------------------------------!
!!
      Subroutine KeyWord(nUnit,KeyWd,Rewind,Exist)
!!
!!  Purpose:
!!    Read from a file until a line contains the string KeyWd.
!!
!!  Input:
!!    nUnit     : Unit to read from.
!!    KeyWd     : Character string - keyword.
!!    Rewind    : Logical.
!!
!!  Output:
!!    File      : Next line in the file contains the data connected
!!                with the keyword KeyWd.
!!  Calls:
!!    MulaRdNlst
!!    Normalize
!!
#include "inputdata.fh"
      Character KeyWd*(*)
      Character*32 TmpKey
      Character*80 InLine,OutLine
      Integer i,KLen,BlInd
      Logical Rewind,Exist
!!
      InLine=KeyWd
      Call Normalize(InLine,OutLine)
!! Index of first blank character from the end:
      BlInd=81
      Do i=80,1,-1
      If(Outline(i:i).ne.' ') GoTo 5
      BlInd=i
      End Do
 5     Continue
      If (BlInd.gt.80) Then
      Write(6,*)'KEYWORD: KeyWd is too long.'
      Write(6,*)'KeyWd:',KeyWd
      Write(6,*)'After normalization (OutLine):'
      Write(6,*)OutLine
      call abend()
      End If
      Exist=.FALSE.
      If (BlInd.eq.1) Return

      KLen=BlInd-1
      TmpKey=OutLine(1:KLen)

      If ( Rewind ) Then
      Rewind nUnit
      Call MulaRdNlst(nUnit,InputName)
      End If
!!
      Read(nUnit,'(a80)',end=10,err=20) InLine
      Call Normalize(InLine,OutLine)
      Do While ( OutLine(1:KLen).ne.TmpKey(1:KLen) )
      Read(nUnit,'(a80)',end=10,err=20) InLine
      Call Normalize(InLine,OutLine)
      End Do
 10    Continue
      Exist = OutLine(1:KLen).eq.TmpKey(1:KLen)
!!
      Return
 20    Write(6,*)' I/O error on unit nUnit=',nUnit
      call abend()
      End
!!
!!-----------------------------------------------------------------------!


      Real*8 Function StrToDble(InString)
!!
!!  Purpose:
!!    Convert a number in string InString to Real*8.
!!
!!  Input:
!!    InString   : Character string.
!!
!!  Output:
!!    xNum     : Real*8.
!!
#include "inputdata.fh"
      Real*8     xNum
      Integer    length
      Character InString*(*)
      Character*1  OneDigit
      Character*2  TwoDigits
!!
      length = Len(InString)
      Write(6,*)' The string is:',InString
      Write(6,*)' Its length is:',length
      if(length.lt.10) then
      Write(OneDigit,'(i1)') length
      Write(6,*)'   OneDigit is:',OneDigit
      Write(6,*)' The format is:','(f'//OneDigit//'.0)'
      read(InString,'(f'//OneDigit//'.0)') xnum
      else
      Write(TwoDigits,'(i2)') length
      Write(6,*)'  TwoDigits is:',TwoDigits
      Write(6,*)' The format is:','(f'//TwoDigits//'.0)'
      read(InString,'(f'//TwoDigits//'.0)') xNum
      end if
      StrToDble=xNum
      End

!!-----------------------------------------------------------------------!
!!
      Function iStrToInt(InLine)
!!
!!  Purpose:
!!    Convert a number in string InLine to integer.
!!
!!  Input:
!!    InLine   : Character string.
!!
!!  Output:
!!    num      : Integer.
!!
      Integer          num
      Character InLine*(*)
      Character ch
      Logical   minus
      IntVal(ch) = Index('0123456789',ch)-1
!!
      length = Len(InLine)
!!
!!---- Convert from string to integer.
      isum = 0
      i = 0
      minus = .false.
      Do nPos = length,1,-1
      If ( InLine(nPos:nPos).eq.'-' ) Then
      minus = .true.
      Else
      ch = InLine(nPos:nPos)
      isum = isum+IntVal(ch)*10**(i)
      i = i+1
      End If
      End Do
!!
      If ( minus ) Then
      num =-isum
      Else
      num = isum
      End If
!!
      iStrToInt=num
      End
!!
!!-----------------------------------------------------------------------!
!!-----------------------------------------------------------------------!
!!
      Subroutine Normalize(line,line2)
!!
!!  Purpose:
!!    Convert a string to uppercase characters.
!!
!!  Input:
!!    line     : Character string.
!!
!!  Output:
!!    line2    : Character string - uppercase letters.
!!
!!  Written by:
!!    P-AA Malmquist,
!!    Dept. of Theoretical Chemistry, Lund University.
!!
      Parameter (ntrans = 256)
#include "inputdata.fh"
      Character line*(*)
      Character line2*(*)
      Character*26  lcase,ucase
      Character*1  ch
      Integer itrans ( ntrans )
      Logical wrdend
      Intrinsic ichar,char,len
      Data icalled /0/
      Data lcase,ucase/'abcdefghijklmnopqrstuvwxyz',                    &
     &                          'ABCDEFGHIJKLMNOPQRSTUVWXYZ' /
!!
!!---- Set up character transformation table:
      If ( icalled.eq.0 ) Then
      Do i = 1,ntrans
      itrans(i) = i
      End Do
      Do j = 1,len(lcase)
      i = ichar(lcase(j:j))
      itrans(i) = ichar(ucase(j:j))
      End Do
      End If
      len1 = len(line)
      len2max = len(line2)
      ista = 0
!! Find first non-blank character, at position ista.
      Do i = 1,len1
      ch = line(i:i)
      If ( ch.ne.' ' ) Then
      ista = i
      goto 11
      End If
      End Do
 11    Continue
      line2 = ' '
      If ( ista.eq.0 ) Return
      wrdend = .false.
      len2 = 0
      Do i = ista,len1
      ch = line(i:i)
      If ( ch.ne.' ' ) Then
      If ( wrdend ) Then
      If ( len2.gt.len2max-1 ) Goto 99
      line2(len2+1:len2+1) = ' '
      len2 = len2+1
      End If
      If ( len2.gt.len2max-1 ) Goto 99
      ch = char(itrans(ichar(ch)))
      line2(len2+1:len2+1) = ch
      len2 = len2+1
      wrdend = .false.
      Else
      wrdend = .true.
      End If
      End Do
      Return
 99    Continue
      Write(6,*)' WARNING: Line truncated in NORMALIZE.'
!!
      End
