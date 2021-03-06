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

subroutine itf_adx_main (F_nb_iter)
   implicit none
#include <arch_specific.hf>
!
   !@objective Initialisation before Performing advection
!
   !@arguments
   integer :: F_nb_iter       !I, total number of iterations for trajectories
!
   !@author  Stephane Chamberland, Jan 2010
   !@revisions

#include "glb_ld.cdk"
#include "schm.cdk"
#include "orh.cdk"
#include "lctl.cdk"
#include "step.cdk"

   logical :: doAdwStat_L
   integer :: nk_winds
   real, dimension(:,:,:), allocatable, save :: ud,vd,wd,ua,va,wa,wat
   logical, save :: done = .false.

   !---------------------------------------------------------------------

   nk_winds= G_nk
   if(Schm_superwinds_L) nk_winds= 2*G_nk+1

   doAdwStat_L = .false.
   if (Step_gstat.gt.0) doAdwStat_L = (mod(Lctl_step,Step_gstat) == 0)
   doAdwStat_L = doAdwStat_L .and. (Orh_icn == Schm_itcn)

   if (.not. done) &
      allocate (ud(l_minx:l_maxx,l_miny:l_maxy,nk_winds), &
                vd(l_minx:l_maxx,l_miny:l_maxy,nk_winds), &
                wd(l_minx:l_maxx,l_miny:l_maxy,nk_winds), &
                ua(l_ni,l_nj,G_nk), va(l_ni,l_nj,G_nk)  , &
               	wa(l_ni,l_nj,G_nk),wat(l_ni,l_nj,G_nk) )

! ua, va, wa, wat only if trapeze ??? + wat=zdt0 ???

   call itf_adx_get_winds2 ( ud, vd, wd, ua, va, wa, wat, &
                             l_minx,l_maxx,l_miny,l_maxy, &
                             l_nk, l_ni, l_nj, nk_winds )

   call adx_main ( ud, vd, wd, ua, va, wa, wat, &
                   l_minx,l_maxx,l_miny,l_maxy, &
                   nk_winds, F_nb_iter, doAdwStat_L )

   done = .true.

   !---------------------------------------------------------------------

   return
end subroutine itf_adx_main
