!******************************************************************************
! Subroutine to Initialize, calculate the RHS, and calculate the Jacobian
! of the Lorenz problem 
!******************************************************************************
! REQUIRED FILES:
! PRECISION_VARS.F90        *DEFINES PRECISION FOR ALL VARIABLES
! CONTROL_VARIABLES.F90     *CONTAINS VARIABLES AND ALLOCATION ROUTINES
!******************************************************************************

      subroutine Rossler_Chaos(programStep,nveclen,ep,dt, &
     &                  tfinal,iDT,rese_vec,resi_vec,akk)
      use precision_vars
      use control_variables

      implicit none
!-----------------------VARIABLES----------------------------------------------
      integer, parameter     :: vecl=3
      real(wp), parameter    :: aa= 0.15_wp
      real(wp), parameter    :: bb= 0.20_wp
      real(wp), parameter    :: cc=10.00_wp
                 
      integer, intent(in   ) :: programStep
 
      !INIT vars
      real(wp),        intent(in   ) :: ep
      real(wp),        intent(inout) :: dt
      integer,         intent(inout) :: nveclen
      real(wp),        intent(  out) :: tfinal
      integer,         intent(in   ) :: iDT

      real(wp), dimension(81,vecl+1) :: ExactTot
      real(wp)                       :: diff
      integer                        :: i,j

      !RHS vars
      real(wp), dimension(vecl), intent(  out) :: rese_vec,resi_vec
      
      !Jacob vars
      real(wp), intent(in   ) :: akk
!------------------------------------------------------------------------------

      !**Pre-initialization. Get problem name and vector length**
      if (programStep==-1) then
        nvecLen = vecl
        probname='Rossler_3'         
        tol=1.0e-11_wp
        
      !**Initialization of problem information**
      elseif (programStep==0) then
      
        !dt = 0.25_wp*0.00001_wp/10**((iDT-1)/20.0_wp) !used for exact solution
        dt = 0.25_wp/10**((iDT-1)/20.0_wp) ! timestep 
        tfinal = 1.0_wp                    ! final time

        !**Exact Solution**
        open(unit=39,file='exact.Rossler_Chaos.data')
        rewind(39)
        do i=1,81
          read(39,*)ExactTot(i,1),ExactTot(i,2),ExactTot(i,3)
          ExactTot(i,4) = 1.0_wp/10**((i-1)/(10.0_wp)) !  used for 81 values of ep
        enddo
        do i=1,81
          diff = abs(ExactTot(i,4) - ep)
          if(diff.le.1.0e-10_wp)then
            uexact(:) = ExactTot(i,:vecl)
            exit
          endif
        enddo

        !**IC**
        uvec(1) = 0.0_wp
        uvec(2) = 1.0_wp
        uvec(3) = 0.0_wp
        
      !**RHS and Jacobian**        
      elseif (programStep>=1) then

        select case (Temporal_Splitting)

          case('IMEX') ! For IMEX schemes
            !**RHS**
            if (programStep==1 .or.programStep==2) then
              rese_vec(:)=0.0_wp
              resi_vec(1)=dt * (-uvec(2)-uvec(3)) ;
              resi_vec(2)=dt * (+uvec(1)+aa*uvec(2)) ;
              resi_vec(3)=dt * (bb + uvec(3)*(uvec(1)-cc)) ;
            !**Jacobian**
            elseif (programStep==3) then
              xjac(1,1) = 1.0_wp-akk*dt*(+0.0_wp)
              xjac(1,2) = 0.0_wp-akk*dt*(-1.0_wp)
              xjac(1,3) = 0.0_wp-akk*dt*(+1.0_wp)

              xjac(2,1) = 0.0_wp-akk*dt*(+1.0_wp)
              xjac(2,2) = 1.0_wp-akk*dt*(aa )
              xjac(2,3) = 0.0_wp-akk*dt*(0.0_wp)

              xjac(3,1) = 0.0_wp-akk*dt*(uvec(3))
              xjac(3,2) = 0.0_wp-akk*dt*(0.0_wp)
              xjac(3,3) = 1.0_wp-akk*dt*(-cc + uvec(1))
            endif
            
          case('IMPLICIT') ! For fully implicit schemes
            !**RHS**
            if (programStep==1 .or.programStep==2) then
              rese_vec(:)=0.0_wp
              resi_vec(1)=dt * (-uvec(2)-uvec(3)) ;
              resi_vec(2)=dt * (+uvec(1)+aa*uvec(2)) ;
              resi_vec(3)=dt * (bb + uvec(3)*(uvec(1)-cc)) ;
            !**Jacobian* *
            elseif (programStep==3) then
              xjac(1,1) = 1.0_wp-akk*dt*(+0.0_wp)
              xjac(1,2) = 0.0_wp-akk*dt*(-1.0_wp)
              xjac(1,3) = 0.0_wp-akk*dt*(+1.0_wp)

              xjac(2,1) = 0.0_wp-akk*dt*(+1.0_wp)
              xjac(2,2) = 1.0_wp-akk*dt*(aa )
              xjac(2,3) = 0.0_wp-akk*dt*(0.0_wp)

              xjac(3,1) = 0.0_wp-akk*dt*(uvec(3))
              xjac(3,2) = 0.0_wp-akk*dt*(0.0_wp)
              xjac(3,3) = 1.0_wp-akk*dt*(-cc + uvec(1))
            endif
            
          case default ! To catch invald inputs
            write(*,*)'Invaild case entered. Enter "IMEX" or "IMPLICIT"'
            write(*,*)'Exiting'
            stop
            
        end select
          
      endif

      end subroutine Rossler_Chaos
