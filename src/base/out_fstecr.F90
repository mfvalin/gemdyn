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

!**s/r out_fstecr

      subroutine out_fstecr3 ( fa,lminx,lmaxx,lminy,lmaxy,rf,nomvar,&
                               mul,add,kind,lstep,nkfa,ind_o,nk_o  ,&
                               nbit,F_empty_stk_L )
      use ISO_C_BINDING
      implicit none
#include <arch_specific.hf>

      character* (*) nomvar
      logical F_empty_stk_L
      integer lminx,lmaxx,lminy,lmaxy,nkfa,nbit,nk_o,kind,lstep
      integer ind_o(nk_o)
      real fa (lminx:lmaxx,lminy:lmaxy,nkfa), rf(nkfa), mul,add

#include "glb_ld.cdk"
#include "lctl.cdk"
#include "out.cdk"
#include "out3.cdk"
#include "outp.cdk"
#include "step.cdk"
      include 'convert_ip123.inc'
      include 'out_meta.cdk'

Interface
subroutine out_stkecr2 ( fa,lminx,lmaxx,lminy,lmaxy,meta,nplans, &
                         g_id,g_if,g_jd,g_jf )
      include "out_meta.cdk"
      integer lminx,lmaxx,lminy,lmaxy,nplans
      integer g_id,g_if,g_jd,g_jf
      real fa(lminx:lmaxx,lminy:lmaxy,nplans)
      type (meta_fstecr), dimension(:), pointer :: meta
End Subroutine out_stkecr2
End Interface

      type(FLOAT_IP) :: RP1,RP2,RP3
      real,   parameter :: eps=1.e-12
      character*8 dumc
      logical, save :: done= .false.
      integer modeip1,i,j,k,ip1,ip2,ip3,err
      integer, save :: istk = 0
      real percent
      real, save, dimension (:,:,:), pointer :: f2c => null()
      type (meta_fstecr), save, dimension(:), pointer :: meta => null()
!
!----------------------------------------------------------------------
!
      if (.not.associated(meta)) allocate (meta(out_stk_size))
      if (.not.associated(f2c )) &
         allocate (f2c(l_minx:l_maxx,l_miny:l_maxy,out_stk_size))
      if (.not.done) then
         out_stk_full= 0 ; out_stk_part= 0 ; out_stk_partbin= 0 ; done= .true.
      endif

      if (F_empty_stk_L) then
         if ( istk .gt. 0) then
            call out_stkecr2 ( f2c,l_minx,l_maxx,l_miny,l_maxy ,&
                               meta,istk, Out_gridi0,Out_gridin,&
                                          Out_gridj0,Out_gridjn )
            if (istk.lt.out_stk_size) then
               out_stk_part= out_stk_part + 1
               percent=real(out_stk_size-istk)/real(out_stk_size)
               if ( (percent <= 0.02)                       ) out_stk_partbin(1) = out_stk_partbin(1) + 1
               if ( (percent >  0.02).and.(percent <=  0.04)) out_stk_partbin(2) = out_stk_partbin(2) + 1
               if ( (percent >  0.04).and.(percent <=  0.08)) out_stk_partbin(3) = out_stk_partbin(3) + 1
               if ( (percent >  0.08).and.(percent <=  0.16)) out_stk_partbin(4) = out_stk_partbin(4) + 1
               if ( (percent >  0.16).and.(percent <=  0.32)) out_stk_partbin(5) = out_stk_partbin(5) + 1
               if ( (percent >  0.32).and.(percent <=  0.64)) out_stk_partbin(6) = out_stk_partbin(6) + 1
               if ( (percent >  0.64)                       ) out_stk_partbin(7) = out_stk_partbin(7) + 1
            else
               out_stk_full= out_stk_full + 1
            endif
         endif
         istk= 0
         deallocate (meta, f2c) ; nullify (meta, f2c)
         return
      endif

      modeip1= 1
      if (kind.eq.2) modeip1= 3 !old ip1 style for pressure lvls output

      if ( lstep > 0 ) then
         RP2%lo  = dble(lstep           ) * dble(Step_dt) / 3600.d0
         RP2%hi  = dble(max(0,lctl_step)) * dble(Step_dt) / 3600.d0
         RP2%kind= KIND_HOURS
         RP3%lo= 0. ; RP3%hi= 0. ; RP3%kind= 0
      endif

      do k= 1, nk_o
         istk = istk + 1
         do j= 1, l_nj
         do i= 1, l_ni
            f2c(i,j,istk)= fa(i,j,ind_o(k))*mul + add
         end do
         end do
         if ( lstep > 0 ) then
            RP1%lo  = rf(ind_o(k))
            RP1%hi  = RP1%lo
            RP1%kind= kind
            err= encode_ip ( meta(istk)%ip1,meta(istk)%ip2,&
                             meta(istk)%ip3,RP1,RP2,RP3 )
         else
            meta(istk)%ip2= Out_ip2
            meta(istk)%ip3= Out_ip3
            call convip ( meta(istk)%ip1, rf(ind_o(k)), kind,&
                          modeip1,dumc,.false. )
         endif
         meta(istk)%nv   = nomvar
         meta(istk)%ig1  = Out_ig1
         meta(istk)%ig2  = Out_ig2
         meta(istk)%ig3  = Out_ig3
         meta(istk)%ni   = Out_gridin - Out_gridi0 + 1
         meta(istk)%nj   = Out_gridjn - Out_gridj0 + 1
         meta(istk)%nbits= nbit
         meta(istk)%dtyp = 134
         if (istk.eq.out_stk_size) then
            call out_stkecr2 ( f2c,l_minx,l_maxx,l_miny,l_maxy ,&
                               meta,istk, Out_gridi0,Out_gridin,&
                                          Out_gridj0,Out_gridjn )
            istk=0
            out_stk_full= out_stk_full + 1
         endif
      end do
!
!--------------------------------------------------------------------
!
      return
      end
