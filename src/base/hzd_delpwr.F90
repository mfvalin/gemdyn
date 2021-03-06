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

!**s/r hzd_delpwr - initialisation et factorisation LU 
!                   de l'operateur unidimensionnel.
!                   direction de travail: suivant la latitude.
!

!
      subroutine hzd_delpwr (F_a_8,F_c_8,F_deltai_8,F_pwr, &
                             minx2,maxx2,nx3,nx2,n20,F_opsyp0_8, &
                             F_opsyp2_8,F_opsypm_8,F_eival_8,F_cdiff)
!
      implicit none
#include <arch_specific.hf>
!
      integer n20,F_pwr,minx2,maxx2,nx3,nx2
      real F_cdiff
      real*8      F_a_8(1:F_pwr,1:F_pwr,minx2:maxx2,nx3), &
                  F_c_8(1:F_pwr,1:F_pwr,minx2:maxx2,nx3), &
             F_deltai_8(1:F_pwr,1:F_pwr,minx2:maxx2,nx3), &
           F_opsypm_8(*),F_opsyp0_8(*),F_opsyp2_8(*),F_eival_8(*)
!
!Author
!     Abdessamad Qaddouri
!
!revision
! v2_10 - Qaddouri A.       - initial version
! v2_31 - Desgagne M.       - remove stkmemw
! v3_00 - Desgagne & Lee    - Lam configuration
!
!object
!
!arguments
!  Name        I/O                 Description
!---------------------------------------------------------------------
!  a_8           I/0     Sub   (block) diagonal part of matrix and LU
!  c_8           I/0     super (block) part of matrix and LU
!  F_deltai_8_8   0      diagonal(block) part of LU
!---------------------------------------------------------------------
!
#include "glb_ld.cdk"
#include "glb_pil.cdk"
!*
      real*8   ZERO_8
      parameter( ZERO_8 = 0.0 )
!
      integer i, j, ii, o1, o2, l_pil_w,l_pil_e
      real*8 b_8(1:F_pwr,1:F_pwr,minx2:maxx2,nx3)
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
      do j=1,nx3
      do i=minx2, maxx2
      do o1=1,F_pwr
         do o2=1,F_pwr
            F_a_8(o1,o2,i,j)=ZERO_8
            b_8(o1,o2,i,j)  =ZERO_8
            F_c_8(o1,o2,i,j)=ZERO_8
         enddo
      enddo
      enddo
      enddo
!
! Calcul des matrices
!
      if(F_pwr.eq.1) then
!
         j=1+Lam_pil_s
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1           
            F_c_8(1,1,i,j)= F_opsyp2_8(2*nx3+j)
              b_8(1,1,i,j)= F_opsyp2_8(nx3+j)  &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j) &
                            - dble(F_cdiff)*F_opsyp0_8(nx3+j)
         enddo
!         
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            do j=2+Lam_pil_s, nx3-1-Lam_pil_n
               F_a_8(1,1,i,j)= F_opsyp2_8(2*nx3+j-1)
               F_c_8(1,1,i,j)= F_opsyp2_8(2*nx3+j)
                 b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j) &
                               - dble(F_cdiff)*F_opsyp0_8(nx3+j)
            enddo
         enddo
!
         j=nx3-Lam_pil_n
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1            
            F_a_8(1,1,i,j)= F_opsyp2_8(2*nx3+j-1)
              b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j) &
                            - dble(F_cdiff)*F_opsyp0_8(nx3+j)
         enddo
!         
      endif
!
      if (F_pwr.eq.2) then
!
         j=1+Lam_pil_s
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1            
            F_c_8(1,1,i,j)= F_opsyp2_8(2*nx3+j)
            F_c_8(2,2,i,j)= F_opsyp2_8(2*nx3+j)           
              b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(2,1,i,j)= - F_opsyp0_8(nx3+j) 
              b_8(1,2,i,j)= dble(F_cdiff)*F_opsyp0_8(nx3+j)
         enddo
!
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            do j=2+Lam_pil_s, nx3-1-Lam_pil_n
               F_a_8(1,1,i,j)= F_opsyp2_8(2*nx3+j-1)
               F_a_8(2,2,i,j)= F_opsyp2_8(2*nx3+j-1)               
               F_c_8(1,1,i,j)= F_opsyp2_8(2*nx3+j)
               F_c_8(2,2,i,j)= F_opsyp2_8(2*nx3+j)              
                 b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j)
                 b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j)
                 b_8(2,1,i,j)= - F_opsyp0_8(nx3+j)
                 b_8(1,2,i,j)= dble(F_cdiff)*F_opsyp0_8(nx3+j)
            enddo
         enddo
!
         j=nx3-Lam_pil_n
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            F_a_8(1,1,i,j)= F_opsyp2_8(2*nx3+j-1)
            F_a_8(2,2,i,j)= F_opsyp2_8(2*nx3+j-1)
            
              b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(2,1,i,j)= - F_opsyp0_8(nx3+j)
              b_8(1,2,i,j)= dble(F_cdiff)*F_opsyp0_8(nx3+j)
         enddo
!         
      endif
