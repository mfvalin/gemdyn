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
#include <msg.h>

!/@*
subroutine itf_adx_set()
   implicit none
#include <arch_specific.hf>
   !@objective Sets different advection parameters
   !@author Stephane Chamberland, Jan 2010
   !@revisions
   !@ v4_14 Plante A.    - add 'model/gbpil_t',Lam_gbpil_t
   !@ v4_40 Qaddouri/Lee - add Adx_yinyang_L key
!*@/
#include <WhiteBoard.hf>
#include "grd.cdk"
#include "glb_ld.cdk"
#include "ver.cdk"
#include "type.cdk"
#include "schm.cdk"
#include "cstv.cdk"
#include "vth.cdk"
#include "vt1.cdk"
#include "lam.cdk"
!!$      type :: vertical_8
!!$         sequence
!!$         real*8, dimension(:),pointer :: t,m
!!$      end type vertical_8
   character(len=40) :: label
   integer :: istat,options,ij,k
   real*8 :: xg_8(1-G_ni:2*G_ni), yg_8(1-G_nj:2*G_nj)
   real*8 :: v_zm_8(0:l_nk+1), v_zt_8(l_nk)
   !---------------------------------------------------------------------
   call msg(MSG_DEBUG,'itf_adx_set')

   options = WB_REWRITE_NONE+WB_IS_LOCAL

   istat = WB_OK
   istat = min(wb_put('model/maxcfl',grd_maxcfl,options),istat)
   istat = min(wb_put('model/is_lam',G_lam,options),istat)
   istat = min(wb_put('model/is_yinyang',Grd_yinyang_L,options),istat)
   istat = min(wb_put('model/is_period_x',G_periodx,options),istat)
   istat = min(wb_put('model/is_period_y',G_periody,options),istat)
   istat = min(wb_put('model/G_ni',G_ni,options),istat)
   istat = min(wb_put('model/G_nj',G_nj,options),istat)
   istat = min(wb_put('model/G_nk',G_nk,options),istat)
   istat = min(wb_put('model/G_niu',G_niu,options),istat)
   istat = min(wb_put('model/G_njv',G_njv,options),istat)
   istat = min(wb_put('model/G_halox',G_halox,options),istat)
   istat = min(wb_put('model/G_haloy',G_haloy,options),istat)

   istat = min(wb_put('model/l_ni',l_ni,options),istat)
   istat = min(wb_put('model/l_nj',l_nj,options),istat)
   istat = min(wb_put('model/l_nk',l_nk,options),istat)
   istat = min(wb_put('model/l_i0',l_i0,options),istat)
   istat = min(wb_put('model/l_j0',l_j0,options),istat)
   istat = min(wb_put('model/l_niu',l_niu,options),istat)
   istat = min(wb_put('model/l_njv',l_njv,options),istat)

   istat = min(wb_put('model/l_north',l_north,options),istat)
   istat = min(wb_put('model/l_south',l_south,options),istat)
   istat = min(wb_put('model/l_east',l_east,options),istat)
   istat = min(wb_put('model/l_west',l_west,options),istat)
   istat = min(wb_put('model/pil_n',pil_n,options),istat)
   istat = min(wb_put('model/pil_s',pil_s,options),istat)
   istat = min(wb_put('model/pil_w',pil_w,options),istat)
   istat = min(wb_put('model/pil_e',pil_e,options),istat)
   istat = min(wb_put('model/gbpil_t',Lam_gbpil_t,options),istat)
   istat = min(wb_put('model/Tlift',Schm_Tlift,options),istat)
   istat = min(wb_put('model/trapeze',Schm_trapeze_L,options),istat)
   istat = min(wb_put('model/cub_traj',Schm_cub_traj_L,options),istat)
   istat = min(wb_put('model/superwinds',Schm_superwinds_L,options),istat)

   istat = min(wb_put('model/cstv_dt',Cstv_dt_8,options),istat)

   do ij=1-G_ni,2*G_ni
      xg_8(ij) = G_xg_8(ij)
   enddo
   do ij=1-G_nj,2*G_nj
      yg_8(ij) = G_yg_8(ij)
   enddo
   istat = min(wb_put('model/G_xg_8/min',1-G_ni,options),istat)
   istat = min(wb_put('model/G_xg_8/max',2*G_ni,options),istat)
   istat = min(wb_put('model/G_xg_8',xg_8,options),istat)
   istat = min(wb_put('model/G_yg_8/min',1-G_nj,options),istat)
   istat = min(wb_put('model/G_yg_8/max',2*G_nj,options),istat)
   istat = min(wb_put('model/G_yg_8',yg_8,options),istat)

   v_zm_8(0) = Cstv_Ztop_8
   do k=1,l_nk+1
      v_zm_8(k) = Ver_a_8%m(k)
   enddo
   do k=1,l_nk
      v_zt_8(k) = Ver_z_8%t(k)
   enddo
   istat = min(wb_put('model/v_zm_8/min',0,options),istat)
   istat = min(wb_put('model/v_zm_8/max',l_nk+1,options),istat)
   istat = min(wb_put('model/v_zm_8',v_zm_8,options),istat)
   istat = min(wb_put('model/v_zt_8/min',1,options),istat)
   istat = min(wb_put('model/v_zt_8/max',l_nk,options),istat)
   istat = min(wb_put('model/v_zt_8',v_zt_8,options),istat)

   !- Note: a copy to label is needed to patch a whiteboard bug
   label = gmmk_xth_s
   istat = min(wb_put('model/gmm/xth_m',label,options),istat)
   label = gmmk_yth_s
   istat = min(wb_put('model/gmm/yth_m',label,options),istat)
   label = gmmk_zth_s
   istat = min(wb_put('model/gmm/zth_m',label,options),istat)

   label = gmmk_xcth_s
   istat = min(wb_put('model/gmm/xcth_m',label,options),istat)
   label = gmmk_ycth_s
   istat = min(wb_put('model/gmm/ycth_m',label,options),istat)
   label = gmmk_zcth_s
   istat = min(wb_put('model/gmm/zcth_m',label,options),istat)

   label = gmmk_xct1_s
   istat = min(wb_put('model/gmm/xct1_m',label,options),istat)
   label = gmmk_yct1_s
   istat = min(wb_put('model/gmm/yct1_m',label,options),istat)
   label = gmmk_zct1_s
   istat = min(wb_put('model/gmm/zct1_m',label,options),istat)

   call handle_error_l(WB_IS_OK(istat),'itf_adx_set','problem putting values in whiteboard')

   call adx_set    ()

   call msg(MSG_DEBUG,'itf_adx_set [end]')
   !---------------------------------------------------------------------
   return
end subroutine itf_adx_set

