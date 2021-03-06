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

subroutine adx_main ( F_ud, F_vd, F_wd, F_ua, F_va, F_wa, F_wat, &
                      F_minx, F_maxx, F_miny, F_maxy,F_nk_winds, &
                      F_nb_iter, F_doAdwStat_L )
   implicit none
#include <arch_specific.hf>

   !@objective Perform advection
   !@arguments

   logical, intent(in) :: F_doAdwStat_L   ! will compute stats if .true.
   integer, intent(in) :: F_nb_iter       ! total number of iterations for trajectories
   integer, intent(in) :: F_minx,F_maxx,F_miny,F_maxy ! bounds of model's wind arrays
   integer, intent(in) :: F_nk_winds      ! nb of wind levels (momentum or super winds)
   real, dimension(F_minx:F_maxx,F_miny:F_maxy, F_nk_winds), intent(in) :: F_ud, F_vd, F_wd ! real destag winds
   real, dimension(*), intent(in) :: F_ua, F_va, F_wa, F_wat

   !@author  alain patoine
   !@revisions
   ! v3_00 - Desgagne & Lee           - Lam configuration
   ! v3_01 - Lee V.                   - Initialize Lam truncated trajectory counters
   ! v3_20 - Tanguay M.               - Option of storing instead of redoing TRAJ
   ! v4_04 - Tanguay M.               - Staggered version TL/AD
   ! V4_10 - Plante A.                - Thermo upstream positions
   ! V4_14 - Plante A.                - No advection in top pilote zone
   ! V4_30 - Plante A.                - Added Adw_thermopos_S
   ! v4_40 - Tanguay M.               - Revision TL/AD
   ! v4.70 - Girard C., Gaudreault S. - Compute trajectories using angular displacement (optional)
   ! v4.80 - Tanguay M.               - GEM4 Mass-Conservation and FLUX calculations 
   !@description
   !  adx_main_2_pos: Calculate upstream positions at th and t1
   !  adx_main_3_int: Interpolation of rhs

#include <gmm.hf>
#include "adx_gmm.cdk"
#include "adx_dims.cdk"
#include "adx_nml.cdk"
#include "adx_pos.cdk"
#include "glb_ld.cdk"
#include "orh.cdk"
#include "schm.cdk"
#include "tracers.cdk"

   logical, parameter :: POLE0_L  = .false.
   logical, parameter :: EXTEND_L = .false.

   integer :: err,i0,in,j0,jn,k0,k0t
   real, dimension(adx_mlni,adx_mlnj,adx_lnk) :: pxm,pym,pzm,wdm
   real, dimension(adx_lminx:adx_lmaxx,adx_lminy:adx_lmaxy,F_nk_winds) :: &
        a_ud,a_vd,a_wd

   real, pointer, dimension(:) :: xth, yth, zth, xcth, ycth, zcth, &
                                  xct1, yct1, zct1
   !---------------------------------------------------------------------
   nullify (xth, yth, zth, xcth, ycth, zcth, xct1, yct1, zct1)
