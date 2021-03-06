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

!**s/r  sol_pre_multicol -  call multicolored block-gauss seidel  
!

!
      subroutine  sol_pre_multicol ( wk22, wk11,niloc,njloc, &
                             Minx, Maxx, Miny, Maxy,nil,njl, &
                              minx1, maxx1, minx2, maxx2,Nk )
      implicit none
#include <arch_specific.hf>
!
      integer niloc, njloc, Minx, Maxx, Miny, Maxy, &
              nil, njl, minx1, maxx1, minx2, maxx2, Nk
      real*8  wk11(*),wk22(*)
!
!author
!       Abdessamad Qaddouri - December  2006
!
!revision
! v3_30 - Qaddouri A.       - initial version
!
#include "schm.cdk"
#include "ptopo.cdk"
#include "sol.cdk"
#include "prec.cdk"
!
      integer  nloc,ii,icol
      real*8 wk12(niloc*njloc*Schm_nith), fdg(niloc,njloc,Schm_nith)
      real*8 fdg1(minx1:maxx1, minx2:maxx2,Schm_nith)
      real*8 wint_8 (Minx:Maxx,Miny:Maxy,Schm_nith)
      real*8 wint_81(Minx:Maxx,Miny:Maxy,Schm_nith)
!
!     ---------------------------------------------------------------
!
      nloc= niloc*njloc*Schm_nith
!
      do ii=1,nloc
         wk12(ii)=wk11(ii)
      enddo
!
      do ii=1,Ptopo_numproc-1
      do icol=1,Prec_ncol
         if (Prec_mycol.eq.icol) then
            call pre_jacobi2D(wk22,wk12,Prec_xevec_8,fdg,niloc,njloc, &
                             Schm_nith,Prec_ai_8,Prec_bi_8,Prec_ci_8)
            call tab_vec ( wint_8 , Minx,Maxx,Miny,Maxy,Schm_nith, &
                             wk22   , sol_i0,sol_in,sol_j0,sol_jn, -1 )
            call tab_vec ( wint_81, Minx,Maxx,Miny,Maxy,Schm_nith, &
                             wk11   , sol_i0,sol_in,sol_j0,sol_jn, -1 )
            call bord_cor( wint_81, wint_8,Minx, Maxx, Miny, Maxy,nil, &
                        njl,minx1, maxx1, minx2, maxx2,Schm_nith,fdg1 )
            call tab_vec ( wint_81, Minx,Maxx,Miny,Maxy,Schm_nith, &
                             wk12   , sol_i0,sol_in,sol_j0,sol_jn, +1 )
         endif
      enddo
      enddo
!
!     ---------------------------------------------------------------
!
      return
      end
!
!**s/r  bord_cor -  rhs correction in preconditionner 
!                 
      subroutine  bord_cor (Rhs, Sol, Minx, Maxx, Miny, Maxy, nil, njl, &
                                    minx1, maxx1, minx2, maxx2,Nk,fdg1)
      implicit none
#include <arch_specific.hf>
!
      integer Minx, Maxx, Miny, Maxy, nil, njl, &
              minx1, maxx1, minx2, maxx2, Nk
      real*8 Sol (Minx:Maxx,Miny:Maxy,Nk), Rhs (Minx:Maxx,Miny:Maxy,Nk), &
             fdg1(minx1:maxx1, minx2:maxx2, Nk)
!
!author
!       Abdessamad Qaddouri - December  2006
!
!revision
! v3_30 - Qaddouri A.       - initial version
!
#include "glb_ld.cdk"
#include "opr.cdk"
#include "sol.cdk"

!
      integer i,j,k,ii,jj, halox,haloy
      real*8 stencil1,stencil2,stencil3,stencil4,stencil5,di_8
!
!     ---------------------------------------------------------------
!
      do k = 1, nk
         fdg1(:,:,k) = 0.
         do j=1+sol_pil_s, njl-sol_pil_n
            do i=1+sol_pil_w, nil-sol_pil_e
               fdg1(i,j,k)=Sol(i,j,k)
            enddo
         enddo
      enddo
!
      halox=1
      haloy=halox
!$omp single
       call rpn_comm_xch_halon (fdg1,minx1,maxx1,minx2,maxx2,nil,njl, &
                          Nk,halox,haloy,G_periodx,G_periody,nil,0,2)
!$omp end single
!
       do k = 1,Nk
!
          i=1+sol_pil_w
          ii=i+l_i0-1
          do j=1+sol_pil_s, njl-sol_pil_n
             jj=j+l_j0-1
             di_8= Opr_opsyp0_8(G_nj+jj) / cos( G_yg_8 (jj) )**2
             stencil2= Opr_opsxp2_8(ii)*di_8
             Rhs(i,j,k) =Rhs(i,j,k)-stencil2*fdg1(i-1,j,k)
          enddo
!
          i=nil-sol_pil_e
          ii=i+l_i0-1
          do j=1+sol_pil_s, njl-sol_pil_n
             jj=j+l_j0-1
             di_8= Opr_opsyp0_8(G_nj+jj) / cos( G_yg_8 (jj) )**2
             stencil3= Opr_opsxp2_8(2*G_ni+ii)*di_8
             Rhs(i,j,k) =Rhs(i,j,k)-stencil3*fdg1(i+1,j,k)
          enddo
!  
          j=1+sol_pil_s
          jj=j+l_j0-1
          do i=1+sol_pil_w, nil-sol_pil_e
             ii=i+l_i0-1
             stencil4= Opr_opsxp0_8(G_ni+ii)*Opr_opsyp2_8(jj)
             Rhs(i,j,k) =Rhs(i,j,k)-stencil4*fdg1(i,j-1,k)
          enddo
!
          j=njl-sol_pil_n
          jj=j+l_j0-1
          do i=1+sol_pil_w, nil-sol_pil_e
             ii=i+l_i0-1
             stencil5= Opr_opsxp0_8(G_ni+ii)*Opr_opsyp2_8(2*G_nj+jj)
             Rhs(i,j,k) =Rhs(i,j,k)-stencil5*fdg1(i,j+1,k)
          enddo
!
      enddo
!
!     ---------------------------------------------------------------
!
      return
      end

