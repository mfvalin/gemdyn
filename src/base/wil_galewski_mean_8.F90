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

!**s/r wil_galewski_mean_8 
!

!
      function wil_galewski_mean_8 (evaluated_at_lat_8)
!
      implicit none
!
      real*8 wil_galewski_mean_8,evaluated_at_lat_8
!
!author M.Tanguay 
!
!revision
! v4_04 - Tanguay M.       - initial version
! v4_04 - Tanguay M.       - Galewski's case
! v4_XX - Cote/Tanguay     - correction 
!
!object
!     Evaluate Mean of geopotential in balanced state 
!     of Galewski's case (Tellus,2004)
!

#include "dcst.cdk"
!
!     ---------------------------------------------------------
      real*8   wil_galewski_geo_8,int_8,geo_8,cslat_8,fct_8,lat_8
      external wil_galewski_geo_8
!
      integer, parameter :: J_MAX = 100 
!
      integer j,jj,j_partial 
!
      real bound1,bound2,lat_4
      real gauss_latitude(J_MAX),gauss_weight(J_MAX)
!
!     ---------------------------------------------------------
!
      j_partial = J_MAX
!
      bound1 = -Dcst_pi_8/2. 
      bound2 = evaluated_at_lat_8 
!
!     Evaluate parameters for Gaussian integral 
!     -----------------------------------------
      call wil_gauleg (bound1,bound2,gauss_latitude,gauss_weight,j_partial)
!
      int_8 = 0.
!
!     Do Gaussian integral w.r.t theta
!     --------------------------------
      do jj = 1,j_partial
!
           lat_4 =      gauss_latitude(jj)
           lat_8 = dble(gauss_latitude(jj))
         cslat_8 = cos(lat_8)
!
           geo_8 = wil_galewski_geo_8 (lat_8)
           fct_8 = cslat_8 * geo_8
!
           int_8 = int_8 + gauss_weight(jj) * fct_8 
!
      enddo
!
!     Correction (J.Cote): Integral of cosinus from [-0.5 pi,0.5 pi] is 2
!     -------------------------------------------------------------------
      int_8 = 0.5 * int_8
!
      wil_galewski_mean_8 = int_8 
!
!     ---------------------------------------------------------
!
      return
      end
