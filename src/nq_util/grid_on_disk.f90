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
Module Grid_On_Disk
      Integer Regenerate, Use_Old, Grid_Status, G_S
      Parameter(Regenerate=1,Use_Old=0)
      Integer Intermediate, Final, Not_Specified, Old_Functional_Type, LuGridFile
      Parameter (Intermediate=2, Final=1, Not_Specified=0)
      Parameter(nBatch_Max=500)
      Integer, Allocatable:: GridInfo(:,:)
      Common /GridOnDisk/ Lu_Grid,            iDisk_Grid,jDisk_Grid,       &
     &                    iBatchInfo(3,nBatch_Max), nBatch,                &
     &                    Grid_Status, G_S(2),iDisk_Set(2),                &
     &                    Old_Functional_Type,iGrid_Set,LuGridFile
End Module Grid_On_Disk
