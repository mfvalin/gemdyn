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

!**s/r pospers - initialise upstream positions at time th as grid point positions
!

!
      subroutine pospers
!
      implicit none
#include <arch_specific.hf>
!
!author
!     Alain Patoine
!
!revision
! v2_00 - Desgagne M.       - initial MPI version
! V4_10 - Plante A.         - Thermo upstream positions
!
!object
!	
!arguments
!     none
!

#include "gmm.hf"
#include "glb_ld.cdk"
#include "geomg.cdk"
#include "vth.cdk"
#include "vt1.cdk"
#include "type.cdk"
#include "ver.cdk"
!
      type(gmm_metadata) :: mymeta
      integer i, j, k, ijk, nij,istat
      real pr1
!*
!
!     ---------------------------------------------------------------
!
      nij = l_ni * l_nj
!
      istat = gmm_get(gmmk_xth_s,xth,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(xth)'
      istat = gmm_get(gmmk_yth_s,yth,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(yth)'
      istat = gmm_get(gmmk_zth_s,zth,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(zth)'
!
      istat = gmm_get(gmmk_xcth_s,xcth,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(xcth)'
      istat = gmm_get(gmmk_ycth_s,ycth,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(ycth)'
      istat = gmm_get(gmmk_zcth_s,zcth,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(zcth)'
!
      istat = gmm_get(gmmk_xct1_s,xct1,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(xct1)'
      istat = gmm_get(gmmk_yct1_s,yct1,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(yct1)'
      istat = gmm_get(gmmk_zct1_s,zct1,mymeta)
      if (GMM_IS_ERROR(istat)) print *,'pospers ERROR at gmm_get(zct1)'
!
      do k = 1, l_nk
      do j = 1, l_nj 
      do i = 1, l_ni
         ijk=(k-1)*nij+(j-1)*l_ni+i
         xth(ijk)  = Geomg_x_8(i)
         yth(ijk)  = Geomg_y_8(j)
         zth(ijk)  = Ver_z_8%m(k)
!
         pr1         = cos(yth(ijk))
!
         zcth(ijk) = sin(yth(ijk))
         xcth(ijk) = cos(xth(ijk)) * pr1
         ycth(ijk) = sin(xth(ijk)) * pr1

         zct1(ijk) = sin(yth(ijk))
         xct1(ijk) = cos(xth(ijk)) * pr1
         yct1(ijk) = sin(xth(ijk)) * pr1
      enddo
      enddo
      enddo
!
!     ---------------------------------------------------------------
!
      return
      end
