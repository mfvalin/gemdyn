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

!**s/p calomeg_w - compute vertical velocity in pressure coordinates
!                    from advection
!


!
      subroutine calomeg_w (F_ww,F_st1,F_wt1,F_tt1,Minx,Maxx,Miny,Maxy,Nk)
!
      implicit none
#include <arch_specific.hf>
!
      integer Minx,Maxx,Miny,Maxy, Nk
      real F_ww(Minx:Maxx,Miny:Maxy,Nk),F_st1(Minx:Maxx,Miny:Maxy)
      real F_wt1(Minx:Maxx,Miny:Maxy,Nk),F_tt1(Minx:Maxx,Miny:Maxy,Nk)
!
!author
!     Claude Girard et Andre Plante avril 2008.
!
!revision
! v4.0.4 Andre Plante Nov. 1008 ajout de vsexp.
!
!object
!	compute vertical velocity in hydrostatic pressure coordinates
!
!        omega = dpi/dt ~ -g*rau*dz/dt = -g*rau*w
!                   
!        where : pi  is the hydrostatic pressure
!                rau the density
!                w   real vertical wind
!
!arguments
!  Name        I/O                 Description
!----------------------------------------------------------------
! F_ww           O                 dpi/dt (Pa/s)
! F_st1        I                   s at time t1 = exp(PIt1/Zsruf)
! F_wt1        I                   real vertical wind
! F_tt1        I                   virtual temperature
!

#include "glb_ld.cdk"
#include "dcst.cdk"
#include "cstv.cdk"
#include "lctl.cdk"
#include "type.cdk"
#include "ver.cdk"

      integer i,j,k
      real, dimension(l_ni,l_nj) :: t1,t2
!     __________________________________________________________________
!

!$omp parallel private(t1,t2)
!$omp do
      do k=1,l_nk
         do j=1,l_nj
            do i=1,l_ni
               t1(i,j)= Ver_a_8%t(k) + Ver_b_8%t(k)*F_st1(i,j)
            end do
         end do
         call vsexp(t2,t1,l_ni*l_nj)
         do j=1,l_nj
            do i=1,l_ni
               F_ww (i,j,k) = -Dcst_grav_8 *F_wt1(i,j,k)*t2(i,j)/ &
                              (Dcst_rgasd_8*F_tt1(i,j,k))
            end do
         end do
      end do
!$omp enddo
!$omp end parallel
!     __________________________________________________________________
!
      return
      end
