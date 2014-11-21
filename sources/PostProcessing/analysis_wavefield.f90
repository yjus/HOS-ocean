MODULE analysis_wavefield
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
!    Copyright (C) 2014 - LHEEA Lab., Ecole Centrale de Nantes, UMR CNRS 6598
!
!    This program is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    This program is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
USE type
USE variables_post_process
!
CONTAINS
!
!
!
SUBROUTINE wave_by_wave(signal,x,n1,n_waves,H_up,L_up,idx_up,H_down,L_down,idx_down,crest,idx_crest,trough,idx_trough)
!
! Wave-by-wave analysis of a periodic signal on n1 point
!
IMPLICIT NONE
!
INTEGER, INTENT(IN)                 :: n1
REAL(RP), DIMENSION(n1), INTENT(IN) :: signal, x
!
! Local variables
INTEGER :: i1
INTEGER, DIMENSION(n1) :: idx_zeros ! indexes of zero-crossings
INTEGER                :: n_zeros, n_waves ! number of zero crossings and waves
INTEGER                :: shift, i_crest, i_trough, i_tmp, j1
! Allocatable variables
INTEGER, ALLOCATABLE, DIMENSION(:), INTENT(INOUT)   :: idx_crest,idx_trough
INTEGER, ALLOCATABLE, DIMENSION(:), INTENT(INOUT)   :: idx_up,idx_down
REAL(RP), ALLOCATABLE, DIMENSION(:), INTENT(INOUT)  :: crest,trough,H_up,H_down,L_up,L_down
!
! Initialize
idx_zeros = 0 ! Necessary since all n1 elements will not be evaluated (only n_zeros)
n_zeros   = 0
!
! First step: locate zero-crossings
DO i1=2,n1
	IF((signal(i1)*signal(i1-1)).LT.0.0_rp) THEN
		n_zeros            = n_zeros+1
		idx_zeros(n_zeros) = i1-1
	ENDIF
ENDDO
IF((signal(1)*signal(n1)).LT.0.0_rp) THEN
	n_zeros            = n_zeros+1
	idx_zeros(n_zeros) = n1
ENDIF
!
! Check if we start with signal>0 (shift=1) or signal<0 (shift=0)?
IF (signal(1) > tiny) THEN
	shift = 1
ELSE
	shift = 0
ENDIF
!
! Number of waves inside the domain
IF(.NOT.iseven(n_zeros)) THEN
  write(*,*) 'n_zeros is not even... there is a problem'
  STOP
ENDIF
n_waves = n_zeros/2
!
! Allocation on the number of waves
!
ALLOCATE(idx_crest(n_waves),idx_trough(n_waves),crest(n_waves),trough(n_waves) &
     , H_up(n_waves), H_down(n_waves), L_up(n_waves), L_down(n_waves) &
     , idx_up(n_waves), idx_down(n_waves))
!
! Evaluate the index of each crest and trough and their amplitudes
DO j1=1,n_waves-1
	i_crest  = (2*j1+1)-shift ! beginning of a crest
	i_trough = (2*j1)-shift   ! beginning of a trough
	! Indexes
	idx_crest(j1)  = idx_zeros(i_crest)-1  + MAXLOC(signal(idx_zeros(i_crest):idx_zeros(i_crest+1)),1)
	idx_trough(j1) = idx_zeros(i_trough)-1 + MINLOC(signal(idx_zeros(i_trough):idx_zeros(i_trough+1)),1)
	! Elevations
	crest(j1)      = MAXVAL(signal(idx_zeros(i_crest):idx_zeros(i_crest+1)),1)
	trough(j1)     = MINVAL(signal(idx_zeros(i_trough):idx_zeros(i_trough+1)),1)
ENDDO
!
! Different cases to treat with periodicity...
!
! Locate maximum of last wave w.r.t. periodic condition
! (n_zeros-shift) gives the last down crossing
! (2-shift) gives the first down-crossing
!IF(MAXVAL(signal(idx_zeros(n_zeros-shift):n1)).GT.(MAXVAL(signal(1:idx_zeros((3)-shift))))) THEN
IF(MAXVAL(signal(idx_zeros(n_zeros-shift):n1),1).GT.(MAXVAL(signal(1:idx_zeros(2-shift)),1))) THEN
  i_tmp               = MAXLOC(signal(idx_zeros(n_zeros-shift):n1),1)
  idx_crest(n_waves)  = idx_zeros(n_zeros-shift)-1+i_tmp
  ! Crest-amplitude
  crest(n_waves)      = MAXVAL(signal(idx_zeros(n_zeros-shift):n1),1)
ELSE
  i_tmp               = MAXLOC(signal(1:idx_zeros(2-shift)),1)
  idx_crest(n_waves)  = n1+i_tmp
  ! Crest-amplitude
  crest(n_waves)      = MAXVAL(signal(1:idx_zeros(2-shift)),1)
