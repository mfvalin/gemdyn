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
!/@*
subroutine adx_get_ij0n(i0,in,j0,jn)
   implicit none
#include <arch_specific.hf>
   !@objective Return advection computational i,j domain
   !@arguments
   integer :: i0,j0,in,jn     !O, scope of advection operations
   !@author  Stephane Chamberland, 2009-12
   !@revisions
   !@ v4_40 - Qaddouri/Lee    - Yin-Yang, expand calculation by 1 point around
#include "adx_dims.cdk"
   !*@/
   !---------------------------------------------------------------------
   integer :: jext

   i0 = 1
   in = adx_mlni
   j0 = 1
   jn = adx_mlnj

   if (adx_lam_L) then
      jext=1
      if (adx_yinyang_L) jext=2
      if (adx_is_west)  i0 =            adx_pil_w - jext
      if (adx_is_east)  in = adx_mlni - adx_pil_e + jext
      if (adx_is_south) j0 =            adx_pil_s - jext
      if (adx_is_north) jn = adx_mlnj - adx_pil_n + jext
   endif

   !---------------------------------------------------------------------
   return
end subroutine adx_get_ij0n
