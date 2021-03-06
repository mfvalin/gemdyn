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

!** s/r glhalo_init - 
!

!
      subroutine glhalo_init()
!
      implicit none
#include <arch_specific.hf>
!
!author
!      Claude Girard
!
!revision
!
!object
!
!arguments
!  Name        I/O                 Description
!----------------------------------------------------------------
! F_v0         I/O       
! F_v1         I/O       
!----------------------------------------------------------------
!

#include "gmm.hf"
#include "glb_ld.cdk"
#include "geomg.cdk"
#include "vt0.cdk"
#include "vt1.cdk"
#include "orh.cdk"
#include "rhsc.cdk"
#include "p_geof.cdk"
!
      type(gmm_metadata) :: mymeta
      integer i,k,istat
!*
!     __________________________________________________________________
!
      istat = gmm_get(gmmk_ut1_s,ut1,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'glhalo_init ERROR at gmm_get(ut1)'
      istat = gmm_get(gmmk_ut0_s,ut0,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'glhalo_init ERROR at gmm_get(ut0)'
      istat = gmm_get(gmmk_vt1_s,vt1,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'glhalo_init ERROR at gmm_get(vt1)'
      istat = gmm_get(gmmk_vt0_s,vt0,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'glhalo_init ERROR at gmm_get(vt0)'
      istat = gmm_get(gmmk_orhsv_s,orhsv,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'glhalo_init ERROR at gmm_get(orhsv)'
      istat = gmm_get(gmmk_rvw2_s,rvw2,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'glhalo_init ERROR at gmm_get(rvw2)'
      istat = gmm_get(gmmk_rhsv_s,rhsv,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'glhalo_init ERROR at gmm_get(rhsv)'
      istat = gmm_get(gmmk_fis0_s,fis0,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'glhalo_init ERROR at gmm_get(fis0)'

      if(l_south) then
         do i = l_minx, l_maxx
            fis0(i,0) = 0.0
         end do
      endif
      if(l_north) then
         do i = l_minx, l_maxx
            fis0(i,l_nj+1) = 0.0
         end do
      endif
      do k=1,G_nk
         if(l_south) then
            do i = l_minx, l_maxx
               ut0(i, 0,k) = 0.0
               ut1(i, 0,k) = 0.0
               vt0(i, 0,k) = 0.0
               vt1(i, 0,k) = 0.0
               vt0(i,-1,k) = 0.0
               vt1(i,-1,k) = 0.0
                rhsv(i, 0,k) = 0.0
               orhsv(i, 0,k) = 0.0
               orhsv(i,-1,k) = 0.0
               rvw2 (i, 0,k) = 0.0
            end do
         endif
         if(l_north) then
            do i = l_minx, l_maxx
               ut0(i,l_njv+2,k) = 0.0
               ut1(i,l_njv+2,k) = 0.0
               vt0(i,l_njv+2,k) = 0.0
               vt1(i,l_njv+2,k) = 0.0
               vt0(i,l_njv+1,k) = 0.0
               vt1(i,l_njv+1,k) = 0.0
                rhsv(i,l_njv+1,k) = 0.0
               orhsv(i,l_njv+1,k) = 0.0
               orhsv(i,l_njv+2,k) = 0.0
               rvw2 (i,l_njv+2,k) = 0.0
            end do
         endif
      enddo
!
      return
      end
