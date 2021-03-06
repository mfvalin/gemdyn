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

!**s/r hzd_bfct_1d - Same as hzd_bfct for 1d diffusion
!                    (based on HZD_BFCT, A.Qaddouri)
!

!
      subroutine hzd_bfct_1d (F_a_8,F_b_8,F_c_8,F_deltainv_8,F_pwr,gni,nx3)
!
      implicit none
#include <arch_specific.hf>
!
      integer F_pwr,gni,nx3
      real*8    F_a_8(1:F_pwr,1:F_pwr,1:gni,nx3), &
                F_c_8(1:F_pwr,1:F_pwr,1:gni,nx3), &
                F_b_8(1:F_pwr,1:F_pwr,1:gni,nx3), &
         F_deltainv_8(1:F_pwr,1:F_pwr,1:gni,nx3)
!
!Author
!     M.Tanguay
!
!revision
! v3_20 - Tanguay M.       - initial version
!
!object
!     see id section
!
!arguments
!
!  Name        I/O        Description
!----------------------------------------------------------------
!  F_deltainv_8    0      diagonal(block) part of LU     
!----------------------------------------------------------------
!
#include "glb_ld.cdk"
#include "glb_pil.cdk"
!*
      integer i,j,o1,o2,l_pil_w,l_pil_e
      real*8 wrk_8  (1:F_pwr,1:F_pwr)
      real*8 delta_8(1:F_pwr,1:F_pwr,1:gni,nx3)
!
!     __________________________________________________________________
!
!  The I vector lies on the Y processor so, l_pil_w and l_pil_e will
!  represent the pilot region along I
!
      l_pil_w=0
      l_pil_e=0
      if (l_south) l_pil_w= Lam_pil_w
      if (l_north) l_pil_e= Lam_pil_e
!
! factorization
!
      j = 1+Lam_pil_s
      do i = 1,gni
         do o1 = 1,F_pwr
         do o2 = 1,F_pwr
              delta_8(o1,o2,i,j)=F_b_8(o1,o2,i,j)
            enddo
         enddo
         call inverse(F_deltainv_8(1,1,i,j),delta_8(1,1,i,j),F_pwr,1)
      enddo
!
      do j = 2+Lam_pil_s ,nx3-Lam_pil_n
          do i = 1,gni
             call mxma8( F_deltainv_8(1,1,i,j-1), 1,F_pwr, &
                                F_C_8(1,1,i,j-1), 1,F_pwr, &
                         wrk_8, 1,F_pwr,F_pwr,F_pwr,F_pwr)
             call mxma8( F_a_8(1,1,i,j), 1,F_pwr, &
                         wrk_8         , 1,F_pwr, &
                         delta_8(1,1,i,j), 1,F_pwr,F_pwr,F_pwr,F_pwr)
             do o1= 1,F_pwr
             do o2=1,F_pwr
                delta_8(o1,o2,i,j)=F_b_8(o1,o2,i,j)-delta_8(o1,o2,i,j)
             enddo
             enddo
             call inverse (F_deltainv_8(1,1,i,j),delta_8(1,1,i,j), &
                                                         F_pwr,1)
          enddo
      enddo
!
!     __________________________________________________________________
!
      return
      end
