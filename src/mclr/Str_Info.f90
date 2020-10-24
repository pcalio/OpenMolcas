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
! Copyright (C) 2020, Roland Lindh                                     *
!***********************************************************************
!        OCSTR        :        Offsets for occupation of strings
!        STREO        :        reordering array
Module Str_Info
      Implicit None
      Type String_Info
           Sequence
           Integer, Pointer:: OCSTR(:)=>Null()
           Integer, Allocatable:: OCSTR_hidden(:)
           Integer, Pointer:: STREO(:)=>Null()
           Integer, Allocatable:: STREO_hidden(:)
      End Type String_Info

      Type (String_Info), Allocatable, Target:: Str(:)
End Module Str_Info
