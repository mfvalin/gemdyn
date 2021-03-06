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

!/@*
subroutine adx_get_params()
   implicit none
#include <arch_specific.hf>
   !@objective Get model/dyn parameters from whiteboard
   !@author Stephane Chamberland, 2010-01
   !@revisions
   ! v4_14 PLante A.    - add 'model/gbpil_t',adx_gbpil_t
   ! v4_40 - Qaddouri/Lee - add Adx_yinyang_L key
   !*@/
#include <WhiteBoard.hf>
#include "adx_dims.cdk"
#include "adx_gmm.cdk"
#include "adx_dyn.cdk"
#include "adx_grid.cdk"
   integer :: istat, nbvals, i, j
   integer :: gminx,gmaxx,gminy,gmaxy,minzm,maxzm,minzt,maxzt
   real*8,dimension(:),allocatable :: xg_8, yg_8,v_zm_8,v_zt_8
   !---------------------------------------------------------------------
   istat = wb_verbosity(WB_MSG_INFO)

   istat = WB_OK
   istat = min(wb_get('model/maxcfl',adx_maxcfl),istat)
   istat = min(wb_get('model/is_lam',adx_lam_L),istat)
   istat = min(wb_get('model/is_yinyang',adx_yinyang_L),istat)
   istat = min(wb_get('model/is_period_x',adx_is_period_x),istat)
   istat = min(wb_get('model/is_period_y',adx_is_period_y),istat)
   istat = min(wb_get('model/G_ni',adx_gni),istat)
   istat = min(wb_get('model/G_nj',adx_gnj),istat)
   istat = min(wb_get('model/G_niu',adx_gniu),istat)
   istat = min(wb_get('model/G_njv',adx_gnjv),istat)
   istat = min(wb_get('model/l_ni',adx_mlni),istat)
   istat = min(wb_get('model/l_nj',adx_mlnj),istat)
   istat = min(wb_get('model/l_nk',adx_lnk),istat)
   istat = min(wb_get('model/l_i0',adx_mli0),istat)
   istat = min(wb_get('model/l_j0',adx_mlj0),istat)
   istat = min(wb_get('model/l_niu',adx_mlniu),istat)
   istat = min(wb_get('model/l_njv',adx_mlnjv),istat)
   istat = min(wb_get('model/G_halox',adx_mhalox),istat)
   istat = min(wb_get('model/G_haloy',adx_mhaloy),istat)
   istat = min(wb_get('model/l_minx',adx_mlminx),istat)
   istat = min(wb_get('model/l_maxx',adx_mlmaxx),istat)
   istat = min(wb_get('model/l_miny',adx_mlminy),istat)
   istat = min(wb_get('model/l_maxy',adx_mlmaxy),istat)

   istat = min(wb_get('model/l_north',adx_is_north),istat)
   istat = min(wb_get('model/l_south',adx_is_south),istat)
   istat = min(wb_get('model/l_east',adx_is_east),istat)
   istat = min(wb_get('model/l_west',adx_is_west),istat)
   istat = min(wb_get('model/pil_n',adx_pil_n),istat)
   istat = min(wb_get('model/pil_s',adx_pil_s),istat)
   istat = min(wb_get('model/pil_w',adx_pil_w),istat)
   istat = min(wb_get('model/pil_e',adx_pil_e),istat)
   istat = min(wb_get('model/gbpil_t',adx_gbpil_t),istat)
   istat = min(wb_get('model/trapeze',adx_trapeze_L),istat)
   istat = min(wb_get('model/cub_traj',adx_cub_traj_L),istat)
   istat = min(wb_get('model/superwinds',adx_superwinds_L),istat)

   istat = min(wb_get('model/cstv_dt',adx_dt_8),istat)

   istat = min(wb_get('model/Tlift',adx_Tlift),istat)

   istat = min(wb_get('model/gmm/xth_m',adx_xth_s),istat)
   istat = min(wb_get('model/gmm/yth_m',adx_yth_s),istat)
   istat = min(wb_get('model/gmm/zth_m',adx_zth_s),istat)

   istat = min(wb_get('model/gmm/xcth_m',adx_xcth_s),istat)
   istat = min(wb_get('model/gmm/ycth_m',adx_ycth_s),istat)
   istat = min(wb_get('model/gmm/zcth_m',adx_zcth_s),istat)

   istat = min(wb_get('model/gmm/xct1_m',adx_xct1_s),istat)
   istat = min(wb_get('model/gmm/yct1_m',adx_yct1_s),istat)
   istat = min(wb_get('model/gmm/zct1_m',adx_zct1_s),istat)

   call handle_error_l(WB_IS_OK(istat),'adx_get_params','problem getting values from whiteboard, bloc 1')

   adx_maxcfl = max(1,adx_maxcfl)
   adx_halox = max(1,adx_maxcfl + 1)
   adx_haloy = adx_halox

   if (adx_lam_L) then
      adx_li0 = adx_mli0
      adx_lni = adx_mlni
      adx_int_i_off = adx_mli0 - 1
   else
      adx_halox = max(3,adx_halox)
      adx_haloy = max(2,adx_haloy)
      adx_li0 = 1
      adx_lni = adx_gni
      adx_int_i_off = 0
   endif
   adx_lnj = adx_mlnj
   adx_lj0 = adx_mlj0
   adx_int_j_off = adx_mlj0 - 1
   adx_trj_i_off = adx_mli0 - adx_li0

   adx_gminx = 1 - adx_halox
   adx_gmaxx = adx_gni + adx_halox
   adx_gminy = 1 - adx_haloy
   adx_gmaxy = adx_gnj + adx_haloy

   adx_lminx = 1 - adx_halox
   adx_lmaxx = adx_lni + adx_halox
   adx_lminy = 1 - adx_haloy
   adx_lmaxy = adx_lnj + adx_haloy

   adx_iimax = adx_gni+2*adx_halox-2
   adx_jjmax = adx_gnj+adx_haloy
   adx_nit = adx_lmaxx - adx_lminx + 1
   adx_njt = adx_lmaxy - adx_lminy + 1
   adx_nijag = adx_nit * adx_njt
   adx_mlnij = adx_mlni*adx_mlnj

   istat = WB_OK
   istat = min(wb_get('model/G_xg_8/min',gminx),istat)
   istat = min(wb_get('model/G_xg_8/max',gmaxx),istat)
   istat = min(wb_get('model/G_yg_8/min',gminy),istat)
   istat = min(wb_get('model/G_yg_8/max',gmaxy),istat)

   istat = min(wb_get('model/v_zm_8/min',minzm),istat)
   istat = min(wb_get('model/v_zm_8/max',maxzm),istat)
   istat = min(wb_get('model/v_zt_8/min',minzt),istat)
   istat = min(wb_get('model/v_zt_8/max',maxzt),istat)

   call handle_error_l(WB_IS_OK(istat),'adx_get_params','problem getting values from whiteboard, bloc 2')

   allocate( &
        xg_8(gminx:gmaxx), &
        yg_8(gminy:gmaxy), &
        v_zm_8(minzm:maxzm), &
        v_zt_8(minzt:maxzt), &
        adx_xg_8(adx_gminx:adx_gmaxx), &
        adx_yg_8(adx_gminy:adx_gmaxy), &
        adx_verz_8%m(minzm:maxzm), &
        adx_verz_8%t(minzt:maxzt), &
        stat = istat)
   call handle_error_l(istat==0,'','problem allocating mem')

   istat = WB_OK
   istat = min(wb_get('model/G_xg_8',xg_8,nbvals),istat)
   istat = min(wb_get('model/G_yg_8',yg_8,nbvals),istat)
   istat = min(wb_get('model/v_zm_8',v_zm_8,nbvals),istat)
   if (nbvals /= maxzm-minzm+1) istat = WB_ERROR
   istat = min(wb_get('model/v_zt_8',v_zt_8,nbvals),istat)
   if (nbvals /= maxzt-minzt+1) istat = WB_ERROR

   call handle_error_l(WB_IS_OK(istat),'adx_get_params','problem getting values from whiteboard, bloc 3')

   do i = 1,adx_gni
      adx_xg_8(i) = xg_8(i)
   enddo
   do j = 1,adx_gnj
      adx_yg_8(j) = yg_8(j)
   enddo

   adx_verz_8%m(:) = v_zm_8(:)
   adx_verz_8%t(:) = v_zt_8(:)

   deallocate(xg_8, yg_8, v_zm_8, v_zt_8)
   !---------------------------------------------------------------------
   return
end subroutine adx_get_params

