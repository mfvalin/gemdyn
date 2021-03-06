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

!**s/r hzd_theta - applies horizontal diffusion on theta
!
      subroutine hzd_theta
      use hzd_ctrl
      implicit none
#include <arch_specific.hf>

#include "gmm.hf"
#include "glb_ld.cdk"
#include "lun.cdk"
#include "hzd.cdk"
#include "vt1.cdk"
#include "dcst.cdk"
#include "pw.cdk"

      integer istat,k
      real, parameter :: p_naught=100000., eps=1.0e-5
      real :: pres_t(l_ni,l_nj,G_nk),th(l_minx:l_maxx,l_miny:l_maxy,G_nk)
!
!-------------------------------------------------------------------
!
      if ( (Hzd_type_S.eq.'HO_IMP') .and. &
          ((Hzd_pwr_theta.ne.Hzd_pwr).or. &
          (abs((Hzd_lnr_theta-Hzd_lnr)/Hzd_lnr).gt.eps)) ) then
         if (Lun_out.gt.0) write (Lun_out,1001)
         return
      endif

      istat = gmm_get(gmmk_tt1_s       ,        tt1)
      istat = gmm_get(gmmk_pw_pt_plus_s, pw_pt_plus)

!$omp parallel private(k) shared (pres_t,th)
!$omp do
      do k=1,G_nk
         pres_t(1:l_ni,1:l_nj,k) = p_naught/pw_pt_plus(1:l_ni,1:l_nj,k)
         call vspown1 (pres_t(1,1,k),pres_t(1,1,k), &
                       real(Dcst_cappa_8),l_ni*l_nj)
         th(1:l_ni,1:l_nj,k) = tt1   (1:l_ni,1:l_nj,k) * &
                               pres_t(1:l_ni,1:l_nj,k)
!NOTE, zeroing in halo regions in order to avoid float error when dble(X)
!  under yyg_xchng: IF EVER we remove dble in yyg_xchng, we do not need this.
         th(l_minx:0     ,:     ,k) = 273.
         th(l_ni+1:l_maxx,:     ,k) = 273.
         th(1:l_ni,l_miny:0     ,k) = 273.
         th(1:l_ni,l_nj+1:l_maxy,k) = 273.
      end do
!$omp enddo
!$omp end parallel

      if (Hzd_type_S.eq.'HO_IMP') then
         if ((.not. G_lam).and.(Hzd_theta_njpole_gu_only.ge.1)) then
            call hzd_theta_gu_pole (th,l_minx,l_maxx,l_miny,l_maxy,G_nk)
         else
            call hzd_ctrl4 ( th, 'S', l_minx,l_maxx,l_miny,l_maxy,G_nk )
         endif
      else
         call hzd_ctrl4 ( th, 'S_THETA', l_minx,l_maxx,l_miny,l_maxy,&
                          G_nk )
      endif

!$omp parallel shared (pres_t,th)
!$omp do
      do k=1,G_nk
         tt1(1:l_ni,1:l_nj,k) = th    (1:l_ni,1:l_nj,k) / &
                                pres_t(1:l_ni,1:l_nj,k)
      enddo
!$omp enddo
!$omp end parallel

 1001 format(/,'Horizontal Diffusion of THETA with HO_IMP only available if (Hzd_pwr_theta=Hzd_pwr).and.(Hzd_lnr_theta=Hzd_lnr)')
!
!-------------------------------------------------------------------
!
      return
      end
