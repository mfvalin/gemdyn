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

!**s/r nest_HOR_gwa
!
      subroutine nest_HOR_gwa
      use nest_blending
      implicit none
#include <arch_specific.hf>

!author 
!     Michel Desgagne   - Spring 2006
!
!revision
! v3_30 - Lee V.          - initial version
! v4_05 - Plante A.       - top blending
! v4_05 - Lepine M.       - VMM replacement with GMM

#include "gmm.hf"
#include "glb_ld.cdk"
#include "vt1.cdk"
#include "lam.cdk"
#include "nest.cdk"
#include "tr3d.cdk"
#include "schm.cdk"

      integer n, gmmstat
      real, dimension(:,:,:), pointer :: fld3d=>null(), fld_nest3d=>null()
!
!----------------------------------------------------------------------
!
      if ( (Lam_blend_Hx <= 0).and.(Lam_blend_Hy <= 0) ) return
!
! Blending main dynamics variables + tracers
!
      gmmstat = gmm_get (gmmk_ut1_s   , fld3d     )
      gmmstat = gmm_get (gmmk_nest_u_s, fld_nest3d)
      call nest_blend (fld3d, fld_nest3d, l_minx,l_maxx,l_miny,l_maxy, 1,G_nk, 'U')

      gmmstat = gmm_get (gmmk_vt1_s   , fld3d     )
      gmmstat = gmm_get (gmmk_nest_v_s, fld_nest3d)
      call nest_blend (fld3d, fld_nest3d, l_minx,l_maxx,l_miny,l_maxy, 1,G_nk, 'V')

      gmmstat = gmm_get (gmmk_tt1_s   , fld3d     )
      gmmstat = gmm_get (gmmk_nest_t_s, fld_nest3d)
      call nest_blend (fld3d, fld_nest3d, l_minx,l_maxx,l_miny,l_maxy, 1,G_nk, 'M')

      call nest_blend (gmmk_st1_s  ,gmmk_nest_s_s  ,'M')

      gmmstat = gmm_get (gmmk_zdt1_s   , fld3d     )
      gmmstat = gmm_get (gmmk_nest_zd_s, fld_nest3d)
      call nest_blend (fld3d, fld_nest3d, l_minx,l_maxx,l_miny,l_maxy, 1,G_nk, 'M')

      if(Schm_nologT_L) then
         gmmstat = gmm_get (gmmk_xdt1_s   , fld3d     )
         gmmstat = gmm_get (gmmk_nest_xd_s, fld_nest3d)
         call nest_blend (fld3d, fld_nest3d, l_minx,l_maxx,l_miny,l_maxy, 1,G_nk, 'M')
      endif

         gmmstat = gmm_get (gmmk_wt1_s   , fld3d     )
         gmmstat = gmm_get (gmmk_nest_w_s, fld_nest3d)
         call nest_blend (fld3d, fld_nest3d, l_minx,l_maxx,l_miny,l_maxy, 1,G_nk, 'M')

      if ( .not.Schm_hydro_L ) then
         gmmstat = gmm_get (gmmk_qt1_s   , fld3d     )
         gmmstat = gmm_get (gmmk_nest_q_s, fld_nest3d)
         call nest_blend (fld3d, fld_nest3d, l_minx,l_maxx,l_miny,l_maxy, 1,G_nk, 'Q')

         if(Schm_nologT_L) then
            gmmstat = gmm_get (gmmk_qdt1_s   , fld3d     )
            gmmstat = gmm_get (gmmk_nest_qd_s, fld_nest3d)
            call nest_blend (fld3d, fld_nest3d, l_minx,l_maxx,l_miny,l_maxy, 1,G_nk, 'M')
         endif
      endif

      
      do n=1,Tr3d_ntr
         gmmstat = gmm_get ('TR/'//trim(Tr3d_name_S(n))//':P'  , fld3d     )
         gmmstat = gmm_get ('NEST/'//trim(Tr3d_name_S(n))//':C', fld_nest3d)
         call nest_blend (fld3d,fld_nest3d,l_minx,l_maxx,l_miny,l_maxy,1,G_nk, 'M')
      enddo
!
!----------------------------------------------------------------------
!
      return
      end
