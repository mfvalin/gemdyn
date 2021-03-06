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

!** s/r ens_uvduv - Computes sqrt((u*du)**2 +(v*dv)**2) of wind-like fields 
!
      subroutine ens_uvduv ( F_duv, F_uu, F_vv, Minx,Maxx,Miny,Maxy, Nk )
!
      implicit none
#include <arch_specific.hf>
!
      integer  Minx,Maxx,Miny,Maxy, Nk
      real     F_duv(Minx:Maxx,Miny:Maxy,Nk), F_uu  (Minx:Maxx,Miny:Maxy,Nk), &
               F_vv (Minx:Maxx,Miny:Maxy,Nk)
!
!authors
!      Lubos Spacek - apr 2005
!
!revision
! 001 pacek L.   - correct the factor in F_duv (now 1/2)
!
!
!object
!     see id section 
!
!arguments
!  Name        I/O                 Description
!----------------------------------------------------------------
! F_duv         O        the resulted (u*du +v*dv)
! F_uu          I        wind-like field on U-grid
! F_vv          I        wind-like field on V-grid
!----------------------------------------------------------------
!

#include "glb_ld.cdk"
#include "geomg.cdk"
#include "dcst.cdk"
      integer i, j, k, i0, in, j0, jn
!*
!     __________________________________________________________________
!
      i0 = 0
      in = l_ni
      j0 = 0
      jn = l_nj
!      i0 = 1
!      in = l_niu
!      j0 = 1
!      jn = l_njv
!      if ((G_lam).and.(l_west)) i0 = 2
!      if (l_south) j0 = 2
!
      do k=1,Nk
         do j = j0, jn
         do i = i0, in
!
! avant on a filtre le champ radical D chapeau
!
!            F_duv(i,j,k) = sqrt(sqrt(( F_uu(i,j,k)*coni +
!     $                                 F_uu(i,j-1,k)*coni1 )**2 
!     $                 + (conj*(F_vv(i,j-1,k)+F_vv(i-1,j-1,k)))**2))
!
! maintenant on filtre le champ D chapeau
!
            F_duv(i,j,k) = 0.5*sqrt(( F_uu(i,j,k) + &
                                       F_uu(i,j-1,k) )**2  &
                       + (F_vv(i,j-1,k)+F_vv(i-1,j-1,k))**2)
         end do
         end do
!
!         if (.not.G_lam) then
!            if (l_south) then
!            do i = i0, in
!               F_duv(i,1,k) = 0.0
!            end do
!            endif
!            if (l_north) then
!            do i = i0, in
!               F_duv(i,l_nj,k) = 0.0
!            end do
!            endif
!         endif
      end do
!
      return
      end
