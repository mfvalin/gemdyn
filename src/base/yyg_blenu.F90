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
!***s/r yyg_blenu - to interpolate and exchange U wind
!


      Subroutine yyg_blenu(tab_dst,tabu_src,tabv_src,Minx,Maxx,Miny,Maxy,NK)
      implicit none
#include <arch_specific.hf>
!
!author
!           Abdessamad Qaddouri/V.Lee - October 2009
!
!     include 'mpif.h'
#include "ptopo.cdk"
#include "glb_ld.cdk"
#include "geomn.cdk"
#include "geomg.cdk"
#include "glb_pil.cdk"
#include "yyg_blnu.cdk"

      integer Minx,Maxx,Miny,Maxy,Ni,Nj,NK,numproc
      real  tabu_src (Minx:Maxx,Miny:Maxy,Nk), tabv_src (Minx:Maxx,Miny:Maxy,Nk)
      real  tab_dst (Minx:Maxx,Miny:Maxy,Nk)
      real*8  tabu_src_8(Minx:Maxx,Miny:Maxy,NK)
      real*8  tabv_src_8(Minx:Maxx,Miny:Maxy,NK)
      integer ierr,i,j,k,kk,kk_proc,m,mm,adr
      real, dimension (:,:), allocatable :: recv_pil,send_pil
      real sent,recv
!     integer status(MPI_STATUS_SIZE)
!     integer stat(MPI_STATUS_SIZE,Ptopo_numproc)
      integer status
      integer request(Ptopo_numproc*2)
      real*8  send_pil_8,tabu_8,tabv_8
      integer tag2,recvlen,sendlen,tag1,ireq
      tag2=14
      tag1=13
      
      sendlen=0
      recvlen=0
      ireq=0
      do kk=1,Bln_usendmaxproc
         sendlen=max(sendlen,Bln_usend_len(kk))
      enddo
      do kk=1,Bln_urecvmaxproc
         recvlen=max(recvlen,Bln_urecv_len(kk))
      enddo
      

!     print *,'yyg_blenu: sendlen=',sendlen,' recvlen=',recvlen
      if (sendlen.gt.0) then
          allocate(send_pil(sendlen*NK,Bln_usendmaxproc))
!         assume rpn_comm_xch_halo already done on tab_src
          tabu_src_8(:,:,:)=dble(tabu_src(:,:,:))
          tabv_src_8(:,:,:)=dble(tabv_src(:,:,:))
      endif
      if (recvlen.gt.0) then
          allocate(recv_pil(recvlen*NK,Bln_urecvmaxproc))
      endif
 
!
      do 100 kk=1,Bln_usendmaxproc
!
!        For each processor (in other colour)
         if (Ptopo_couleur.eq.0) then
             kk_proc = Bln_usendproc(kk)+Ptopo_numproc-1
         else
             kk_proc = Bln_usendproc(kk)-1
         endif

!        prepare to send to other colour processor
         if (Bln_usend_len(kk).gt.0) then
!            prepare something to send

                adr=Bln_usend_adr(kk)+1

             call int_cubvec_lag(send_pil(1,KK),tabu_src_8, tabv_src_8,  &
                             Bln_usend_imx1(adr),Bln_usend_imy1(adr),    &
                             Bln_usend_imx2(adr),Bln_usend_imy2(adr),    &
                             Geomg_xu_8,Geomg_y_8,Geomg_x_8,Geomg_yv_8,  &
                             l_minx,l_maxx,l_miny,l_maxy,Nk,             &
                             Bln_usend_xxr(adr),Bln_usend_yyr(adr),      &
                             Bln_usend_len(kk) ,                         &
                             Bln_usend_s1(adr) ,Bln_usend_s2(adr) )

             ireq = ireq+1
!            print *,'blenu: sending',Bln_usend_len(kk)*NK, ' to ',kk_proc
!            call MPI_ISend (send_pil(1,KK),Bln_usend_len(kk)*NK,MPI_REAL, &
!                                        kk_proc,tag2+Ptopo_world_myproc, &
!                                        MPI_COMM_WORLD,request(ireq),ierr)
             call RPN_COMM_ISend (send_pil(1,KK),Bln_usend_len(kk)*NK, &
                                  'MPI_REAL',kk_proc,tag2+Ptopo_world_myproc, &
                                  'MULTIGRID',request(ireq),ierr)
         endif
 100  continue
!
!        check to receive from other colour processor
!
      do 200 kk=1,Bln_urecvmaxproc

         if (Ptopo_couleur.eq.0) then
             kk_proc = Bln_urecvproc(kk)+Ptopo_numproc-1
         else
             kk_proc = Bln_urecvproc(kk)-1
         endif
         if (Bln_urecv_len(kk).gt.0) then
!            detect something to receive

             ireq = ireq+1
!            print *,'blenu: receiving',Bln_urecv_len(kk)*NK,' from ',kk_proc
!            call MPI_IRecv(recv_pil(1,KK),Bln_urecv_len(kk)*NK,MPI_REAL,  &
!                   kk_proc,tag2+kk_proc,MPI_COMM_WORLD,request(ireq),ierr)
             call RPN_COMM_IRecv(recv_pil(1,KK),Bln_urecv_len(kk)*NK,'MPI_REAL',&
                    kk_proc,tag2+kk_proc,'MULTIGRID',request(ireq),ierr)
         endif

 200  continue

!Wait for all done sending and receiving

!     call mpi_waitall(ireq,request,stat,ierr)
      call RPN_COMM_waitall_nostat(ireq,request,ierr)

! Now fill my results if I have received something

      if (recvlen.gt.0) then

          do 300 kk=1,Bln_urecvmaxproc
             mm=0
             do m=1,Bln_urecv_len(kk)
                adr=Bln_urecv_adr(kk)+m
             do k=1,NK
                mm=mm+1
                tab_dst(Bln_urecv_i(adr),Bln_urecv_j(adr),k)= &
                0.5*tab_dst(Bln_urecv_i(adr),Bln_urecv_j(adr),k)+ &
                0.5*recv_pil(mm,KK)
             enddo
             enddo
 300  continue

       
      endif
      if (recvlen.gt.0)deallocate(recv_pil)
      if (sendlen.gt.0) deallocate(send_pil)

!
!
      return
      end

