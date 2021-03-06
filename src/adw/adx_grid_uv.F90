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
subroutine adx_grid_uv ( F_u_adw, F_v_adw, F_u_model,F_v_model, &
                         F_aminx,F_amaxx,F_aminy,F_amaxy,       &
                         F_minx,F_maxx,F_miny,F_maxy,F_nk)
   implicit none
#include <arch_specific.hf>
!
   !@objective Extend the grid from model to adw with filled halos
!
   !@arguments
   integer :: F_aminx,F_amaxx,F_aminy,F_amaxy !I, adw local array bounds
   integer :: F_minx,F_maxx,F_miny,F_maxy     !I, model's local array bounds
   integer :: F_nk             !I, number of levels
   real,dimension(F_minx:F_maxx,F_miny:F_maxy,F_nk) :: &
        F_u_model, F_v_model   !I, winds on model-grid
   real,dimension(F_aminx:F_amaxx,F_aminy:F_amaxy,F_nk) :: &
        F_u_adw ,F_v_adw       !O, winds on adw-grid
!*@/

#include "adx_dims.cdk"

   integer :: nrow, j1

   !---------------------------------------------------------------------

   call msg(MSG_DEBUG,'adx_model2adx_grid_uv')
   nrow = 999
   if (adx_lam_L) nrow = 0
   call rpn_comm_xch_halox( &
        F_u_model, F_minx,F_maxx,F_miny,F_maxy, &
        adx_mlni, adx_mlnj, F_nk, adx_halox, adx_haloy, &
        adx_is_period_x, adx_is_period_y, &
        F_u_adw, F_aminx,F_amaxx,F_aminy,F_amaxy, adx_lni, nrow)
   call rpn_comm_xch_halox( &
        F_v_model, F_minx,F_maxx,F_miny,F_maxy, &
        adx_mlni, adx_mlnj, F_nk, adx_halox, adx_haloy, &
        adx_is_period_x, adx_is_period_y, &
        F_v_adw, F_aminx,F_amaxx,F_aminy,F_amaxy, adx_lni, nrow)

!$omp parallel private(j1)
   if (.not.adx_lam_L) then
      if (adx_is_south) then
         j1 = 0
         call adx_polw3(F_u_adw, F_v_adw, &
              j1, F_aminx,F_amaxx,F_aminy,F_amaxy, adx_lni,adx_lnj, adx_haloy,adx_halox, F_nk)
      endif
      if (adx_is_north) then
         j1 = adx_lnj+1
         call adx_polw3(F_u_adw, F_v_adw, &
              j1, F_aminx,F_amaxx,F_aminy,F_amaxy, adx_lni,adx_lnj, adx_halox,adx_haloy, F_nk)
     endif
   endif
!$omp end parallel

   call msg(MSG_DEBUG,'adx_model2adx_grid_uv [end]')

   !---------------------------------------------------------------------

   return
end subroutine adx_grid_uv
