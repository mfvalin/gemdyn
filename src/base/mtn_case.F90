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

!**s/r mtn_case - generates initial condition for mountain wave
!                 experiment (Schar et al. 2002 or Pinty et al. 1995)
!
      subroutine mtn_case2(F_u, F_v, F_w, F_t, F_zd, F_s, F_topo, &
                           F_q, pref_tr, suff_tr, Mminx,Mmaxx,Mminy,Mmaxy)
      implicit none
#include <arch_specific.hf>

      character* (*) pref_tr,suff_tr
      integer Mminx,Mmaxx,Mminy,Mmaxy
      real F_u    (Mminx:Mmaxx,Mminy:Mmaxy,*), F_v(Mminx:Mmaxx,Mminy:Mmaxy,*), &
           F_w    (Mminx:Mmaxx,Mminy:Mmaxy,*), F_t(Mminx:Mmaxx,Mminy:Mmaxy,*), &
           F_zd   (Mminx:Mmaxx,Mminy:Mmaxy,*), F_s(Mminx:Mmaxx,Mminy:Mmaxy  ), &
           F_topo (Mminx:Mmaxx,Mminy:Mmaxy)  , F_q(Mminx:Mmaxx,Mminy:Mmaxy,*)

!author 
!     Sylvie Gravel  - rpn - Aug 2003
!
!revision
! v3_20 - Gravel S.        - initial version 
! v3_20 - Plante A.        - Modifs ...

#include "gmm.hf"
#include "glb_pil.cdk"
#include "glb_ld.cdk"
#include "dcst.cdk"
#include "lun.cdk"
#include "ptopo.cdk"
#include "cstv.cdk" 
#include "geomg.cdk"
#include "grd.cdk"
#include "out3.cdk"
#include "tr3d.cdk"
#include "vt1.cdk"
#include "theo.cdk"
#include "vtopo.cdk"
#include "mtn.cdk"
#include "zblen.cdk"
#include "type.cdk"
#include "ver.cdk"
#include "schm.cdk"
#include "p_geof.cdk"

      type(gmm_metadata) :: mymeta
      character(len=GMM_MAXNAMELENGTH) :: tr_name
      integer i,j,k,l,i00,err,istat
      real a00, a01, a02, xcntr, zdi, zfac, zfac1, capc1
      real, allocatable, dimension(:,:) :: psurf
      real hauteur, tempo, dx, slp, slpmax
      real*8 temp1, temp2
      real, pointer    , dimension(:,:,:) :: tr
!
!     ---------------------------------------------------------------
!
      allocate(psurf (l_minx:l_maxx,l_miny:l_maxy))

!---------------------------------------------------------------------
!     Initialize orography
!---------------------------------------------------------------------

      xcntr = int(float(Grd_ni-1)*0.5)+1
      do j=1,l_nj
      do i=1,l_ni
         i00 = i + l_i0 - 1
         zdi  = float(i00)-xcntr
         zfac = (zdi/mtn_hwx)**2
         if ( Theo_case_S .eq. 'MTN_SCHAR' &
             .or.  Theo_case_S .eq. 'MTN_SCHAR2' ) then
            zfac1= Dcst_pi_8 * zdi / mtn_hwx1
            F_topo(i,j) = mtn_hght* exp(-zfac) * cos(zfac1)**2
         else
            F_topo(i,j) = mtn_hght/(zfac + 1.)
         endif
      enddo
      enddo

!---------------------------------------------------------------------
!     If time-dependant topography
!---------------------------------------------------------------------
      if(Vtopo_L) then
         istat = gmm_get(gmmk_topo_low_s , topo_low , mymeta)
         istat = gmm_get(gmmk_topo_high_s, topo_high, mymeta)
         topo_low (1:l_ni,1:l_nj) = 0.
         topo_high(1:l_ni,1:l_nj) = F_topo(1:l_ni,1:l_nj) * Dcst_grav_8
         F_topo   (1:l_ni,1:l_nj) = 0.
       endif

      if (      Theo_case_S .eq. 'MTN_SCHAR'  &
           .or. Theo_case_S .eq. 'MTN_SCHAR2' &
           .or. Theo_case_S .eq. 'MTN_PINTYNL') then

!---------------------------------------------------------------------
!     Generate surface pressure field and its logarithm (s)
!     Set wind imags (u,v)
!     Transform orography from geometric to geopotential height
!     Set non-hydrostatic perturbation pressure (q)
!---------------------------------------------------------------------
!
      a00 = mtn_nstar**2/Dcst_grav_8
      a01 = (Dcst_cpd_8*mtn_tzero*a00)/Dcst_grav_8
      capc1 = Dcst_grav_8**2/(mtn_nstar**2*Dcst_cpd_8*mtn_tzero)
