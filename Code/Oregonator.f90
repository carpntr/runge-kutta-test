!******************************************************************************
! Subroutine to Initialize, calculate the RHS, and calculate the Jacobian
! of the Oregonator problem 
!******************************************************************************
! REQUIRED FILES:
! PRECISION_VARS.F90        *DEFINES PRECISION FOR ALL VARIABLES
! CONTROL_VARIABLES.F90     *CONTAINS VARIABLES AND ALLOCATION ROUTINES
!******************************************************************************

      subroutine Oregonator(programStep,nveclen,ep,dt, &
     &                  tfinal,iDT,rese_vec,resi_vec,akk)
      use precision_vars
      use control_variables

!     Oregonator system
!     


      implicit none
!-----------------------VARIABLES----------------------------------------------
      integer, parameter     :: vecl=3
      real(wp), parameter    :: aa= 77.27_wp !small=oscil large=flatline
      real(wp), parameter    :: bb= 8.375e-6_wp !small=horizontal stretch large=oscil
      real(wp), parameter    :: cc= 01610.0_wp !small=reduces large t behavior and amplifies low t
                                             !large=oscil
                 
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
      real(wp)                :: cct
!------------------------------------------------------------------------------


      !**Pre-initialization. Get problem name and vector length**
      if (programStep==-1) then
        nvecLen = vecl
        probname='Oregonatr'         
        tol=1.0e-10_wp
        dt_error_tol=1.0e-13_wp
        
      !**Initialization of problem information**
      elseif (programStep==0) then
      
!       dt = 0.25_wp*0.00001_wp/10**((iDT-1)/20.0_wp) !used for exact solution
!  HACK
       dt = 0.0125_wp/10**((iDT-1)/20.0_wp) ! timestep 
!  HACK
!        dt = 0.25_wp/10**((iDT-1)/20.0_wp) ! timestep 
        tfinal = 360.0_wp                    ! final time

        !**Exact Solution**
        uexact(1)=0.1000814870318523e1_wp
        uexact(2)=0.1228178521549917e4_wp
        uexact(3)=0.1320554942846706e3_wp

        !**IC**
        uvec(1) = 1.0_wp
        uvec(2) = 2.0_wp
        uvec(3) = 3.0_wp
        
      !**RHS and Jacobian**        
      elseif (programStep>=1) then
      
      !  Stiff component is cc
      cct = cc / ep

        select case (Temporal_Splitting)

          case('IMEX') ! For IMEX schemes
            !**RHS**
            if (programStep==1 .or.programStep==2) then
              resE_vec(1)=dt * (-uvec(2)-uvec(3)) ;
              resE_vec(2)=dt * (+uvec(1)+aa*uvec(2)) ;
              resE_vec(3)=dt * (bb*uvec(1) + uvec(3)*(    +uvec(1))) ;
              resI_vec(1:2)=0.0_wp
              resI_vec(3)=dt * (           + uvec(3)*(-cct        )) ;
            !**Jacobian**
            elseif (programStep==3) then
              xjac(1,1) = 1.0_wp-akk*dt*(+0.0_wp)
              xjac(1,2) = 0.0_wp-akk*dt*(+0.0_wp)
              xjac(1,3) = 0.0_wp-akk*dt*(+0.0_wp)

              xjac(2,1) = 0.0_wp-akk*dt*(+0.0_wp)
              xjac(2,2) = 1.0_wp-akk*dt*(+0.0_wp)
              xjac(2,3) = 0.0_wp-akk*dt*(+0.0_wp)

              xjac(3,1) = 0.0_wp-akk*dt*(0.0_wp)
              xjac(3,2) = 0.0_wp-akk*dt*(0.0_wp)
              xjac(3,3) = 1.0_wp-akk*dt*( -cct )
            endif
            
          case('IMPLICIT') ! For fully implicit schemes
            !**RHS**
            if (programStep==1 .or.programStep==2) then
              resE_vec(:)=0.0_wp
              resI_vec(1)=dt * (aa*(uvec(2)+uvec(1)*(1.0_wp-bb*uvec(1)-uvec(2))) )
              resI_vec(2)=dt * ((uvec(3)-(1.0_wp+uvec(1))*uvec(2))/aa )
              resI_vec(3)=dt * (cc*(uvec(1)-uvec(3)) )
            !**Jacobian* *
            elseif (programStep==3) then
              xjac(1,1) = 1.0_wp - akk*dt*(aa*(1.0_wp-2.0_wp*bb*uvec(1)-uvec(2)) )
              xjac(1,2) = 0.0_wp - akk*dt*(aa*(1.0_wp-uvec(1)) )
              xjac(1,3) = 0.0_wp - akk*dt*(0.0_wp)

              xjac(2,1) = 0.0_wp - akk*dt*(-uvec(2)/aa )
              xjac(2,2) = 1.0_wp - akk*dt*(-(1.0_wp+uvec(1))/aa )
              xjac(2,3) = 0.0_wp - akk*dt*(1.0_wp/aa )

              xjac(3,1) = 0.0_wp - akk*dt*(+cc )
              xjac(3,2) = 0.0_wp - akk*dt*(0.0_wp)
              xjac(3,3) = 1.0_wp - akk*dt*(-cc )
            endif
            
          case default ! To catch invalid inputs
            write(*,*)'Invaild case entered. Enter "IMEX" or "IMPLICIT"'
            write(*,*)'Exiting'
            stop
            
        end select
          
      endif

      end subroutine Oregonator