!  nullify (pxt, pyt, pzt, pxmu, pymu, pzmu, pxmv, pymv, pzmv)
   if (.not.associated(pxt)) then
      allocate (pxt(adx_mlni,adx_mlnj,adx_lnk), &
                                       pyt(adx_mlni,adx_mlnj,adx_lnk), &
                                       pzt(adx_mlni,adx_mlnj,adx_lnk), &
                                       pxmu(adx_mlni,adx_mlnj,adx_lnk), &
                                       pymu(adx_mlni,adx_mlnj,adx_lnk), &
                                       pzmu(adx_mlni,adx_mlnj,adx_lnk), &
                                       pxmv(adx_mlni,adx_mlnj,adx_lnk), &
                                       pymv(adx_mlni,adx_mlnj,adx_lnk), &
                                       pzmv(adx_mlni,adx_mlnj,adx_lnk)  )
      pxt=0.; pyt=0.; pzt=0.; pxmu=0.; pymu=0.; pzmu=0.; pxmv=0.; pymv=0.; pzmv=0.
   endif

   k0 = adx_gbpil_t+1
   k0t= k0
   if(adx_gbpil_t.gt.0) k0t=k0-1

   call adx_grid_uv (a_ud,a_vd, F_ud,F_vd,                    &
                     adx_lminx,adx_lmaxx,adx_lminy,adx_lmaxy, &
                     F_minx,F_maxx,F_miny,F_maxy, F_nk_winds)

   call adx_grid_scalar (a_wd,F_wd, adx_lminx, adx_lmaxx    , &
                         adx_lminy, adx_lmaxy, F_minx,F_maxx, &
                         F_miny,F_maxy, F_nk_winds, POLE0_L, EXTEND_L)

   err = gmm_get(adx_xth_s , xth)
   err = gmm_get(adx_yth_s , yth)
   err = gmm_get(adx_zth_s , zth)

   err = gmm_get(adx_xcth_s,xcth)
   err = gmm_get(adx_ycth_s,ycth)
   err = gmm_get(adx_zcth_s,zcth)

   err = gmm_get(adx_xct1_s,xct1)
   err = gmm_get(adx_yct1_s,yct1)
   err = gmm_get(adx_zct1_s,zct1)

   call timing_start2 (30, 'ADW_TRAJE', 21)  ! Compute trajectories

   ! Note : with lid nesting, we compute momentum pos from k0t-2 to allow for
   !        cubic interpolation in adx_cubicpos

   if (Tr_extension_L) then
      call adx_get_ij0n_ext (i0,in,j0,jn)
   else
      call adx_get_ij0n (i0,in,j0,jn)
   endif

   if (G_lam) then
      call adx_pos_angular_m (F_nb_iter, pxm , pym , pzm             , &
                              a_ud, a_vd, a_wd, F_ua, F_va, F_wa, wdm, &
                              xth, yth, zth, adx_lminx, adx_lmaxx , &
                              adx_lminy,adx_lmaxy, adx_mlni,adx_mlnj , &
                              max(k0t-2,1), adx_lnk, F_nk_winds)

      call adx_pos_muv (pxmu, pymu, pzmu, pxmv, pymv, pzmv, pxm, pym, pzm, &
                        adx_mlni, adx_mlnj, k0, adx_lnk, i0,in,j0,jn)

      call adx_pos_angular_t (pxt,pyt,pzt,pxm,pym,pzm,F_wat,wdm, &
                              adx_mlni,adx_mlnj,k0t,adx_lnk , &
                              i0,in,j0,jn, .true.)


   else
      call adx_pos_m (F_nb_iter, pxm , pym , pzm             , &
                      a_ud, a_vd, a_wd, F_ua, F_va, F_wa, wdm, &
                      xth , yth , zth , xcth, ycth, zcth     , &
                      xct1, yct1, zct1, adx_lminx, adx_lmaxx , &
                      adx_lminy,adx_lmaxy, adx_mlni,adx_mlnj , &
                      max(k0t-2,1), adx_lnk, F_nk_winds)

      call adx_pos_t (pxt,pyt,pzt,pxm,pym,pzm,F_wat,wdm, &
                      adx_mlni,adx_mlnj,k0t,adx_lnk , &
                      i0,in,j0,jn, .true.)
   end if

   call timing_stop (30)

!   if (F_doAdwStat_L .and. adw_stats_L) then
!      call adx_stats('m', a_ud  ,a_vd  ,a_wd                , &
!                     pxm,  pym,  pzm , xth , yth , zth      , &
!                     xcth, ycth, zcth, xct1, yct1, zct1     , &
!                     adx_lminx,adx_lmaxx,adx_lminy,adx_lmaxy, &
!                     F_nk_winds,adx_mlni, adx_mlnj, adx_lnk, &
!                     adx_lnk,i0,in,j0,jn,k0,adx_lnk )
!   endif

   call timing_start2 (31, 'ADW_INLAG', 21)  ! Interpolate

   call adx_int_rhs ( pxm, pym, pzm, .true. , F_doAdwStat_L, &
                      pxmu,pymu,pzmu,pxmv,pymv,pzmv, &
                      adx_mlni, adx_mlnj, k0 , adx_lnk )

   call adx_int_rhs ( pxt, pyt, pzt, .false., F_doAdwStat_L, &
                      pxmu,pymu,pzmu,pxmv,pymv,pzmv, &
                      adx_mlni, adx_mlnj, k0t, adx_lnk )

   call timing_stop (31)

   !---------------------------------------------------------------------
   return


end subroutine adx_main

