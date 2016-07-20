      module SBP_Coef_Module

      use precision_vars, only: wp

      implicit none; save

      real(wp),  parameter                      :: tol=1.0e-12_wp

      private
      public  ::  Define_CSR_Operators,Pmat,Pinv,iD1,jD1,D1,iD2,jD2,D2,nnz_D2
      public  ::  nnz_D1_per,iD1_per,jD1_per,D1_per
      
      real(wp),  dimension(:), allocatable :: Pmat,Pinv,D1,D2,D1_per
      integer,   dimension(:), allocatable :: iD1, iD2,jD1,jD2,iD1_per,jD1_per
      integer                              :: nnz_D2,nnz_D1_per
      

      contains
!==============================================================================
      subroutine Define_CSR_Operators(n,h)
      
      
      integer,  intent(in) :: n
      real(wp), intent(in) :: h
      integer,  parameter  :: order = 242

!     CSR storage for derivative matrices
      integer             :: nnz_D1

      allocate(iD1(n+1),iD2(n+1),Pmat(n),Pinv(n))

!      if(order == 242) then
        nnz_D1 = 28+4*(n-8)
        allocate(jD1(nnz_D1),D1(nnz_D1))
        nnz_D2 = 38+5*(n-8)
        allocate(jD2(nnz_D2),D2(nnz_D2))
 !     endif
      
      nnz_D1_per=4*n
      allocate(iD1_per(n+1),jD1_per(nnz_D1_per),D1_per(nnz_D1_per))
      
 !     call D1_242(n,nnz_D1,iD1,jD1,D1,h)
 !     call D2_242(n,nnz_D2,iD2,jD2,D2,h)
      call D1_periodic(n,nnz_D1_per,iD1_per,jD1_per,D1_per,h)

      end subroutine Define_CSR_Operators
!==============================================================================         
      subroutine D1_periodic(n,nnz,ia,ja,a,h)

      integer,                    intent(in   ) :: n,nnz

      integer,   dimension(n+1),  intent(  out) :: ia
      integer,   dimension(nnz),  intent(  out) :: ja

      real(wp),  dimension(nnz),  intent(  out) ::  a
      real(wp),                   intent(in   ) :: h

      integer                                   :: i,j
      integer                                   :: icnt, jcnt

      real(wp),  dimension(5)      :: d1mat
      real(wp) :: tol
      
      
       !  Diagonal matrix norm needed for 1st- and 2nd-order derivatives 
      Pmat(:) = 1.0_wp*h
      Pinv(:) = 1.0_wp / Pmat(:)
      
      d1mat(:)= (/1.0_wp/12.0_wp,-8.0_wp/12.0_wp,0.0_wp, &
     &            8.0_wp/12.0_wp,-1.0_wp/12.0_wp/)
      
      tol=1.0e-12_wp
      
      ia(:) = (/ (i, i=1,n*4+1,4) /)
      ja(:) = 0      ;
      a(:) = 0.0_wp ;
      ia(1) = 1      ! start at beginning of array   
         
      a(1:2)=d1mat(4:5); ja(1:2)=(/2,3/)
      a(3:4)=d1mat(1:2); ja(3:4)=(/n-1,n/)
      a(5)  =d1mat(2)  ; ja(5)  =1
      a(6:7)=d1mat(4:5); ja(6:7)=(/3,4/)
      a(8)  =d1mat(1)  ; ja(8)  =n
      icnt  = 8
          
      do i = 3,n-2
        jcnt = 0 
        do j = 1,5
          if(abs(d1mat(j)) >= tol) then
              icnt = icnt + 1 ; jcnt = jcnt + 1 ;
          ja(icnt) = i-3+j
           a(icnt) = d1mat(j)
          endif
        enddo
!        ia(i+1) = ia(i) + jcnt
      enddo
      
      a(icnt+1)       =d1mat(5)  ; ja(icnt+1)       =1
      a(icnt+2:icnt+3)=d1mat(1:2); ja(icnt+2:icnt+3)=(/n-3,n-2/)
      a(icnt+4)       =d1mat(4)  ; ja(icnt+4)       =n
      a(icnt+5:icnt+6)=d1mat(4:5); ja(icnt+5:icnt+6)=(/1,2/)            
      a(icnt+7:icnt+8)=d1mat(1:2); ja(icnt+7:icnt+8)=(/n-2,n-1/)     
      
      end subroutine D1_periodic
