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
#include "stop_mpi.h"
#include "msg.h"

!/@*
subroutine adx_grid_scalar (F_fld_adw, F_fld_model,          &
                            F_aminx,F_amaxx,F_aminy,F_amaxy, &
                            F_minx,F_maxx,F_miny,F_maxy,F_nk,F_pol0_L,F_extend_L)
   implicit none
#include <arch_specific.hf>
!
   !@objective Extend the grid from model to adw with filled halos
!
   !@arguments
   logical :: F_extend_L  !I, Extend field beyond poles
   logical :: F_pol0_L    !I, Set values=0 around poles (e.g. 4 winds)
   integer :: F_aminx,F_amaxx,F_aminy,F_amaxy !I, adw local array bounds
   integer :: F_minx,F_maxx,F_miny,F_maxy     !I, model's local array bounds
   integer :: F_nk        !I, number of levels
   real, dimension(F_minx:F_maxx,F_miny:F_maxy,F_nk) :: &
        F_fld_model       !I, fld on model-grid
   real, dimension(F_aminx:F_amaxx,F_aminy:F_amaxy,F_nk) :: &
        F_fld_adw         !O, fld on adw-grid
!*@/

#include "adx_dims.cdk"

   integer :: nrow
   logical :: is_south_L

   !---------------------------------------------------------------------

   call msg(MSG_DEBUG,'adx_model2adx_grid_scalar')

   nrow = 999
   if (adx_lam_L) nrow = 0
   call rpn_comm_xch_halox( &
        F_fld_model, F_minx,F_maxx,F_miny,F_maxy, &
        adx_mlni, adx_mlnj, F_nk, adx_halox, adx_haloy, &
        adx_is_period_x, adx_is_period_y, &
        F_fld_adw, F_aminx,F_amaxx,F_aminy,F_amaxy, adx_lni, nrow)

   if (.not.adx_lam_L) then
      if (adx_is_south) then
         is_south_L = .true.
         call adx_pole0s2(F_fld_adw, F_fld_model, &
              F_aminx,F_amaxx,F_aminy,F_amaxy,F_minx,F_maxx,F_miny,F_maxy,&
              F_nk, F_pol0_L, F_extend_L, is_south_L)
      endif

      if (adx_is_north) then
         is_south_L = .false.
         call adx_pole0s2(F_fld_adw, F_fld_model, &
              F_aminx,F_amaxx,F_aminy,F_amaxy,F_minx,F_maxx,F_miny,F_maxy,&
              F_nk, F_pol0_L, F_extend_L, is_south_L)
      endif
   endif

   call msg(MSG_DEBUG,'adx_model2adx_grid_scalar [end]')

   !---------------------------------------------------------------------

   return
end subroutine adx_grid_scalar