!
      do j=1,l_nj
      do i=1,l_ni
         psurf(i,j)=Cstv_pref_8*(1.-capc1 &
               +capc1*exp(-a00*F_topo(i,j)))**(1./Dcst_cappa_8)
         F_s   (i,j)   = log(psurf(i,j)/Cstv_pref_8)
         F_u   (i,j,1) = mtn_flo
      enddo
      enddo
!
      do k=1,g_nk
      do j=1,l_nj
      do i=1,l_ni
         F_u (i,j,k) = F_u (i,j,1)
         F_v (i,j,k) = 0.0
      enddo
      enddo
      enddo
!
!---------------------------------------------------------------------
!     Initialize temperature and vertical motion fields
!---------------------------------------------------------------------
!
       do k=1,g_nk
         do j=1,l_nj
            do i=1,l_ni
               tempo = exp(Ver_a_8%m(k)+Ver_b_8%m(k)*F_s(i,j))
               a02 = (tempo/Cstv_pref_8)**Dcst_cappa_8
               hauteur=-log((capc1-1.+a02)/capc1)/a00
               temp1=mtn_tzero*((1.-capc1)*exp(a00*hauteur)+capc1)
               tempo = exp(Ver_a_8%m(k+1)+Ver_b_8%m(k+1)*F_s(i,j))
               a02 = (tempo/Cstv_pref_8)**Dcst_cappa_8
               hauteur=-log((capc1-1.+a02)/capc1)/a00
               temp2=mtn_tzero*((1.-capc1)*exp(a00*hauteur)+capc1)
               F_t(i,j,k)=Ver_wp_8%t(k)*temp2+Ver_wm_8%t(k)*temp1
            enddo
         enddo
      enddo        
!
      else   ! MTN_PINTY or MTN_PINTY2 or NOFLOW
!-----------------------------------------------------------------------
!     Generate pressure from Cstv_ptop_8, Cstv_pref_8, and coordinate
!     Generate corresponding geopotential for isothermal atmosphere
!     Set wind and temperature
!-----------------------------------------------------------------------

      do k=1,g_nk
      do j=1,l_nj
      do i=1,l_ni
         F_t (i,j,k) = mtn_tzero
      enddo
      enddo
      enddo

      do k=1,g_nk
      do j=1,l_nj
      do i=1,l_ni
         F_u (i,j,k) = mtn_flo
         F_v (i,j,k) = 0.
      enddo
      enddo
      enddo

      do j=1,l_nj
      do i=1,l_ni
         psurf(i,j) = Cstv_pref_8 *  &
                      exp( -Dcst_grav_8 * F_topo(i,j)/ &
                           (Dcst_Rgasd_8 * mtn_tzero ) )	
         F_s(i,j) = log(psurf(i,j)/Cstv_pref_8)
      enddo
      enddo         

!     calculate maximum mountain slope

      slpmax=0
      dx=Dcst_rayt_8*Grd_dx*Dcst_pi_8/180.
      do j=1,l_nj
      do i=1,l_ni
      slp=abs(F_topo(i,j)-F_topo(i-1,j))/dx
      slpmax=max(slp,slpmax)
      enddo
      enddo
      slpmax=(180.d0/Dcst_pi_8)*atan(slpmax)

      print*,"SLPMAX=",slpmax," DEGREES"

      endif
!
!-----------------------------------------------------------------------
!     Transform orography from geometric to geopotential height
!-----------------------------------------------------------------------
      do j=1,l_nj
      do i=1,l_ni
         F_topo(i,j) = Dcst_grav_8 * F_topo(i,j)
      end do
      end do
!
      call rpn_comm_xch_halo ( F_topo, l_minx,l_maxx,l_miny,l_maxy,l_ni,l_nj,1, &
                    G_halox,G_haloy,G_periodx,G_periody,l_ni,0 )

!-----------------------------------------------------------------------
!     create tracers (humidity and MTN)
!-----------------------------------------------------------------------
      do k=1,Tr3d_ntr
         if (Tr3d_name_S(k)(1:2).eq.'HU') then
            nullify(tr)
            tr_name = trim(pref_tr)//trim(Tr3d_name_S(k))//trim(suff_tr)
            istat = gmm_get(tr_name,tr,mymeta)
            tr = 0.
         endif
      end do
!
 9000 format(/,'CREATING INPUT DATA FOR MOUNTAIN WAVE THEORETICAL CASE' &
            /,'======================================================')
!
!     -----------------------------------------------------------------
!
      return
      end
