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
!*s/r sol_lam - Solution of the elliptic problem for LAM grids
!
      subroutine sol_lam ( F_sol_8, F_rhs_8, F_dg1, F_dg2, F_dwfft, &
                           F_iln, F_prout, F_ni, F_nj, F_nk )
      implicit none
#include <arch_specific.hf>

      logical F_prout
      integer F_ni, F_nj, F_nk, F_iln
      real*8 F_rhs_8(F_ni,F_nj,F_nk), F_sol_8 (F_ni,F_nj,F_nk), &
             F_dg1(*), F_dg2(*), F_dwfft(*)

!author
!     Desgagne   Spring 2013
!
!revision
! v4_50 - Desgagne M.       - initial version

#include "glb_ld.cdk"
#include "glb_pil.cdk"
#include "lam.cdk"
#include "lun.cdk"
#include "ldnh.cdk"
#include "sol.cdk"
#include "opr.cdk"
#include "ptopo.cdk"
#include "fft.cdk"
#include "schm.cdk"
#include "trp.cdk"

      integer Gni, NK, i, j, nev, NSTOR, its, dim
      real*8  conv
      real*8, dimension(:), allocatable :: wk_evec_8
!
!     ---------------------------------------------------------------
!
      if ( sol_type_S .eq. 'ITERATIVE_2D' ) then
         
         NK = G_nk - Lam_gbpil_T
         call  sol_fgmres ( F_sol_8, F_rhs_8, F_iln, l_ni, l_nj, &
                        ldnh_minx,ldnh_maxx,ldnh_miny,ldnh_maxy, &
                        G_nk, NK, F_prout, conv, its )
         if ( F_prout ) write(Lun_out,1003) conv, its

      else

         NK = sol_nk
         if (Fft_fast_L) then
            
            call sol_fft_lam ( F_sol_8, F_rhs_8                   ,&
                      ldnh_maxx, ldnh_maxy, ldnh_nj               ,&
                      trp_12smax, trp_12sn, trp_22max, trp_22n    ,&
                      G_ni, G_nj, G_nk, NK, Ptopo_npex, Ptopo_npey,&
                      Sol_ai_8, Sol_bi_8, Sol_ci_8, F_dg2, F_dwfft )
         
         else
         
            Gni= G_ni-Lam_pil_w-Lam_pil_e
            dim= Gni*Gni
            allocate ( wk_evec_8(dim) )
            do j=1,Gni
            do i=1,Gni
               wk_evec_8((j-1)*Gni+i)= &
                    Opr_xevec_8((j+Lam_pil_w-1)*G_ni+i+Lam_pil_w)
            enddo
            enddo
         
            call sol_mxma ( F_sol_8, F_rhs_8, wk_evec_8       ,&
                 ldnh_maxx, ldnh_maxy, ldnh_nj, dim           ,&
                 trp_12smax, trp_12sn, trp_22max, trp_22n     ,&
                 G_ni, G_nj, G_nk, NK, Ptopo_npex, Ptopo_npey ,&
                 Sol_ai_8,Sol_bi_8,Sol_ci_8,F_dg1,F_dg2,F_dwfft)
         
            deallocate (wk_evec_8)
            
         endif

      endif

 1003 format (3x,'Final FGMRES solver convergence criteria: ',1pe14.7,' at iteration', i3)
!
!     ---------------------------------------------------------------
! 
      return
      end
