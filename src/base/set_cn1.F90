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

!**s/r set_cn1 - initialization of the commons at level one
!
      subroutine set_cn1
      implicit none
#include <arch_specific.hf>

!author
!     michel roch - rpn - june 1993
!
!revision
! v2_00 - Desgagne/Lee      - initial MPI version (from setcn1 v1_03)
! v2_31 - Desgagne/Lee      - introduce tracers, output of sliced tracers
! v3_11 - Gravel S.         - modify for theoretical cases
! v3_21 - Lee V.            - remove Tr2d
! v3_30 - Desgagne & Winger - call glb_restart

#include "gmm.hf"
#include "var_gmm.cdk"
#include "glb_ld.cdk"
#include "grd.cdk"
#include "init.cdk"
#include "lun.cdk"
#include "p_geof.cdk"

      integer :: istat
!
!-------------------------------------------------------------------
!
      if (Lun_out.gt.0) write(Lun_out,2000)

      call var_dict

!     Initialize the time-dependent variables comdecks
!     -------------------------------------------------
      call heap_paint

      call set_vt( )

      if (Grd_yinyang_L) then
!     Initialization for Yin-Yang communications
         call yyg_initscalbc()
         call yyg_initvecbc1()
         call yyg_initvecbc2()
         call yyg_initblenbc2()
         call yyg_initblenu()
         call yyg_initblenv()
      else
         if (G_lam) call nest_set_gmmvar
      endif

!     Initialize right hand sides comdeck
!     -----------------------------------
      call set_rhs( )

!     Initialize digital filter variables comdecks
!     --------------------------------------------
      if ( Init_mode_L ) call set_vta( )

      gmmk_fis0_s      = 'FIS0'
      gmmk_topo_low_s  = 'TOPOLOW'
      gmmk_topo_high_s = 'TOPOHIGH'

      nullify (fis0, topo_low, topo_high)
      istat = gmm_create(gmmk_fis0_s,fis0,meta2d,GMM_FLAG_RSTR+GMM_FLAG_IZER)

      istat = gmm_create(gmmk_topo_low_s ,topo_low ,meta2d,GMM_FLAG_RSTR+GMM_FLAG_IZER)
      istat = gmm_create(gmmk_topo_high_s,topo_high,meta2d,GMM_FLAG_RSTR+GMM_FLAG_IZER)

 2000 format( /,'INITIALIZATION OF MAIN GMM VARIABLES S/R SET_CN1', &
              /,'====================================================')
!
!     ---------------------------------------------------------------
!
      return
      end
