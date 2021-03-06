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

!**s/r theo_3D
!

!
      subroutine theo_3D_2( F_u, F_v, F_w, F_t, F_zd, F_s, F_q, F_topo, &
                           pref_tr, suff_tr )
      implicit none
#include <arch_specific.hf>
!
      character* (*) pref_tr,suff_tr
      real F_u(*), F_v(*), F_w (*), F_t(*), F_zd(*), &
           F_s(*), F_topo(*), F_q(*)
!
#include "theo.cdk"
#include "glb_ld.cdk"
!
!---------------------------------------------------------------------
!
      if ( Theo_case_S.eq.'MTN_SCHAR'  &
           .or. Theo_case_S.eq.'MTN_SCHAR2' &
           .or. Theo_case_S.eq.'MTN_PINTY' &
           .or. Theo_case_S.eq.'MTN_PINTY2' &
           .or. Theo_case_S.eq.'MTN_PINTYNL' &
           .or. Theo_case_S.eq.'NOFLOW' ) then
         call mtn_case2( F_u, F_v, F_w, F_t, F_zd, F_s, F_topo, &
                         F_q, pref_tr, suff_tr, &
                         l_minx, l_maxx, l_miny, l_maxy )
      else
         call abort
      endif
!
!---------------------------------------------------------------------
      return
      end