ENDIF
!
! Locate minimum of last wave w.r.t. periodic condition
! (n_zeros-shift) gives the last down crossing
! (2-shift) gives the first down-crossing
IF(MINVAL(signal(idx_zeros(n_zeros-shift):n1)).LT.MINVAL(signal(1:idx_zeros(2-shift)))) THEN
  i_tmp                = MINLOC(signal(idx_zeros((2*n_waves)-shift):n1),1)
  idx_trough(n_waves)  = idx_zeros(n_zeros-shift)-1+i_tmp
  ! Trough-amplitude
  trough(n_waves)      = MINVAL(signal(idx_zeros(n_zeros-shift):n1),1)
ELSE
  i_tmp                = MINLOC(signal(1:idx_zeros(2-shift)),1)
  idx_trough(n_waves)  = n1+i_tmp
  ! Trough-amplitude
  trough(n_waves)      = MINVAL(signal(1:idx_zeros(2-shift)),1)
ENDIF
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
DO j1=1,n_waves-2
	i_crest  = (2*j1+1)-shift ! beginning of a crest
	i_trough = (2*j1)-shift   ! beginning of a trough
	! Heights up/down crossing
	H_up(j1)       = crest(j1) - trough(j1+1)
	H_down(j1)     = crest(j1) - trough(j1)
	! Lengths up/down crossing
	L_up(j1)    = x(idx_zeros(i_crest+2))-x(idx_zeros(i_crest))
	L_down(j1)  = x(idx_zeros(i_trough+2))-x(idx_zeros(i_trough))
	! Indexes up-crossing and down-crossing wave beginning	
	idx_up(j1)   = idx_zeros(i_crest)
	idx_down(j1) = idx_zeros(i_trough)
ENDDO
!
! Specific treatment of 2 last waves which may encounter periodic boundary
! n_waves-1
j1 = n_waves-1
i_crest  = (2*j1+1)-shift ! beginning of a crest
i_trough = (2*j1)-shift   ! beginning of a trough
! Heights and lengths up/down crossing
H_up(j1)       = crest(j1) - trough(j1+1)
H_down(j1)     = crest(j1) - trough(j1)
IF (shift == 1) THEN
	L_up(j1)    = x(idx_zeros(i_crest+2))-x(idx_zeros(i_crest))
ELSE
	L_up(j1)    = x(n1)-x(idx_zeros(i_crest))+x(idx_zeros(1))
ENDIF
!
L_down(j1)     = x(idx_zeros(i_trough+2))-x(idx_zeros(i_trough))
! Indexes up-crossing and down-crossing wave beginning	
idx_up(j1)   = idx_zeros(i_crest)
idx_down(j1) = idx_zeros(i_trough)
!
! n_waves
j1 = n_waves
i_crest  = (2*j1+1)-shift ! beginning of a crest
i_trough = (2*j1)-shift   ! beginning of a trough
!
H_up(j1)       = crest(j1) - trough(1)
H_down(j1)     = crest(j1) - trough(j1)
! Longueurs up/down crossing
IF (shift == 1) THEN
	L_up(j1)  = x(n1)-x(idx_zeros(i_crest))+x(idx_zeros(1))
	! Index up-crossing wave beginning	
	idx_up(j1) = idx_zeros(i_crest)
ELSE
	L_up(j1)  = x(idx_zeros(3))-x(idx_zeros(1))
	! Index up-crossing wave beginning	
	idx_up(j1) = idx_zeros(1)
ENDIF
!
L_down(j1)     = x(n1)-x(idx_zeros(i_trough))+x(idx_zeros(2-shift))
! Index down-crossing wave beginning	
idx_down(j1) = idx_zeros(i_trough)
!
END SUBROUTINE wave_by_wave
!
!
!
SUBROUTINE H_onethird(H,n_waves,H_1_3rd)
!
! Computation of H_1/3
!
REAL(RP), DIMENSION(n_waves), INTENT(IN) :: H
INTEGER, INTENT(IN)                      :: n_waves
REAL(RP), INTENT(OUT)                    :: H_1_3rd
!
! Local variables
REAL(RP), DIMENSION(n_waves) :: H_sorted
INTEGER                      :: twothird
!
H_sorted = H
twothird = NINT(2.0_rp/3.0_rp*n_waves)
!
! Sorting in increasing order
!
CALL sort_shell(H_sorted)
!
H_1_3rd = SUM(H_sorted(twothird:n_waves))/(n_waves-twothird)
!
END SUBROUTINE H_onethird
!
!
!
SUBROUTINE locate_freak(H,L,idx_crest,idx_start,n_waves,x,n1,H_lim,n_freak,H_freak,L_freak,x_freak,idx_freak)
!
! This subroutine locate the freak waves in a given 2D wavefield
!
REAL(RP), DIMENSION(n_waves), INTENT(IN) :: H, L
INTEGER, DIMENSION(n_waves), INTENT(IN)  :: idx_crest, idx_start
INTEGER, INTENT(IN)                      :: n_waves, n1
REAL(RP), DIMENSION(n1), INTENT(IN)      :: x
REAL(RP), INTENT(IN)                     :: H_lim
!
REAL(RP), ALLOCATABLE, DIMENSION(:), INTENT(OUT) :: H_freak, x_freak, L_freak
INTEGER, ALLOCATABLE, DIMENSION(:), INTENT(OUT)  :: idx_freak
INTEGER, INTENT(OUT) :: n_freak
!
! Local variables
INTEGER :: j1, i_freak
!
!
! Number of freak waves
n_freak=0
DO j1=1,n_waves
   IF(H(j1).GT.H_lim) THEN
      n_freak = n_freak + 1
   ENDIF
