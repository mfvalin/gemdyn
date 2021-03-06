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

!**s/r set_oprz - Computes vertical operators and matrices a,b,c
!                 for the elliptic solver
!

!
      subroutine set_oprz
      implicit none
#include <arch_specific.hf>
!
!author
!     M. Desgagne - initial MPI version (from setoprz v1_03)
!
!revision
! v2_00 - Desgagne M.       - initial MPI version
! v4_00 - Plante & Girard   - Log-hydro-pressure coord on Charney-Phillips grid
! v4_02   Qaddouri A.       - Rewrite set_pois for vertical stag version
! v4_05 - Girard C.         - Open top
!

#include "glb_ld.cdk"
#include "dcst.cdk"
#include "schm.cdk"
#include "lam.cdk"
#include "opr.cdk"
#include "sol.cdk"
#include "cstv.cdk"
#include "trp.cdk"
#include "ver.cdk"
#include "ptopo.cdk"

      integer k, km, k0, k1, AA, BB, CC
      real*8, parameter ::  one = 1.d0
      real*8  wk(G_nk), Falfas_8, Fbetas_8
      real*8, dimension  &
      ((trp_12smax-trp_12smin+1)*(trp_22max-trp_22min+1)*G_nj) :: a,b,c
!
!     __________________________________________________________________
!
!
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!     Compute the vertical operators: tri-diagnonal matrices
!                  O(AA+k): lower diagonal
!                  O(BB+k):       diagonal
!                  O(CC+k): upper diagonal
!           O(AA+k)*P(k-1)+O(BB+k)*P(k)+O(CC+k)*P(k+1)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      AA=0
      BB=G_nk
      CC=G_nk*2
      k0=1+Lam_gbpil_T
!
!     ~~~~~~~~~~~~~~~~~
!     Diagonal Operator
!     ~~~~~~~~~~~~~~~~~
!
      do k = 1, G_nk
         Opr_opszp0_8(AA+k) = 0.d0
         Opr_opszp0_8(BB+k) = one
         Opr_opszp0_8(CC+k) = 0.d0
         !        Zero in the others to start
         Opr_opszp2_8(AA+k) = 0.d0
         Opr_opszp2_8(BB+k) = 0.d0
         Opr_opszp2_8(CC+k) = 0.d0
         Opr_opszpm_8(AA+k) = 0.d0
         Opr_opszpm_8(BB+k) = 0.d0
         Opr_opszpm_8(CC+k) = 0.d0
         Opr_opszpl_8(AA+k) = 0.d0
         Opr_opszpl_8(BB+k) = 0.d0
         Opr_opszpl_8(CC+k) = 0.d0
      end do
!
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~
!     Second Derivative Operator
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      Opr_opszp2_8(AA+k0)   = 0.d0
      Opr_opszp2_8(BB+k0)   =-Ver_idz_8%t(k0 )*Ver_gama_8(k0)*Ver_idz_8%m(k0)
      Opr_opszp2_8(CC+k0)   =+Ver_idz_8%t(k0 )*Ver_gama_8(k0)*Ver_idz_8%m(k0)
      do k = k0+1, G_nk-1
         Opr_opszp2_8(AA+k) =+Ver_idz_8%t(k-1)*Ver_gama_8(k-1)*Ver_idz_8%m(k)
         Opr_opszp2_8(BB+k) =-Ver_idz_8%t(k-1)*Ver_gama_8(k-1)*Ver_idz_8%m(k) &
                             -Ver_idz_8%t(k)*Ver_gama_8(k)*Ver_idz_8%m(k)
         Opr_opszp2_8(CC+k) =+Ver_idz_8%t(k)*Ver_gama_8(k)*Ver_idz_8%m(k)
      end do
      Opr_opszp2_8(AA+G_nk) =+Ver_idz_8%m(G_nk)/Ver_wpstar_8(G_nk)* &
                              (Ver_idz_8%t(G_nk-1)*Ver_gama_8(G_nk-1) &
                              +Ver_idz_8%t(G_nk  )*Ver_gama_8(G_nk  )*Ver_betas_8 )
      Opr_opszp2_8(BB+G_nk) =-Ver_idz_8%m(G_nk)/Ver_wpstar_8(G_nk)* &
                             (Ver_idz_8%t(G_nk-1)*Ver_gama_8(G_nk-1) &
                             +Ver_idz_8%t(G_nk  )*Ver_gama_8(G_nk  )*(one-Ver_alfas_8) )
      Opr_opszp2_8(CC+G_nk) = 0.d0
