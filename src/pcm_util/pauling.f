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
      Function Pauling(N)
      Implicit Real*8 (A-H,O-Z)
!
!     Pauling radius for atomic number N (UFF when not defined)
!
      Dimension R(110)
      Save R
      Data R/                                                           &
!        H             He
     & 1.20D+00,      1.20D+00,                                         &
!       Li            Be           B               C            N
     & 1.37D+00,     1.45D+00,    1.45D+00,       1.50D+00,    1.50D+00,&
!       O             F            Ne
     & 1.40D+00,     1.35D+00,    1.30D+00,                             &
!       Na            Mg           Al              Si           P
     & 1.57D+00,     1.36D+00,    1.24D+00,       1.17D+00,    1.90D+00,&
!       S             Cl           Ar
     & 1.85D+00,     1.80D+00,    1.88D+00,                             &
!       K             Ca (n.a.)
     & 2.75D+00,     0.00D+00,                                          &
!       Sc(n.a.)      Ti (n.a)     V (n.a.)        Cr (n.a.)    Mn (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Fe            Co           Ni              Cu           Zn
     & 0.00D+00,     0.00D+00,    1.63D+00,       1.40D+00,    1.39D+00,&
!       Ga            Ge (n.a.)    As              Se           Br
     & 1.87D+00,     1.86D+00,    2.00D+00,       2.00D+00,    1.95D+00,&
!       Kr
     & 2.02D+00,                                                        &
!       Rb (n.a.)     Sr (n.a.)
     & 0.00D+00,     0.00D+00,                                          &
!       Y  (n.a.)     Zr (n.a.)    Nb (n.a.)       Mo (n.a.)    Tc (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Ru (n.a.)     Rh (n.a..a.)    Pd              Ag           Cd
     & 0.00D+00,     0.00D+00,    1.63D+00,       1.72D+00,    1.58D+00,&
!       In            Sn           Sb (n.a.)       Te           I
     & 1.93D+00,     2.17D+00,    2.20D+00,       2.20D+00,    2.15D+00,&
!       Xe
     & 2.16D+00,                                                        &
!       Cs (n.a.)     Ba (n.a.)
     & 0.00D+00,     0.00D+00,                                          &
!       La (n.a.)     Ce (n.a.)    Pr (n.a.)       Nd (n.a.)    Pm (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Sm (n.a.)     Eu (n.a.)    Gd (n.a.)       Tb (n.a.)    Dy (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Ho (n.a.)     Er (n.a.)    Tm (n.a.)        Yb (n.a.)    Lu (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Hf (n.a.)
     & 0.00D+00,                                                        &
!       Ta (n.a.)     W (n.a.)     Re (n.a.)       Os (n.a.)    Ir (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Pt            Au           Hg              Tl           Pb
     & 1.72D+00,     1.66D+00,    1.55D+00,       1.96D+00,    1.02D+00,&
!       Bi (n.a.)     Po (n.a.)    At (n.a.)       Rn (n.a.)    Fr (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Ra (n.a.)     Ac (n.a.)    Th (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,                             &
!       Pa (n.a.)     U            Np (n.a.)       Pu (n.a.)    Am (n.a.)
     & 0.00D+00,     1.86D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Cm (n.a.)     Bk (n.a.)    Cf (n.a.)       Es (n.a.)    Fm (n.a.)
     & 0.00D+00,     0.00D+00,    0.00D+00,       0.00D+00,    0.00D+00,&
!       Md (n.a.)
     & 0.00D+00, 9*0.00D+00 /

!     If the Pauling radius is not defined, resort to the UFF value
      If(R(N).eq.0.00D+00) R(N) = UFF_radii(N)

      Pauling = R(N)
      Return
      End