!
      if(F_pwr.eq.3) then
         j=1+Lam_pil_s
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            F_c_8(1,1,i,j)= F_opsyp2_8(2*nx3+j)
            F_c_8(2,2,i,j)= F_opsyp2_8(2*nx3+j)
            F_c_8(3,3,i,j)= F_opsyp2_8(2*nx3+j)
              b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(3,3,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(1,3,i,j)= -dble(F_cdiff)*F_opsyp0_8(nx3+j)
              b_8(2,1,i,j)= -F_opsyp0_8(nx3+j)
              b_8(3,2,i,j)= -F_opsyp0_8(nx3+j)
         enddo
!         
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            do j=2+Lam_pil_s, nx3-1-Lam_pil_n
               F_a_8(1,1,i,j)= F_opsyp2_8(2*nx3+j-1)
               F_a_8(2,2,i,j)= F_opsyp2_8(2*nx3+j-1)
               F_a_8(3,3,i,j)= F_opsyp2_8(2*nx3+j-1) 
               F_c_8(1,1,i,j)= F_opsyp2_8(2*nx3+j)
               F_c_8(2,2,i,j)= F_opsyp2_8(2*nx3+j)
               F_c_8(3,3,i,j)= F_opsyp2_8(2*nx3+j) 
                 b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j)
                 b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j)
                 b_8(3,3,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j)
                 b_8(1,3,i,j)= -dble(F_cdiff)*F_opsyp0_8(nx3+j)
                 b_8(2,1,i,j)= -F_opsyp0_8(nx3+j) 
                 b_8(3,2,i,j)= -F_opsyp0_8(nx3+j)
            enddo
         enddo
!         
         j=nx3-Lam_pil_n
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            F_a_8(1,1,i,j)= F_opsyp2_8(2*nx3+j-1)
            F_a_8(2,2,i,j)= F_opsyp2_8(2*nx3+j-1)
            F_a_8(3,3,i,j)= F_opsyp2_8(2*nx3+j-1) 
            
              b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(3,3,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(1,3,i,j)= -dble(F_cdiff)*F_opsyp0_8(nx3+j)
              b_8(2,1,i,j)= -F_opsyp0_8(nx3+j) 
              b_8(3,2,i,j)= -F_opsyp0_8(nx3+j)
         enddo
!         
      endif
!
      if(F_pwr.eq.4) then
!
         j=1+Lam_pil_s
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            F_c_8(1,1,i,j)= F_opsyp2_8(2*nx3+j)
            F_c_8(2,2,i,j)= F_opsyp2_8(2*nx3+j)
            F_c_8(3,3,i,j)= F_opsyp2_8(2*nx3+j) 
            F_c_8(4,4,i,j)= F_opsyp2_8(2*nx3+j)
              b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j) 
              b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(3,3,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(4,4,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(1,4,i,j)= dble(F_cdiff)*F_opsyp0_8(nx3+j)
              b_8(2,1,i,j)= - F_opsyp0_8(nx3+j)
              b_8(3,2,i,j)= - F_opsyp0_8(nx3+j)
              b_8(4,3,i,j)= - F_opsyp0_8(nx3+j)
         enddo
!         
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            do j=2+Lam_pil_s, nx3-1-Lam_pil_n
               F_a_8(1,1,i,j)= F_opsyp2_8(2*nx3+j-1)
               F_a_8(2,2,i,j)= F_opsyp2_8(2*nx3+j-1)
               F_a_8(3,3,i,j)= F_opsyp2_8(2*nx3+j-1) 
               F_a_8(4,4,i,j)= F_opsyp2_8(2*nx3+j-1) 
               F_c_8(1,1,i,j)= F_opsyp2_8(2*nx3+j)
               F_c_8(2,2,i,j)= F_opsyp2_8(2*nx3+j)
               F_c_8(3,3,i,j)= F_opsyp2_8(2*nx3+j) 
               F_c_8(4,4,i,j)= F_opsyp2_8(2*nx3+j) 
                 b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j) 
                 b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j)
                 b_8(3,3,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j)
                 b_8(4,4,i,j)= F_opsyp2_8(nx3+j) &
                               + F_eival_8(ii)*F_opsypm_8(nx3+j)
                 b_8(1,4,i,j)= dble(F_cdiff)*F_opsyp0_8(nx3+j)
                 b_8(2,1,i,j)= - F_opsyp0_8(nx3+j)
                 b_8(3,2,i,j)= - F_opsyp0_8(nx3+j)
                 b_8(4,3,i,j)= - F_opsyp0_8(nx3+j) 
            enddo
         enddo
!         
         j=nx3-Lam_pil_n
         do i = 1+l_pil_w, nx2-l_pil_e
            ii = i + n20 - 1
            F_a_8(1,1,i,j)= F_opsyp2_8(2*nx3+j-1)
            F_a_8(2,2,i,j)= F_opsyp2_8(2*nx3+j-1)
            F_a_8(3,3,i,j)= F_opsyp2_8(2*nx3+j-1)
            F_a_8(4,4,i,j)= F_opsyp2_8(2*nx3+j-1)
              b_8(1,1,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j) 
              b_8(2,2,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(3,3,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(4,4,i,j)= F_opsyp2_8(nx3+j) &
                            + F_eival_8(ii)*F_opsypm_8(nx3+j)
              b_8(1,4,i,j)= dble(F_cdiff)*F_opsyp0_8(nx3+j)
              b_8(2,1,i,j)= - F_opsyp0_8(nx3+j)
              b_8(3,2,i,j)= - F_opsyp0_8(nx3+j)
              b_8(4,3,i,j)= - F_opsyp0_8(nx3+j)
         enddo
!         
      endif
!
! Factorisation
!
      call hzd_bfct (F_a_8,b_8,F_c_8,F_deltai_8,F_pwr,minx2, &
                                             maxx2,nx3, nx2)
!
      do o1=1,F_pwr
      do o2=1,F_pwr
         do i= minx2,0+l_pil_w
         do j=1,nx3
            F_deltai_8(o1,o2,i,j)= ZERO_8
         enddo
         enddo
      enddo
      enddo 
!
      do o1=1,F_pwr
      do o2=1,F_pwr
         do i= nx2+1-l_pil_e,maxx2
         do j=1,nx3
            F_deltai_8(o1,o2,i,j)= ZERO_8
         enddo 
         enddo
      enddo
      enddo
!
!     __________________________________________________________________
!     
           return
           end