!
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!     First Derivative Operator (non symetric)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
      Opr_opszpl_8(AA+k0)   = 0.d0
      Opr_opszpl_8(BB+k0)   =-Ver_wp_8%m(k0)*Ver_idz_8%t(k0)*Ver_gama_8(k0)
      Opr_opszpl_8(CC+k0)   =+Ver_wp_8%m(k0)*Ver_idz_8%t(k0)*Ver_gama_8(k0)
      do k = k0+1, G_nk-1
         Opr_opszpl_8(AA+k) =-Ver_wm_8%m(k)*Ver_idz_8%t(k-1)*Ver_gama_8(k-1)
         Opr_opszpl_8(BB+k) =+Ver_wm_8%m(k)*Ver_idz_8%t(k-1)*Ver_gama_8(k-1) &
                             -Ver_wp_8%m(k)*Ver_idz_8%t(k)*Ver_gama_8(k)
         Opr_opszpl_8(CC+k) =+Ver_wp_8%m(k)*Ver_idz_8%t(k)*Ver_gama_8(k)
      end do
      Opr_opszpl_8(AA+G_nk) =-Ver_wmA_8(G_nk)*Ver_idz_8%t(G_nk-1)*Ver_gama_8(G_nk-1) &
                             +Ver_betas_8 &
                             *Ver_wpA_8(G_nk)*Ver_idz_8%t(G_nk)*Ver_gama_8(G_nk)
      Opr_opszpl_8(BB+G_nk) =+Ver_wmA_8(G_nk)*Ver_idz_8%t(G_nk-1)*Ver_gama_8(G_nk-1) &
                             -(one-Ver_alfas_8) &
                             *Ver_wpA_8(G_nk)*Ver_idz_8%t(G_nk)*Ver_gama_8(G_nk)
      Opr_opszpl_8(CC+G_nk) = 0.d0
!
!     ~~~~~~~~~~~~~~~~~~~~~~~
!     Double average operator
!     ~~~~~~~~~~~~~~~~~~~~~~~
!
      Falfas_8=.5d0*Ver_wmstar_8(G_nk)+Ver_wpstar_8(G_nk)*Ver_alfas_8
      Fbetas_8=.5d0*Ver_wmstar_8(G_nk)+Ver_wpstar_8(G_nk)*Ver_betas_8

      Opr_opszpm_8(AA+k0)   = 0.d0
      Opr_opszpm_8(BB+k0)   = Ver_wp_8%m(k0)*.5d0*Ver_gama_8(k0)*Ver_epsi_8(k0)
      Opr_opszpm_8(CC+k0)   = Ver_wp_8%m(k0)*.5d0*Ver_gama_8(k0)*Ver_epsi_8(k0)
      do k = k0+1, G_nk-1
         Opr_opszpm_8(AA+k) = Ver_wm_8%m(k)*.5d0*Ver_gama_8(k-1)*Ver_epsi_8(k-1)
         Opr_opszpm_8(BB+k) = Ver_wm_8%m(k)*.5d0*Ver_gama_8(k-1)*Ver_epsi_8(k-1) &
                            + Ver_wp_8%m(k)*.5d0*Ver_gama_8(k)*Ver_epsi_8(k)
         Opr_opszpm_8(CC+k) = Ver_wp_8%m(k)*.5d0*Ver_gama_8(k)*Ver_epsi_8(k)
      end do
      Opr_opszpm_8(AA+G_nk) = Ver_wmA_8(G_nk)*.5d0*Ver_gama_8(G_nk-1)*Ver_epsi_8(G_nk-1) &
                            + Ver_wpA_8(G_nk)*Fbetas_8*Ver_gama_8(G_nk)*Ver_epsi_8(G_nk)
      Opr_opszpm_8(BB+G_nk) = Ver_wmA_8(G_nk)*.5d0*Ver_gama_8(G_nk-1)*Ver_epsi_8(G_nk-1) &
                            + Ver_wpA_8(G_nk)*Falfas_8*Ver_gama_8(G_nk)*Ver_epsi_8(G_nk)
      Opr_opszpm_8(CC+G_nk) = 0.d0
