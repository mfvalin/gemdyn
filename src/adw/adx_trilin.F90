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
#include "msg.h"

!/@*
subroutine adx_trilin5(F_xo,F_yo,F_u1,F_u2,F_xth,F_yth,F_zth, &
     F_dth,F_has_u2_L, F_i0,F_in,F_j0,F_jn, &
     F_ni,F_nj,F_aminx, F_amaxx, F_aminy, F_amaxy,F_k0,F_nk,F_nk_winds)
   implicit none
#include <arch_specific.hf>
   !@objective switcher to call adx_setint/adx_trilin or adx_trilin_turbo
   !@arguments
   logical :: F_has_u2_L               !I, .T. if F_u2 needs to be treated
   real    :: F_dth
   integer :: F_nk, F_nk_winds         !I, number of vertical levels (may be super grid for winds)
   integer :: F_aminx, F_amaxx, F_aminy, F_amaxy !I, wind fields array bounds
   integer :: F_ni, F_nj               !I, dims of position fields
   integer :: F_i0,F_in,F_j0,F_jn,F_k0 !I, operator scope
   real,dimension(F_ni,F_nj,F_nk) :: F_xth,F_yth,F_zth !I, x,y,z positions
   real,dimension(F_aminx:F_amaxx,F_aminy:F_amaxy,F_nk_winds) :: &
        F_u1, F_u2  !I, field to interpol
   real,dimension(F_ni,F_nj,F_nk) :: F_xo,F_yo !O, result of interp
   !@author Stephane Chamberland 
   !@revisions
   ! v4_40 - Tanguay M.        - Revision TL/AD
   ! v4_70 - PLante A.         - remove adw_nosetint_L
!*@/
#include "adx_dims.cdk"
#include "adx_grid.cdk"
#include "adx_interp.cdk"

   integer :: num,iimax
   integer, dimension(F_ni,F_nj,F_nk) :: loci,locj,lock
   real,    dimension(F_ni,F_nj,F_nk) :: capz1
   real*8 p_z00_8
   real*8,  dimension(:), pointer :: p_bsz_8
   integer, dimension(:), pointer :: p_lcz
   !---------------------------------------------------------------------
   call msg(MSG_DEBUG,'adx_trilin [begin]')
   num = F_ni*F_nj*F_nk
   
   p_z00_8 = adx_verZ_8%m(0)
   p_lcz   => adx_lcz%m
   p_bsz_8 => adx_bsz_8%m      
   if(adx_superwinds_L)then
      p_lcz   => adx_lcz%s
      p_bsz_8 => adx_bsz_8%s
   endif
   iimax   = adx_iimax+1
   call adx_trilin_ijk1 (                                              &
        F_xth, F_yth, F_zth, capz1, loci, locj, lock,                   &
        adx_lcx, adx_lcy, p_lcz, adx_bsx_8, adx_bsy_8, p_bsz_8, &
        adx_diz_8, p_z00_8, iimax,                                      &
        num, F_i0, F_in, F_j0, F_jn, F_k0, F_nk, adx_lnk)
   
   call adx_trilin_turbo3 (F_xo, F_u1, F_dth,      &
        F_xth, F_yth, capz1, loci, locj, lock,      &
        adx_bsx_8, adx_bsy_8, adx_xbc_8, adx_ybc_8, &
        num, F_i0, F_in, F_j0, F_jn, F_k0, F_nk)
   
   if (F_has_u2_L) then
      call adx_trilin_turbo3 (F_yo, F_u2, F_dth,      &
           F_xth, F_yth, capz1, loci, locj, lock,      &
           adx_bsx_8, adx_bsy_8, adx_xbc_8, adx_ybc_8, &
           num, F_i0, F_in, F_j0, F_jn, F_k0, F_nk)
   endif
   
   call msg(MSG_DEBUG,'adx_trilin [end]')
   !---------------------------------------------------------------------
   return
end subroutine adx_trilin5
!=========================================================================
subroutine adx_trilin4()
   print*,'Called a stum adx_trilin4'
   stop
end subroutine adx_trilin4
