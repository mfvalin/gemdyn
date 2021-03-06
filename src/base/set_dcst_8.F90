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

!**function set_dcst_8 - initializes geophysical constants
!
      logical function set_dcst_8 ( val, liste, nbre, unout, numproc )
      implicit none
#include <arch_specific.hf>

      integer nbre,unout,numproc
      character * (*) liste(nbre)
      real*8 val(nbre)

!author
!     M. Desgagne July 2005

      integer i, ier, ierrmpi, flag(nbre)
      real*8 rdval
      external RPN_COMM_bcst_x
!
!     ---------------------------------------------------------------
!
      if (unout.gt.0) write (unout,1000)

      flag = 0

      i=1
      if (unout.gt.0) then
         ier = 1
         call constnt (rdval,ier,liste(i),100)
         if (ier.eq.1) then
         rdval = 0.4d0
         ier = 1
         call constnt (rdval,ier,'KARMAN',103)
         write(unout,100)
         write(unout,102) 'THE VALUE OF THE CONSTANT KARMAN HAS BEEN'
         write(unout,102) '                          ------         '
         write(unout,103) 'CHANGED TO ', rdval,'   IN S/R set_dcst_8'
         write(unout,100)
         endif
      endif

      if (numproc.gt.1)  &
         call constnt_x (rdval,ier,liste(i),4,RPN_COMM_bcst_x, &
                                                4,0,0,ierrmpi)

      do i=1,nbre
         call constnt (val(i),flag(i),liste(i),100)
      end do

      set_dcst_8  = .true.

      do i=1,nbre
         if (flag(i).eq.1) then
            if (unout.gt.0) write (unout,1005) liste(i),val(i)
         else            
            if (unout.gt.0) write (unout,1006) liste(i)
            set_dcst_8  = .false.
         endif
      end do

  100 format (1x,52('*'))
  102 format (1x,'*',4x,A,5x,'*')
  103 format (1x,'*',4x,A,F4.2,A,11x,'*')
 1000 format ( &
            /,'INITIALIZATION OF PHYSICAL CONSTANTS: (S/R SET_DCST_8)', &
            /,'======================================================')
 1005 format (1x,"THE VALUE OF",1x,a10,2x,"=",1x,e21.12)
 1006 format (" WARNING ==> THE CONSTANT ",a10," DOES NOT EXIST.")
!
!     ---------------------------------------------------------------
!
      return
      end
