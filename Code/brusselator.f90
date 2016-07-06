!******************************************************************************
! Subroutine to Initialize, calculate the RHS, and calculate the Jacobian
! of the Kaps problem (Hairer II, pp 403)
!******************************************************************************
! REQUIRED FILES:
! PRECISION_VARS.F90        *DEFINES PRECISION FOR ALL VARIABLES
! CONTROL_VARIABLES.F90     *CONTAINS VARIABLES AND ALLOCATION ROUTINES
!******************************************************************************

      subroutine Brusselator(programStep,nveclen,ep,dt, &
     &                       tfinal,iDT,resE_vec,resI_vec,akk)

      use precision_vars
      use control_variables

      implicit none
!-----------------------VARIABLES----------------------------------------------
      integer,  parameter    :: vecl=2
      integer, intent(in   ) :: programStep
      real(wp), parameter    :: aa=5.0_wp, bb=2.0_wp

      !INIT vars
      real(wp), intent(in   ) :: ep
      real(wp), intent(inout) :: dt
      integer,  intent(  out) :: nveclen
      real(wp), intent(  out) :: tfinal
      integer,  intent(in   ) :: iDT

      real(wp), dimension(81,vecl+1) :: ExactTot
      real(wp)                       :: diff
      integer                        :: i,j

      !RHS vars
      real(wp), dimension(vecl), intent(  out) :: resE_vec,resI_vec
      
      !Jacob vars
      real(wp), intent(in   ) :: akk
!------------------------------------------------------------------------------

      !**Pre-initialization. Get problem name and vector length**
      if (programStep==-1) then
        nvecLen = vecl
        probname='Brusselat'     
        tol=5.0e-9_wp  
        dt_error_tol=1.0e-13_wp
        
      !**Initialization of problem information**        
      elseif (programStep==0) then
      
        dt = 0.25_wp/10**((iDT-1)/20.0_wp) ! timestep   
        tfinal = 1.0_wp                   ! final time
        
        !**Exact Solution** 
        open(unit=39,file='exact.brusselator.data')
        rewind(39)
        do i=1,81
          read(39,*)ExactTot(i,1),ExactTot(i,2)
          ExactTot(i,3) = 1.0_wp/10**((i-1)/(10.0_wp))  !  used for 81 values of ep
        enddo
        do i=1,81
          diff = abs(ExactTot(i,3) - ep)
          if(diff.le.1.0e-10_wp)then
            uexact(:) = ExactTot(i,:vecl)
            exit
          endif
        enddo

        !**IC**
        uvec(1) = 1.0_wp
        uvec(2) = 1.0_wp
      
      !**RHS and Jacobian**
      elseif (programStep>=1) then

        select case (Temporal_Splitting)

          case('IMEX') ! For IMEX schemes
            !**RHS**
            if (programStep==1 .or.programStep==2) then
              resE_vec(1) = 0.0_wp
              resE_vec(2) = 0.0_wp
              resI_vec(1) = 0.0_wp
              resI_vec(2) = 0.0_wp
            !**Jacobian**
            elseif (programStep==3) then
              xjac(1,1) = 1.0_wp-akk*dt*(0.0_wp)
              xjac(1,2) = 0.0_wp-akk*dt*(0.0_wp)
              xjac(2,1) = 0.0_wp-akk*dt*(0.0_wp)
              xjac(2,2) = 1.0_wp-akk*dt*(0.0_wp)
            endif
            
          case('IMPLICIT') ! For fully implicit schemes
            !**RHS**
            if (programStep==1 .or.programStep==2) then
              resE_vec(:) = 0.0_wp
              resI_vec(1) = dt*(aa+uvec(1)*( uvec(1)*uvec(2)-bb-1))
              resI_vec(2) = dt*(   uvec(1)*(-uvec(1)*uvec(2)+bb  ))
            !**Jacobian**
            elseif (programStep==3) then
              xjac(1,1) = 1.0_wp-akk*dt*(   2.0_wp*uvec(1)*uvec(2)-bb-1)
              xjac(1,2) = 0.0_wp-akk*dt*(          uvec(1)*uvec(1))
              xjac(2,1) = 0.0_wp-akk*dt*(bb-2.0_wp*uvec(1)*uvec(2))
              xjac(2,2) = 1.0_wp-akk*dt*(          uvec(1)*uvec(1))
            endif
            
          case default ! To catch invald inputs
            write(*,*)'Invaild case entered. Enter "IMEX" or "IMPLICIT"'
            write(*,*)'Exiting'
            stop
            
        end select
        
      endif
      
      end subroutine Brusselator