!===============================================================================   
     
      subroutine D1_242(n,nnz,ia,ja,a,h)

      integer,                    intent(in   ) :: n,nnz

      integer,   dimension(n+1),  intent(  out) :: ia
      integer,   dimension(nnz),  intent(  out) :: ja

      real(wp),  dimension(nnz),  intent(  out) ::  a
      real(wp),                   intent(in   ) :: h

      integer                                   :: i,j,k
      integer                                   :: icnt, jcnt
      real(wp)                                  :: tnorm
      real(wp),  allocatable, dimension(:)      :: d1mat
      real(wp),  allocatable, dimension(:,:)    :: D1blk, D2blk, D1blkT

      continue

      if(n < 8) then 
        write(*,*)'Dimension not large enough to support D242: stopping'
        stop
      endif
      allocate(d1mat(1:5))
      allocate(D1blk(1:4,1:6))
      allocate(D2blk(1:4,1:6))
      allocate(D1blkT(1:6,1:4))

    !  h = 1.0_wp / (n - 1)

      !  Diagonal matrix norm needed for 1st- and 2nd-order derivatives 
      Pmat(1:  4) = reshape((/17.0_wp/48.0_wp,59.0_wp/48.0_wp,43.0_wp/48.0_wp,49.0_wp/48.0_wp/),(/4/))
      Pmat(5:n-4) = 1.0_wp
      Pmat(n-3:n) = reshape((/49.0_wp/48.0_wp,43.0_wp/48.0_wp,59.0_wp/48.0_wp,17.0_wp/48.0_wp/),(/4/))

      Pmat(:)=Pmat(:)*h


      Pinv(:) = 1.0_wp / Pmat(:)

      d1mat(:)= reshape((/1.0_wp/12.0_wp,-8.0_wp/12.0_wp,0.0_wp,8.0_wp/12.0_wp,-1.0_wp/12.0_wp/),(/5/))

      !  Boundary closure data for first derivative operators,  Note reshape does column first; hence the transpose
      D1blkT  = reshape(                                                                                               &
              & (/-24.0_wp/17.0_wp, 59.0_wp/34.0_wp, -4.0_wp/17.0_wp,-3.0_wp/34.0_wp, 0.0_wp        , 0.0_wp,          &
              &    -1.0_wp/ 2.0_wp,  0.0_wp        ,  1.0_wp/2.0_wp , 0.0_wp        , 0.0_wp        , 0.0_wp,          &
              &     4.0_wp/43.0_wp,-59.0_wp/86.0_wp,  0.0_wp        ,59.0_wp/86.0_wp,-4.0_wp/43.0_wp, 0.0_wp,          &
              &     3.0_wp/98.0_wp,  0.0_wp        ,-59.0_wp/98.0_wp, 0.0_wp        ,32.0_wp/49.0_wp,-4.0_wp/49.0_wp/),&
              & (/6,4/)  )
      D1blk = Transpose(D1blkT)

      !  Derivative operators are ``per-symmetric''
      do i=1,4
         do j=1,6
           D2blk(i,j)= - D1blk(5-i,7-j)
         end do
      end do
     
      !  Assemble derivative operator into compressed sparse row storage format
      call CSR_Filler(n,nnz,d1mat,D1blk,D2blk, ia,ja,a)

      !  account for spatial grid spacing.  Assumes domain is 0 <= x <= 1  
      a(:) = a(:) / h

      !  Derivative operator must differentiate monomials of sufficient order to be correct.
      call test_error(1,n,nnz,ia,ja,a)

      deallocate(d1mat,D1blk,D2blk,D1blkT)


      end subroutine D1_242

