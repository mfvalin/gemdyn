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

!**s/r nest_bcs_t0 -
!
      subroutine nest_bcs_t0 ()
      implicit none
#include <arch_specific.hf>
!
!author 
!     Michel Desgagne   - Spring 2006
!
!revision
! v3_30 - Lee V.          - initial version
! v4_03 - Lee/Plante      - acid test
! v4_05 - Lepine M.       - VMM replacement with GMM
! v4_14 - PLante          - Top piloting (Lid nesting)
!
#include "gmm.hf"
#include "glb_ld.cdk"
#include "vt0.cdk"
#include "nest.cdk"
#include "tr3d.cdk"
#include "lam.cdk"
#include "schm.cdk"

      character(len=GMM_MAXNAMELENGTH) :: tr_name
      integer err,i,j,k,nvar,n,istat
      real, pointer, dimension(:,:,:) :: tr,tr0
!
!----------------------------------------------------------------------
!
      istat = gmm_get(gmmk_nest_u_s ,nest_u )
      istat = gmm_get(gmmk_nest_v_s ,nest_v )
      istat = gmm_get(gmmk_nest_t_s ,nest_t )
      istat = gmm_get(gmmk_nest_s_s ,nest_s )
      istat = gmm_get(gmmk_nest_w_s ,nest_w )
      istat = gmm_get(gmmk_nest_zd_s,nest_zd)

      istat = gmm_get(gmmk_ut0_s , ut0 )
      istat = gmm_get(gmmk_vt0_s , vt0 )
      istat = gmm_get(gmmk_tt0_s , tt0 )
      istat = gmm_get(gmmk_st0_s , st0 )
      istat = gmm_get(gmmk_wt0_s , wt0 )
      istat = gmm_get(gmmk_zdt0_s,zdt0 )

      if (.not.Schm_hydro_L) then
         istat = gmm_get(gmmk_nest_q_s,nest_q)

         istat = gmm_get(gmmk_qt0_s,qt0)
      endif

      if ( Schm_nologT_L) then
         istat = gmm_get(gmmk_nest_xd_s,nest_xd)
         istat = gmm_get(gmmk_xdt0_s,xdt0 )
         if (.not.Schm_hydro_L) then
            istat = gmm_get(gmmk_nest_qd_s,nest_qd)
            istat = gmm_get(gmmk_qdt0_s,qdt0)
         endif
      endif

      if (l_north) then
         ut0 (1:l_niu,l_nj-pil_n+1:l_nj ,1:G_nk) = nest_u (1:l_niu,l_nj-pil_n+1:l_nj ,1:G_nk)
         vt0 (1:l_ni ,l_nj-pil_n  :l_njv,1:G_nk) = nest_v (1:l_ni ,l_nj-pil_n  :l_njv,1:G_nk)
         tt0 (1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk) = nest_t (1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk)
         st0 (1:l_ni ,l_nj-pil_n+1:l_nj) = nest_s (1:l_ni,l_nj-pil_n+1:l_nj)
         wt0 (1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk) = nest_w (1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk)
         zdt0(1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk) = nest_zd(1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk)
         if(Schm_nologT_L) &
         xdt0(1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk) = nest_xd(1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk)
         if (.not. Schm_hydro_L) then
            qt0 (1:l_ni ,l_nj-pil_n+1:l_nj ,2:G_nk+1) = nest_q (1:l_ni ,l_nj-pil_n+1:l_nj ,2:G_nk+1)
            if(Schm_nologT_L) &
            qdt0(1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk)   = nest_qd(1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk)
         endif
      endif

      if (l_south) then
         ut0 (1:l_niu,1:pil_s ,1:G_nk) = nest_u (1:l_niu,1:pil_s ,1:G_nk)
         vt0 (1:l_ni ,1:pil_s ,1:G_nk) = nest_v (1:l_ni ,1:pil_s ,1:G_nk)
         tt0 (1:l_ni ,1:pil_s ,1:G_nk) = nest_t (1:l_ni ,1:pil_s ,1:G_nk)
         st0 (1:l_ni ,1:pil_s) = nest_s (1:l_ni,1:pil_s)
         wt0 (1:l_ni ,1:pil_s ,1:G_nk) = nest_w (1:l_ni ,1:pil_s ,1:G_nk)
         zdt0(1:l_ni ,1:pil_s ,1:G_nk) = nest_zd(1:l_ni ,1:pil_s ,1:G_nk)
         if(Schm_nologT_L) &
         xdt0(1:l_ni ,1:pil_s ,1:G_nk) = nest_xd(1:l_ni ,1:pil_s ,1:G_nk)
         if (.not. Schm_hydro_L) then
            qt0 (1:l_ni ,1:pil_s ,2:G_nk+1) = nest_q (1:l_ni ,1:pil_s ,2:G_nk+1)
            if(Schm_nologT_L) &
            qdt0(1:l_ni ,1:pil_s ,1:G_nk)   = nest_qd(1:l_ni ,1:pil_s ,1:G_nk)
         endif
      endif

      if (l_east) then
         ut0 (l_ni-pil_e  :l_niu,1:l_nj ,1:G_nk) = nest_u (l_ni-pil_e  :l_niu,1:l_nj ,1:G_nk)
         vt0 (l_ni-pil_e+1:l_ni ,1:l_njv,1:G_nk) = nest_v (l_ni-pil_e+1:l_ni ,1:l_njv,1:G_nk)
         tt0 (l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk) = nest_t (l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk)
         st0 (l_ni-pil_e+1:l_ni ,1:l_nj) = nest_s (l_ni-pil_e+1:l_ni,1:l_nj)
         wt0 (l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk) = nest_w (l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk)
         zdt0(l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk) = nest_zd(l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk)
         if(Schm_nologT_L) &
         xdt0(l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk) = nest_xd(l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk)
         if (.not. Schm_hydro_L) then
            qt0 (l_ni-pil_e+1:l_ni ,1:l_nj ,2:G_nk+1) = nest_q (l_ni-pil_e+1:l_ni ,1:l_nj ,2:G_nk+1)
            if(Schm_nologT_L) &
            qdt0(l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk)   = nest_qd(l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk)
         endif
      endif

      if (l_west) then
         ut0 (1:pil_w, 1:l_nj , 1:G_nk) = nest_u (1:pil_w, 1:l_nj , 1:G_nk)
         vt0 (1:pil_w, 1:l_njv, 1:G_nk) = nest_v (1:pil_w, 1:l_njv, 1:G_nk)
         tt0 (1:pil_w, 1:l_nj , 1:G_nk) = nest_t (1:pil_w, 1:l_nj , 1:G_nk)
         st0 (1:pil_w, 1:l_nj) = nest_s (1:pil_w,1:l_nj)
         wt0 (1:pil_w, 1:l_nj , 1:G_nk) = nest_w (1:pil_w, 1:l_nj , 1:G_nk)
         zdt0(1:pil_w, 1:l_nj , 1:G_nk) = nest_zd(1:pil_w, 1:l_nj , 1:G_nk)
         if(Schm_nologT_L) &
         xdt0(1:pil_w, 1:l_nj , 1:G_nk) = nest_xd(1:pil_w, 1:l_nj , 1:G_nk)
         if (.not. Schm_hydro_L) then
            qt0 (1:pil_w, 1:l_nj, 2:G_nk+1) = nest_q (1:pil_w, 1:l_nj, 2:G_nk+1)
            if(Schm_nologT_L) &
            qdt0(1:pil_w, 1:l_nj, 1:G_nk)   = nest_qd(1:pil_w, 1:l_nj , 1:G_nk)
         endif
      endif

      if (Schm_opentop_L) then
         ut0 (1:l_niu,1:l_nj ,1:Lam_gbpil_t) = nest_u (1:l_niu,1:l_nj ,1:Lam_gbpil_t)
         vt0 (1:l_ni ,1:l_njv,1:Lam_gbpil_t) = nest_v (1:l_ni ,1:l_njv,1:Lam_gbpil_t)
         tt0 (1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1) = nest_t (1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1)
         wt0 (1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1) = nest_w (1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1)
         zdt0(1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1) = nest_zd(1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1)
         if(Schm_nologT_L) &
         xdt0(1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1) = nest_xd(1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1)
         if (.not. Schm_hydro_L) then
            qt0 (1:l_ni,1:l_nj,2:Lam_gbpil_t)     = nest_q (1:l_ni,1:l_nj,2:Lam_gbpil_t)
            if(Schm_nologT_L) &
            qdt0(1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1) = nest_qd(1:l_ni ,1:l_nj ,1:Lam_gbpil_t-1)
         endif
      endif

      if (Lam_toptt_L) then