!
!
      if(Schm_opentop_L) then
         Opr_opszp2_8(BB+k0) = Opr_opszp2_8(BB+k0) - Ver_idz_8%t(k0-1)*Ver_gama_8(k0-1)*Ver_idz_8%m(k0)*(one-Ver_alfat_8)
         Opr_opszpl_8(BB+k0) = Opr_opszpl_8(BB+k0) &
                             + Ver_wm_8%m(k0)*Ver_idz_8%t(k0-1)*Ver_gama_8(k0-1)*(one-Ver_alfat_8)
         Opr_opszpm_8(BB+k0) = Opr_opszpm_8(BB+k0) + Ver_wm_8%m(k0) &
            		     *(Ver_wp_8%t(k0-1)+Ver_wm_8%t(k0-1)*Ver_alfat_8)*Ver_gama_8(k0-1)*Ver_epsi_8(k0-1)
      endif
!
!     substracting derivative of gamma*epsi
      do k = k0, G_nk-1
         km=max(k-1,1)
         Opr_opszpl_8(BB+k) = Opr_opszpl_8(BB+k) - Ver_idz_8%m(k) &
                            *(Ver_gama_8(k)*Ver_epsi_8(k)-Ver_onezero(k)*Ver_gama_8(km)*Ver_epsi_8(km))
      end do
      Opr_opszpl_8(AA+G_nk) = Opr_opszpl_8(AA+G_nk) &
             - Ver_idz_8%m(G_nk)/Ver_wpstar_8(G_nk)*.5d0*Ver_wmstar_8(G_nk) &
             * (Ver_gama_8(G_nk)*Ver_epsi_8(G_nk)-Ver_gama_8(G_nk-1)*Ver_epsi_8(G_nk-1))
      Opr_opszpl_8(BB+G_nk) = Opr_opszpl_8(BB+G_nk) &
             - Ver_idz_8%m(G_nk)/Ver_wpstar_8(G_nk)*(one-.5d0*Ver_wmstar_8(G_nk)) &
             * (Ver_gama_8(G_nk)*Ver_epsi_8(G_nk)-Ver_gama_8(G_nk-1)*Ver_epsi_8(G_nk-1))

!     multiplying by 1-cappa
      do k = k0, G_nk
         Opr_opszpm_8(AA+k) = Opr_opszpm_8(AA+k)*(one-Dcst_cappa_8)
         Opr_opszpm_8(BB+k) = Opr_opszpm_8(BB+k)*(one-Dcst_cappa_8)
         Opr_opszpm_8(CC+k) = Opr_opszpm_8(CC+k)*(one-Dcst_cappa_8)
      end do
!     ---------------------------------------------------
!     Compute eigenvalues and eigenvector in the vertical
!     ---------------------------------------------------
!
      call set_pois (Opr_zeval_8, Opr_lzevec_8, Opr_zevec_8, G_nk, G_nk)
!
      do k =1, G_nk-Lam_gbpil_T
      do k1=1, G_nk-Lam_gbpil_T
         wk(k) = Opr_zevec_8 ((k-1)*G_nk+k1)
      enddo
      wk(k)= Cstv_hco0_8*Opr_zeval_8(k)
      enddo

      sol_nk = trp_12sn-east*Lam_gbpil_T

      if (Sol_type_s.eq.'DIRECT') then
         call sol_abc ( wk,G_yg_8(1),Opr_opsyp0_8, &
                        Opr_opsyp2_8,Opr_xeval_8 , &
             trp_12smin, trp_12smax,  sol_nk, trp_12sn0, &
             trp_22min , trp_22max , trp_22n, trp_22n0 , &
             G_ni,G_nj,G_nk, Sol_ai_8, Sol_bi_8, Sol_ci_8 )
      endif
!
!     ---------------------------------------------------------------
!
      return
      end
