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

!**s/r hzd_imp_ctrl - applies horizontal diffusion on field F_f2hzd
!

      subroutine hzd_imp_ctrl (F_f2hzd, F_grd_S, NK)
      implicit none
#include <arch_specific.hf>
!
      character*(*) F_grd_S
      integer     Minx,Maxx,Miny,Maxy, Nk
      real        F_f2hzd (*)
!
!author
!     Abdessamad Qaddouri
!
!revision
! v2_10 - Qaddouri A.       - initial version
! v2_21 - Desgagne M.       - control for diffusion on momentum only
! v2_31 - Desgagne M.       - remove stkmemw
! v3_11 - Corbeil L.        - new RPNCOMM transpose
! v4    - Gravel-Girard-Plante - staggered version
! v4_04 - Girard-Plante     - Diffuse only real winds and zdot.
! v4_05 - Plante A.         - Diffuse w.
!
!object
! The diffusion includes: second  order(Hzd_pwr=1), 
!                         fourth  order(Hzd_pwr=2),
!                         sixth   order(Hzd_pwr=3) and 
!                         eightth order(Hzd_pwr=4) diffusion operator
! 
#include "fft.cdk"
#include "glb_ld.cdk"
#include "trp.cdk"
#include "hzd.cdk"
#include "opr.cdk"
#include "ptopo.cdk"
!
      integer dpwr, nev, NSTOR, trpmin,trpmax,trpn
      real cdiff
      real*8  wk1_8(l_minx:l_maxx,l_miny:l_maxy, NK)
      real*8, pointer, dimension (:) :: a,c,d,xp,yp,evvec,odvec,wh_evec
!     __________________________________________________________________
!
      cdiff = Hzd_cdiff
      dpwr  = Hzd_pwr

      nev   = (G_ni+2)/ 2
      NSTOR = nev + ( 1 - mod(nev,2) )

      trpmin  =  trp_12dmin
      trpmax  =  trp_12dmax
      trpn    =  trp_12dn
      evvec   => Opr_evvec_8
      odvec   => Opr_odvec_8
      wh_evec => Hzd_wevec_8

      if (F_grd_S.eq.'U') then
         a       => Hzd_au_8
         c       => Hzd_cu_8
         d       => Hzd_deltau_8
         xp      => Hzd_xp0_8
         yp      => Opr_opsyp0_8
         evvec   => Hzd_evvec_8
         odvec   => Hzd_odvec_8
         wh_evec => Hzd_wuevec_8
      endif

      if (F_grd_S.eq.'V') then
         a       => Hzd_av_8
         c       => Hzd_cv_8
         d       => Hzd_deltav_8
         xp      => Opr_opsxp0_8
         yp      => Hzd_yp0_8
      endif

      if (F_grd_S.eq.'S') then
         a       => Hzd_as_8
         c       => Hzd_cs_8
         d       => Hzd_deltas_8
         xp      => Opr_opsxp0_8
         yp      => Opr_opsyp0_8
         trpmin  =  trp_p12dmin
         trpmax  =  trp_p12dmax
         trpn    =  trp_p12dn
      endif

      if (F_grd_S.eq.'S_TR') then
         a       => Hzd_astr_8
         c       => Hzd_cstr_8
         d       => Hzd_deltastr_8
         xp      => Opr_opsxp0_8
         yp      => Opr_opsyp0_8
         trpmin  =  trp_p12dmin
         trpmax  =  trp_p12dmax
         trpn    =  trp_p12dn
         cdiff   =  Hzd_cdiff_tr
         dpwr    =  Hzd_pwr_tr
      endif

      dpwr  = dpwr / 2

      if (Fft_fast_L) then

         call hzd_solfft2( F_f2hzd, wk1_8, a,c,d                       , &
                           trpmin,trpmax,trp_22min,trp_22max           , &
                           trpn,trp_22n,G_nj, dpwr, l_minx,l_maxx,l_miny,l_maxy, Nk, G_ni, &
                           l_ni,l_nj, trpn, xp, yp, cdiff              , &
                           Ptopo_npex,Ptopo_npey,G_lam )

      else

         call hzd_solmxma     ( F_f2hzd, wk1_8, wh_evec,                      &
                                a,c,d, trpmin,trpmax,trp_22min,trp_22max,     &
                                trpn,trp_22n,G_nj, dpwr, l_minx,l_maxx,l_miny,l_maxy, Nk, G_ni, &
                                l_ni,l_nj, trpn, xp, yp, cdiff,               &
                                Ptopo_npex,Ptopo_npey)
      endif
!     __________________________________________________________________
!
      return
      end