! =============================================================================

      subroutine D2_242(n,nnz,ia,ja,a,h)

      integer,                    intent(in   ) :: n,nnz

      integer,   dimension(n+1),  intent(  out) :: ia
      integer,   dimension(nnz),  intent(  out) :: ja

      real(wp),  dimension(nnz),  intent(  out) ::  a
      real(wp),                   intent(in   ) :: h
      
      real(wp),  dimension(4  )                 ::  Pmat_L, Pinv_L

      integer                                   :: i,j,k
      integer                                   :: icnt, jcnt
      real(wp)                                  :: tnorm, m24
      real(wp),  allocatable, dimension(:)      :: d1vec, d2mat
      real(wp),  allocatable, dimension(:,:)    :: M1blk, M2blk, M1blkT1, M1blkT2
      real(wp),  allocatable, dimension(:,:)    :: D1blk, D2blk
      real(wp),  parameter                      :: tol=1.0e-12_wp
      real(wp),  allocatable, dimension(:)      :: err, x0_vec, x1_vec, x2_vec
      real(wp),  allocatable, dimension(:)      ::     dx0_vec,dx1_vec,dx2_vec

      continue

      if(n < 8) then 
        write(*,*)'Dimension not large enough to support D242: stopping'
        stop
      endif
      allocate(d1vec(1:4))
      allocate(d2mat(1:5))
      allocate(M1blk(1:4,1:6),M2blk(1:4,1:6))
      allocate(M1blkT1(1:6,1:4),M1blkT2(1:6,1:4))
      allocate(D1blk(1:4,1:6),D2blk(1:4,1:6))

  !    h = 1.0_wp / (n - 1)

      Pmat_L(1:4) = reshape((/17.0_wp/48.0_wp,59.0_wp/48.0_wp,43.0_wp/48.0_wp,49.0_wp/48.0_wp/),(/4/))

      Pinv_L(:)   = 1.0_wp / Pmat_L(:)

      d1vec(:) = + reshape((/-24.0_wp/17.0_wp, 59.0_wp/34.0_wp,-4.0_wp/17.0_wp, -3.0_wp/34.0_wp                /),(/4/))
      d2mat(:) = - reshape((/  1.0_wp/12.0_wp,-16.0_wp/12.0_wp,30.0_wp/12.0_wp,-16.0_wp/12.0_wp,1.0_wp/12.0_wp /),(/5/))

      m24 = 16815244.0_wp/410099621.0_wp
      M1blkT1= reshape(                                                                                                 &
              & (/  9.0_wp/ 8.0_wp,-59.0_wp/48.0_wp, +1.0_wp/12.0_wp,  1.0_wp/48.0_wp, 0.0_wp        , 0.0_wp,          &
              &   -59.0_wp/48.0_wp, 59.0_wp/24.0_wp,-59.0_wp/48.0_wp,  0.0_wp        , 0.0_wp        , 0.0_wp,          &
              &     1.0_wp/12.0_wp,-59.0_wp/48.0_wp, 55.0_wp/24.0_wp,-59.0_wp/48.0_wp, 1.0_wp/12.0_wp, 0.0_wp,          &
              &     1.0_wp/48.0_wp,  0.0_wp        ,-59.0_wp/48.0_wp, 59.0_wp/24.0_wp,-4.0_wp/ 3.0_wp, 1.0_wp/12.0_wp/),&
              & (/6,4/)  )
      M1blkT2= reshape(                                                                                         &
              & (/-1.0_wp/3.0_wp*m24,+1.0_wp/1.0_wp*m24,-1.0_wp/1.0_wp*m24,+1.0_wp/3.0_wp*m24, 0.0_wp, 0.0_wp,  &
              &   +1.0_wp/1.0_wp*m24,-3.0_wp/1.0_wp*m24,+3.0_wp/1.0_wp*m24,-1.0_wp/1.0_wp*m24, 0.0_wp, 0.0_wp,  &
              &   -1.0_wp/1.0_wp*m24,+3.0_wp/1.0_wp*m24,-3.0_wp/1.0_wp*m24,+1.0_wp/1.0_wp*m24, 0.0_wp, 0.0_wp,  &
              &   +1.0_wp/3.0_wp*m24,-1.0_wp/1.0_wp*m24,+1.0_wp/1.0_wp*m24,-1.0_wp/3.0_wp*m24, 0.0_wp, 0.0_wp/),&
              & (/6,4/)  )
      M1blk = Transpose(-M1blkT1-M1blkT2)

      do i=1,4
         do j=1,6
           M2blk(i,j)= + M1blk(5-i,7-j)
         end do
      end do

      do j = 1,4
        M1blk(1,  j) = M1blk(1,  j) - d1vec(j)
        M2blk(4,7-j) = M2blk(4,7-j) - d1vec(j)
      enddo
      do i = 1,4
        D1blk(i,:) = Pinv_L(  i)*M1blk(i,:)
        D2blk(i,:) = Pinv_L(5-i)*M2blk(i,:)
      enddo

      call CSR_Filler(n,nnz,d2mat,D1blk,D2blk, ia,ja,a)

      a(:) = a(:) / h / h
      call test_error(2,n,nnz,ia,ja,a)

      end subroutine D2_242

