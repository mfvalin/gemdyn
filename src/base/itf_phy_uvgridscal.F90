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

!**s/r itf_phy_uvgridscal - Interpolation of wind fields to the physic s grid.
!

!
      subroutine itf_phy_uvgridscal (F_put,F_pvt,Minx,Maxx,Miny,Maxy,nkphy,vers)
!
      implicit none
#include <arch_specific.hf>
!
      integer,intent(IN) :: Minx,Maxx,Miny,Maxy,nkphy
      real, dimension(Minx:Maxx,Miny:Maxy,nkphy),intent(INOUT) :: F_put, F_pvt 
      logical,intent(IN) :: vers
!
!author
!     Stephane Laroche        Janvier 2001
!
!revision
! v2_31 - Laroche S.       - initial MPI version
! v3_00 - Desgagne & Lee   - Lam configuration
! v3_21 - Desgagne M.      - Revision Openmp
! v3_30 - Desgagne M.      - new interface itf_phy (p_uvgridscal)
! v3_30 - Tanguay M.       - Revision Openmp LAM 
!
!object
!	Cubic interpolation of the dynamics fields from their own grid
!	to the grid where the physics tendencies are computed
!	
!arguments
!  Name        I/O                 Description
!----------------------------------------------------------------
! F_put       
! F_pvt
! vers          I          .true.  wind grid ---> scalar grid    
!                          .false. wind grid <--- scalar grid 
!----------------------------------------------------------------
!    

#include "glb_ld.cdk"
#include "schm.cdk"
#include "inuvl.cdk"
!
!*
      integer i,j,k,i0u,j0u,inu,jnu,i0v,j0v,inv,jnv
      integer nsu,ndu,nsv,ndv
      real, dimension(l_minx:l_maxx,l_miny:l_maxy,nkphy) :: wk_u, wk_v
!
!     ---------------------------------------------------------------
!
      if(vers) then
       nsu = 1
       ndu = 0
       nsv = 2
       ndv = 0
      else
       nsu = 0
       ndu = 1
       nsv = 0
       ndv = 2
      endif
!
!     x component
!
      call uv_acg2g (wk_u,F_put,nsu,ndu,l_minx,l_maxx,l_miny,l_maxy,nkphy,i0u,inu,j0u,jnu)
!
!     y component
!
      call uv_acg2g (wk_v,F_pvt,nsv,ndv,l_minx,l_maxx,l_miny,l_maxy,nkphy,i0v,inv,j0v,jnv)
!
!$omp parallel private(i,j)
!$omp do
      do k=1,nkphy
         do j= j0u, jnu
         do i= i0u, inu
            F_put(i,j,k) = wk_u(i,j,k)
         end do
         end do
         do j= j0v, jnv
         do i= i0v, inv
            F_pvt(i,j,k) = wk_v(i,j,k)
         end do
         end do
      end do
!$omp end do
!$omp end parallel
!
!     ---------------------------------------------------------------
!
      return
      end
