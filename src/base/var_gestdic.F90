!-------------------------------------- LICENCE BEGIN ------------------------------------
!Environment Canada - Atmospheric Science and Technology License/Disclaimer,
!                     version 3; Last Modified: May 7, 2008.
!This is free but copyrighted software; you can use/redistribute/modify it under the terms
!of the Environment Canada - Atmospheric Science and Technology License/Disclaimer
!version 3 or (at your option) any later version that should be found at:
!http://collaboration.cmc.ec.gc.ca/science/rpn.comm/license.html
!
!This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
!without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
!See the above mentioned License/Disclaimer for more details.
!You should have received a copy of the License/Disclaimer along with this software;
!if not, you can write to: EC-RPN COMM Group, 2121 TransCanada, suite 500, Dorval (Quebec),
!CANADA, H9P 1J3; or send e-mail to service.rpn@ec.gc.ca
!-------------------------------------- LICENCE END --------------------------------------
!**s/r var_gestdic
!
      subroutine var_gestdic (string)
      implicit none
#include <arch_specific.hf>

      character(len=*),intent(in)  :: string

!Author
!     M. Desgagne  -  fall 2013
!
#include "dcst.cdk"
#include "vardict.cdk"

      character*256 substring, upper_string
      character*32 mult_S,add_S
      integer lst,ion,ign,ihs,ivs,imu,iad
      integer i,ideb,ifin,flag
!
!-------------------------------------------------------------------
!
      call low2up (string,upper_string)

      lst = len(trim(upper_string))
      ion = index(upper_string,"OUTNAME=" )
      ign = index(upper_string,"GMMNAME=" )
      ihs = index(upper_string,"HSTAG="   )
      ivs = index(upper_string,"VSTAG="   )
      imu = index(upper_string,"FACT_MUL=")
      iad = index(upper_string,"FACT_ADD=")

      if (ign.gt.0) then
         substring = upper_string(ign+8:lst)
         ifin= index (substring,';') - 1
         if (ifin < 0) ifin = len(trim(substring))
         ideb= 1
         do i=1,ifin
            if (substring(i:i) == ' ') then
               ideb=ideb+1
            else
               exit
            endif
         end do
         if (ifin-ideb+1 .gt. 0) then
            var_cnt = var_cnt + 1
            vardict(var_cnt)%gmm_name= substring(ideb:ifin)
         else
            return
         endif
      else
         return
      endif
         
      if (ion.gt.0) then
         substring = upper_string(ion+8:lst)
         ifin   = index (substring,';') - 1
         if (ifin < 0) ifin = len(trim(substring))
         ideb= 1
         do i=1,ifin
            if (substring(i:i) == ' ') then
               ideb=ideb+1
            else
               exit
            endif
         end do
         if (ifin-ideb+1 .gt. 0) then
            vardict(var_cnt)%out_name= substring(ideb:ifin)
         endif
      endif

      if (ihs.gt.0) then
         substring = upper_string(ihs+6:lst)
         ifin   = index (substring,';') - 1
         if (ifin < 0) ifin = len(trim(substring))
         ideb= 1
         do i=1,ifin
            if (substring(i:i) == ' ') then
               ideb=ideb+1
            else
               exit
            endif
         end do
         if (ifin-ideb+1 .gt. 0) then
            vardict(var_cnt)%hor_stag= substring(ideb:ifin)
         endif
      endif

      if (ivs.gt.0) then
         substring = upper_string(ivs+6:lst)
         ifin   = index (substring,';') - 1
         if (ifin < 0) ifin = len(trim(substring))
         ideb= 1
         do i=1,ifin
            if (substring(i:i) == ' ') then
               ideb=ideb+1
            else
               exit
            endif
         end do
         if (ifin-ideb+1 .gt. 0) then
            vardict(var_cnt)%ver_stag= substring(ideb:ifin)
         endif
      endif

      if ( (len(trim(vardict(var_cnt)%out_name)) .gt. 0) .and. &
         ( (len(trim(vardict(var_cnt)%hor_stag)) .eq. 0) .or.  &
           (len(trim(vardict(var_cnt)%ver_stag)) .eq. 0) ) ) then
         print*, 'error 1'
         stop
      endif

      if (imu.gt.0) then
         substring = upper_string(imu+9:lst)
         ifin   = index (substring,';') - 1
         if (ifin < 0) ifin = len(trim(substring))
         ideb= 1
         do i=1,ifin
            if (substring(i:i) == ' ') then
               ideb=ideb+1
            else
               exit
            endif
         end do
         if (ifin-ideb+1 .gt. 0) then
            read(substring(ideb:ifin),*) vardict(var_cnt)%fact_mult
         endif
      endif

      if (iad.gt.0) then
         substring = upper_string(iad+9:lst)
         ifin   = index (substring,';') - 1
         if (ifin < 0) ifin = len(trim(substring))
         ideb= 1
         do i=1,ifin
            if (substring(i:i) == ' ') then
               ideb=ideb+1
            else
               exit
            endif
         end do
         if (ifin-ideb+1 .gt. 0) then
            read(substring(ideb:ifin),*) vardict(var_cnt)%fact_add
         endif
      endif

!      print*, 'OKOKOKOK: ',var_cnt
!      print*, 'GMM_NAME: ',trim(vardict(var_cnt)%gmm_name)
!      print*, 'OUT_NAME: ',trim(vardict(var_cnt)%out_name)
!      print*, 'HOR_STAG: ',trim(vardict(var_cnt)%hor_stag)
!      print*, 'VER_STAG: ',trim(vardict(var_cnt)%ver_stag)
!      print*, 'FACT_MUL: ',vardict(var_cnt)%fact_mult
!      print*, 'FACT_ADD: ',vardict(var_cnt)%fact_add
!
!-------------------------------------------------------------------
      return
      end