! ======================================================================================

      subroutine CSR_Filler(n,nnz,dmat,D1blk,D2blk, ia,ja,a)

      !  Store the Derivative matrix in CSR format

      implicit none

      real(wp),  parameter                     :: tol=1.0e-12_wp

      integer,                   intent(in   ) :: n,nnz
      real(wp),  dimension(:),   intent(in   ) :: dmat
      real(wp),  dimension(:,:), intent(in   ) :: D1blk,D2blk

      integer,   dimension(:),   intent(  out) :: ia
      integer,   dimension(:),   intent(  out) :: ja
      real(wp),  dimension(:),   intent(  out) ::  a

      integer                                  :: i,j,k
      integer                                  :: icnt, jcnt
      real(wp),  allocatable, dimension(:)     :: err

      continue

      icnt  = 0      ; jcnt = 0 

      ia(:) = 0      ; ja(:) = 0      ;
       a(:) = 0.0_wp ;
      ia(1) = 1      ! start at beginning of array

      !  load derivative matrix info into CSR buckets:  Left block boundary

      do i = 1,4
        jcnt = 0 
        do j = 1,6
          if(abs(D1blk(i,j)) >= tol) then
              icnt = icnt + 1 ; jcnt = jcnt + 1 ;
          ja(icnt) = j
           a(icnt) = D1blk(i,j)
          endif
        enddo
        ia(i+1) = ia(i) + jcnt
      enddo
  
      !  load derivative matrix info into CSR buckets:  interior
      do i = 5,n-4
        jcnt = 0 
        do j = 1,5
          if(abs(dmat(j)) >= tol) then
              icnt = icnt + 1 ; jcnt = jcnt + 1 ;
          ja(icnt) = i-3+j
           a(icnt) = dmat(j)
          endif
        enddo
        ia(i+1) = ia(i) + jcnt
      enddo
 
      do i = 1,4
         k = n-4+i
        jcnt = 0 
        do j = 1,6
          if(abs(D2blk(i,j)) >= tol) then
              icnt = icnt + 1 ; jcnt = jcnt + 1 ;
          ja(icnt) = n-6+j
           a(icnt) = D2blk(i,j)
          endif
        enddo
        ia(k+1) = ia(k) + jcnt
      enddo
      if(icnt /= nnz) then
        write(*,*)'dimension of nnz buckets is incorrect: stopping'
        write(*,*)'icnt, nnz', icnt, nnz
        stop
      endif

      end subroutine CSR_Filler