!        Pilot the temperature for the whole top level
         do j=1,l_nj
         do i=1,l_ni
            tt0(i,j,1) = nest_t(i,j,1)
         end do
         end do
      endif

      do n=1,Tr3d_ntr
         tr_name = 'NEST/'//trim(Tr3d_name_S(n))//':C'
         istat = gmm_get(tr_name,tr)
         tr_name = 'TR/'//trim(Tr3d_name_S(n))//':M'
         istat = gmm_get(tr_name,tr0)

         if (l_north) &
         tr0 (1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk) = tr (1:l_ni ,l_nj-pil_n+1:l_nj ,1:G_nk)
         if (l_east)  &
         tr0 (l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk) = tr (l_ni-pil_e+1:l_ni ,1:l_nj ,1:G_nk)
         if (l_south) &
         tr0 (1:l_ni ,1:pil_s ,1:G_nk) = tr (1:l_ni ,1:pil_s ,1:G_nk)
         if (l_west)  &
         tr0 (1:pil_w ,1:l_nj ,1:G_nk) = tr (1:pil_w ,1:l_nj ,1:G_nk)

         if (Schm_opentop_L) &
         tr0 (1:l_ni, 1:l_nj, 1:Lam_gbpil_t-1) = tr (1:l_ni, 1:l_nj, 1:Lam_gbpil_t-1)

      enddo


!
!----------------------------------------------------------------------
 1000 format (/,19('#'),' NEST_BCS STAT ',i6,1X,19('#'))
 1001 format(3X,'NEST Boundary ConditionS: (S/R NEST_BCS)')
!
      return
      end