ENDDO
!
! Allocate freak waves parameters
IF(n_freak.NE.0) THEN
	ALLOCATE(H_freak(n_freak),x_freak(n_freak),L_freak(n_freak), idx_freak(n_freak))
ELSE
	n_freak=1
	ALLOCATE(H_freak(n_freak),x_freak(n_freak),L_freak(n_freak), idx_freak(n_freak))
	n_freak=0
ENDIF
!
i_freak = 0
!
DO j1=1,n_waves
	IF(H(j1).GT.H_lim) THEN
		i_freak                  = i_freak+1
		H_freak(i_freak)         = H(j1)
		L_freak(i_freak)         = L(j1)
		IF (idx_crest(j1).GT.n1) THEN
			x_freak(i_freak)      = x(n1)+x(idx_crest(j1)-n1)
		ELSE
			x_freak(i_freak)      = x(idx_crest(j1))
		ENDIF
		idx_freak(i_freak) = idx_start(j1) ! index of the beginning of the corresponding wave
	ENDIF
ENDDO
!
!
END SUBROUTINE locate_freak
!
!
!
SUBROUTINE sort_shell(arr)
!
! From Numerical Recipies in Fortran
! This routine sorts an array arr into ascending order by Shell's method (diminishing increment 
! sort). arr is replaced on output by its sorted arrangment
IMPLICIT NONE
!
REAL(RP), DIMENSION(:), INTENT(INOUT) :: arr
!
REAL(RP) :: v
INTEGER  :: i,j,inc,n
!
n = SIZE(arr)
inc = 1
!
! Determine the starting increment
DO
   inc = 3*inc+1
   IF (inc > n) exit
ENDDO
!
! Loop over the partial sorts
DO
   inc = inc / 3
   ! Outer loop of straight insertion
   DO i = inc+1,n
       v=arr(i)
       j=i
       ! Inner loop of straight insertion
       DO
           if (arr(j-inc) <= v) exit
           arr(j) = arr(j-inc)
           j=j-inc
           if (j<= inc) exit
       ENDDO
       arr(j)=v
   ENDDO
   if (inc<= 1) exit
ENDDO
!
END SUBROUTINE sort_shell
!
!
!
SUBROUTINE moment(n,data,ave,adev,sdev,var,skew,curt)
!
! From Numerical Recipies in Fortran
! Given an array of data, this routine returns its mean ave, average deviation adev, standard
! deviation sdev, variance var, skewness skew, and kurtosis curt.
!
USE type
!
IMPLICIT NONE
!
REAL(RP), INTENT(OUT) :: ave,adev,sdev,var,skew,curt
INTEGER, INTENT(IN)   :: n
REAL(RP),INTENT(IN)   :: data(n)
!
REAL(RP) :: ep
REAL(RP), DIMENSION(size(data)) :: p,s
!
if (n <= 1) then
   write(*,*) 'ERREUR : moment: n must be at least 2'
   STOP
endif
!
! First pass to get the mean.
!
ave=sum(data(:))/n
!
! Second pass to get the first (absolute), second, third, and
! fourth moments of the deviation from the mean.
!
s(:)=data(:)-ave 
ep=sum(s(:))
adev=sum(abs(s(:)))/n
p(:)=s(:)*s(:)
var=sum(p(:))
p(:)=p(:)*s(:)
skew=sum(p(:))
p(:)=p(:)*s(:)
curt=sum(p(:))
!
! Corrected two-pass formula.
!
var=(var-(ep**2.d0)/n)/REAL(n-1)
!
sdev=sqrt(var)
!
if (ABS(var) > tiny) then
   skew=skew/(n*sdev**3)
   curt=curt/(n*var**2)-3.0_sp
else
   write(*,*) 'ERREUR : moment: no skew or kurtosis when zero variance'
   STOP
end if
!
END SUBROUTINE moment
!
END MODULE analysis_wavefield