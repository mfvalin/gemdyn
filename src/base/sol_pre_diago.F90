!---------------------------------- LICENCE BEGIN -------------------------------
! GEM - Library of kernel routines for the GEM numerical atmospheric model
! Copyright (C) 1990-2010 - Division de Recherche en Prevision Numerique
!                       Environnement Canada
! This library is free software; you can redistribute it and/or modify it 
! under the terms of the GNU Lesser General Public License as published by
! the Free Software Foundation, version 2.1 of the License. This library is
! distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
! without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
! PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
! You should have received a copy of the GNU Lesser General Public License
! along with this library; if not, write to the Free Software Foundation, Inc.,
! 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
!---------------------------------- LICENCE END ---------------------------------

!**s/r  sol_pre_diago -  call diagonal Preconditionner  
!

!
!
      subroutine  sol_pre_diago ( wk22, wk11, Minx,Maxx,Miny,Maxy, &
                                  nil,njl, minx1,maxx1,minx2,maxx2 )
      implicit none
#include <arch_specific.hf>
!
      integer Minx,Maxx,Miny,Maxy,nil,njl, minx1,maxx1,minx2,maxx2
      real*8  wk11(*),wk22(*)
!
! author    Abdessamad Qaddouri -  December 2006
!
!revision
! v3_30 - Qaddouri A.       - initial version
!
#include "schm.cdk"
#include "sol.cdk"

      real*8 wint_8 (Minx:Maxx,Miny:Maxy,Schm_nith)
!
!     ---------------------------------------------------------------
!
      call  tab_vec  ( wint_8 , Minx,Maxx,Miny,Maxy,Schm_nith, &
                       wk11   , sol_i0,sol_in,sol_j0,sol_jn, -1 )
!
      call pre_diago ( wint_8 , wint_8, Minx, Maxx, Miny, Maxy,nil, &
                          njl,minx1, maxx1, minx2, maxx2,Schm_nith )
!
      call  tab_vec  ( wint_8 , Minx,Maxx,Miny,Maxy,Schm_nith, &
                       wk22   , sol_i0,sol_in,sol_j0,sol_jn, +1 )
!
!     ---------------------------------------------------------------
!
      return
      end