! ======================================================================================

      subroutine test_error(order,n,nnz,ia,ja,a)

      implicit none

      integer,                   intent(in) :: order, n, nnz
      integer,   dimension(:),   intent(in) :: ia
      integer,   dimension(:),   intent(in) :: ja
      real(wp),  dimension(:),   intent(in) ::  a
      integer                               ::  i

      real(wp),  allocatable, dimension(:)  :: err,  x0_vec ,  x1_vec ,   x2_vec,   x3_vec
      real(wp),  allocatable, dimension(:)  ::     d1x0_vec ,d1x1_vec , d1x2_vec, d1x3_vec
      real(wp),  allocatable, dimension(:)  ::     d1x0T_vec,d1x1T_vec,d1x2T_vec,d1x3T_vec
      real(wp),  allocatable, dimension(:)  ::      d2x0_vec, d2x1_vec, d2x2_vec, d2x3_vec
      real(wp),  allocatable, dimension(:)  ::     d2x0T_vec,d2x1T_vec,d2x2T_vec,d2x3T_vec

      real(wp)                              :: tnorm, x

      continue

      allocate(  x0_vec(n),  x1_vec(n),  x2_vec(n),  x3_vec(n))
      allocate(d1x0_vec(n) ,d1x1_vec(n) ,d1x2_vec(n) ,d1x3_vec(n) )
      allocate(d1x0T_vec(n),d1x1T_vec(n),d1x2T_vec(n),d1x3T_vec(n))
      allocate(d2x0_vec(n) ,d2x1_vec(n) ,d2x2_vec(n) ,d2x3_vec(n) )
      allocate(d2x0T_vec(n),d2x1T_vec(n),d2x2T_vec(n),d2x3T_vec(n))
      allocate(err(n))

      do i = 1,n
         x = 1.0_wp*(i-1)/(n-1)
        x0_vec(i) = 1.0_wp       ; d1x0_vec(i) = 0.0_wp     ; d2x0_vec(i) = 0.0_wp
        x1_vec(i) = 1.0_wp*x     ; d1x1_vec(i) = 1.0_wp     ; d2x1_vec(i) = 0.0_wp
        x2_vec(i) = 1.0_wp*x*x   ; d1x2_vec(i) = 2.0_wp*x   ; d2x2_vec(i) = 2.0_wp
        x3_vec(i) = 1.0_wp*x*x*x ; d1x3_vec(i) = 3.0_wp*x*x ; d2x3_vec(i) = 6.0_wp*x
      enddo

      if(order == 1) then
         call amux_local (n, x0_vec,d1x0T_vec, a,ja,ia)
         call amux_local (n, x1_vec,d1x1T_vec, a,ja,ia)
         call amux_local (n, x2_vec,d1x2T_vec, a,ja,ia)
         call amux_local (n, x3_vec,d1x3T_vec, a,ja,ia)
         err(:) = d1x0_vec(:) - d1x0T_vec(:) &
                + d1x1_vec(:) - d1x1T_vec(:) &
                + d1x2_vec(:) - d1x2T_vec(:) !&
                !+ d1x3_vec(:) - d1x3T_vec(:)
         tnorm = maxval(err)
!         write(*,*)'error in  first derivative',tnorm
!         if(tnorm >= tol) write(*,*)'maxerr',maxval(err)
      elseif(order == 2) then
         call amux_local (n, x0_vec,d2x0T_vec, a,ja,ia)
         call amux_local (n, x1_vec,d2x1T_vec, a,ja,ia)
         call amux_local (n, x2_vec,d2x2T_vec, a,ja,ia)
         call amux_local (n, x3_vec,d2x3T_vec, a,ja,ia)

         err(:) = d2x0_vec(:) - d2x0T_vec(:) &
                + d2x1_vec(:) - d2x1T_vec(:) &
                + d2x2_vec(:) - d2x2T_vec(:) !&
                !+ d2x3_vec(:) - d2x3T_vec(:)
         tnorm = maxval(err)
!         write(*,*)'error in second derivative',tnorm
!         if(tnorm >= tol) write(*,*)'maxerr',maxval(err)
      endif


      end subroutine test_error

! ======================================================================================

      subroutine amux_local (n, x, y, a,ja,ia)

        implicit none

        real(wp), dimension(:), intent(in   ) :: x,a
        real(wp), dimension(:), intent(  out) :: y
        integer,                intent(in   ) :: n
        integer, dimension(:),  intent(in   ) :: ja,ia

        !-----------------------------------------------------------------------
        !         A times a vector
        !----------------------------------------------------------------------- 
        ! multiplies a matrix by a vector using the dot product form
        ! Matrix A is stored in compressed sparse row storage.
        !
        ! on entry:
        !----------
        ! n     = row dimension of A
        ! x     = real array of length equal to the column dimension of
        !         the A matrix.
        ! a, ja,
        !    ia = input matrix in compressed sparse row format.
        !
        ! on return:
        !-----------
        ! y     = real array of length n, containing the product y=Ax
        !
        !-----------------------------------------------------------------------
        ! local variables
    
        real(wp) :: t
        integer  :: i, k
            
        do i = 1,n
          t = 0.0_wp        !     compute the inner product of row i with vector x
          do k=ia(i), ia(i+1)-1
            t = t + a(k)*x(ja(k))
          enddo
          y(i) = t          !     store result in y(i) 
        enddo

      end subroutine amux_local


      end module SBP_Coef_Module
