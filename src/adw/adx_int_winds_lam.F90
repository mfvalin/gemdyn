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
#include "constants.h"
#include "msg.h"
#include "stop_mpi.h"

!/@*
subroutine adx_int_winds_lam(F_wrkx1,F_wrky1,F_u1,F_u2,F_xth,F_yth,F_zth, &
                             F_dth, F_cliptraj_L, F_has_u2_L, F_i0,F_in,F_j0,F_jn, &
                             F_ni,F_nj,F_aminx, F_amaxx, F_aminy, F_amaxy,F_k0,F_nk, F_nk_super)
   implicit none
#include <arch_specific.hf>
   !@objective
   !@arguments
   logical, intent(in) :: F_cliptraj_L                                                  ! .T. to clip trajectories
   logical, intent(in) :: F_has_u2_L                                                    ! .T. if F_u2 needs to be treated
   real, intent(in)    :: F_dth                                                         ! factor (1. or timestep)
   integer, intent(in) :: F_nk, F_nk_super                                              ! number of vertical levels
   integer, intent(in) :: F_aminx, F_amaxx, F_aminy, F_amaxy                            ! wind fields array bounds
   integer, intent(in) :: F_ni, F_nj                                                    ! dims of position fields
   integer, intent(in) :: F_i0,F_in,F_j0,F_jn,F_k0                                      ! operator scope
   real, dimension(F_ni,F_nj,F_nk), intent(inout) :: F_xth,F_yth                        ! x,y positions
   real, dimension(F_ni,F_nj,F_nk), intent(in) :: F_zth                                 ! z positions
   real, dimension(F_aminx:F_amaxx,F_aminy:F_amaxy,F_nk_super), intent(in) :: F_u1,F_u2 ! field to interpol
   real, dimension(F_ni,F_nj,F_nk), intent(out) :: F_wrkx1,F_wrky1                      ! F_dt * result of interp
!
   !@revisions
   !  2015-11,  Monique Tanguay    : GEM4 Mass-Conservation and FLUX calculations
   !*@/
   !---------------------------------------------------------------------
#include "adx_dims.cdk"
#include "adx_nml.cdk"

   integer :: num
   real, dimension(1,1,1), target :: no_conserv,no_flux

   call msg(MSG_DEBUG,'adx_int_winds_lam')
   if (F_cliptraj_L) then
        call adx_cliptraj3(F_xth,F_yth,F_i0,F_in,F_j0,F_jn,F_ni,F_nj,F_k0,F_nk,'')
   end if

   if(adx_cub_traj_L) then
      num=F_ni*F_nj*F_nk

      if (adw_catmullrom_L) then
         call adx_tricub_catmullrom(F_wrkx1, F_u1, F_xth,F_yth,F_zth,num, &
                                    .false., F_i0,F_in,F_j0,F_jn,F_k0,F_nk, 's')
         if(F_has_u2_L) then
            call adx_tricub_catmullrom(F_wrky1, F_u2, F_xth,F_yth,F_zth,num, &
                                       .false., F_i0,F_in,F_j0,F_jn,F_k0,F_nk, 's')
         end if
      else
         call adx_tricub_lag3d7(F_wrkx1, no_conserv, no_conserv, no_conserv, no_conserv, F_u1, &
                                no_flux, no_flux, no_flux, no_flux, 0,                         &
                                F_xth,F_yth,F_zth,num,                                         &
                                .false.,.false.,F_i0,F_in,F_j0,F_jn,F_k0,F_nk, 's')
         if(F_has_u2_L) then
            call adx_tricub_lag3d7(F_wrky1, no_conserv, no_conserv, no_conserv, no_conserv, F_u2, &
                                   no_flux, no_flux, no_flux, no_flux, 0,                         &
                                   F_xth,F_yth,F_zth,num,                                         &
                                   .false.,.false.,F_i0,F_in,F_j0,F_jn,F_k0,F_nk, 's')
         end if
      end if
   else
      call adx_trilin5(F_wrkx1,F_wrky1,F_u1,F_u2,F_xth,F_yth,F_zth, &
           F_dth, F_has_u2_L, F_i0,F_in,F_j0,F_jn, &
           F_ni,F_nj,F_aminx, F_amaxx, F_aminy, F_amaxy,F_k0,F_nk, F_nk_super)
   endif

   call msg(MSG_DEBUG,'adx_int_winds_lam [end]')
   !---------------------------------------------------------------------
   return
end subroutine adx_int_winds_lam
