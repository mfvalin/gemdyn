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

!**s/r psadj - Adjust surface pressure for conservation
!
      subroutine psadj (F_kount)
      implicit none
#include <arch_specific.hf>

      integer, intent(in) :: F_kount

!author
!     Andre Plante from hzd_main      
!
!revision
! v4_05 - Lepine M.         - VMM replacement with GMM
! v4_50 - Qaddouri-PLante   - YY version
! v4_70 - Tanguay M.        - dry air pressure conservation
! v4_80 - Tanguay M.        - REAL*8 with iterations and psadj LAM 
!	
#include "gmm.hf"
#include "glb_ld.cdk"
#include "cstv.cdk"
#include "geomg.cdk"
#include "schm.cdk"
#include "vt0.cdk"
#include "vt1.cdk"
#include "ptopo.cdk"
#include "grd.cdk"
#include "lun.cdk"
#include "tr3d.cdk"
#include "dcst.cdk"
#include "psadj.cdk"
#include "rstr.cdk"
#include "iau.cdk"

      type(gmm_metadata) :: mymeta
      integer err,i,j,n,istat,iteration,MAX_iteration
      real*8,dimension(l_minx:l_maxx,l_miny:l_maxy,1:l_nk):: pr_m_8,pr_t_8
      real*8,dimension(l_minx:l_maxx,l_miny:l_maxy)       :: pr_p0_0_8,pr_p0_w_0_8 
      real*8 l_avg_8,g_avg_ps_0_8
      character(len= 9) communicate_S
!
!     ---------------------------------------------------------------
!
      if ( Schm_psadj == 0 ) then
         if ( Schm_psadj_print_L ) goto 999
         return
      endif

      if ( Schm_psadj <= 2 ) then
         if ( Cstv_dt_8*F_kount <= Iau_period ) goto 999
      endif

      if (G_lam.and..not.Grd_yinyang_L) then
         if (Rstri_rstn_L) call gem_error(-1,'psadj','PSADJ NOT AVAILABLE FOR LAMs in RESTART mode')
         if (.not. Schm_adxlegacy_L) then
            call adv_psadj_LAM_0
         else
            call adx_psadj_LAM_0
         endif
         return
      endif

! for GU and GY

      communicate_S = "GRID"
      if (Grd_yinyang_L) communicate_S = "MULTIGRID"

      istat = gmm_get(gmmk_st0_s,st0,mymeta)

      MAX_iteration = 3
      if (Schm_psadj==1) MAX_iteration = 1 

      do n= 1,MAX_iteration 

         !Obtain pressure levels
         !----------------------
         call calc_pressure_8 (pr_m_8,pr_t_8,pr_p0_0_8,st0,l_minx,l_maxx,l_miny,l_maxy,l_nk)

         !Compute dry surface pressure (- Cstv_pref_8)
         !--------------------------------------------
         if (Schm_psadj>=2) then

            call dry_sfc_pressure_8 (pr_p0_w_0_8,pr_m_8,pr_p0_0_8,l_minx,l_maxx,l_miny,l_maxy,l_nk,'M')

         !Compute wet surface pressure (- Cstv_pref_8)
         !--------------------------------------------
         elseif (Schm_psadj==1) then

            pr_p0_w_0_8(1:l_ni,1:l_nj) = pr_p0_0_8(1:l_ni,1:l_nj) - Cstv_pref_8 

         endif

         l_avg_8 = 0.0d0
         do j=1+pil_s,l_nj-pil_n
         do i=1+pil_w,l_ni-pil_e
            l_avg_8 = l_avg_8 + pr_p0_w_0_8(i,j) * Geomg_area_8(i,j) * Geomg_mask_8(i,j)
         enddo
         enddo

         call RPN_COMM_allreduce (l_avg_8,g_avg_ps_0_8,1,"MPI_DOUBLE_PRECISION","MPI_SUM",communicate_S,err)

         g_avg_ps_0_8 = g_avg_ps_0_8 * PSADJ_scale_8

         !Correct surface pressure in order to preserve air mass    
         !------------------------------------------------------
         do j=1+pil_s,l_nj-pil_n
         do i=1+pil_w,l_ni-pil_e
            pr_p0_0_8(i,j) = pr_p0_0_8(i,j) + (PSADJ_g_avg_ps_initial_8 - g_avg_ps_0_8)
            st0      (i,j) = log(pr_p0_0_8(i,j)/Cstv_pref_8)
         end do
         end do

      end do

  999 continue

      if ( Schm_psadj_print_L ) call stat_psadj (0,"AFTER DYNSTEP")
 
!     ---------------------------------------------------------------
!
      return
      end
