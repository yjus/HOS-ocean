MODULE read_files
!
! This module contains the input related routines
!  Subroutines :    read_3d
!                   read_modes
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
!    Copyright (C) 2014 - LHEEA Lab., Ecole Centrale de Nantes, UMR CNRS 6598
!
!    This program is part of HOS-ocean
!
!    HOS-ocean is free software: you can redistribute it and/or modify
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
USE variables_3d
!
IMPLICIT NONE
!
!
!
CONTAINS
!
!
!
SUBROUTINE init_read_3d(filename,i_unit,tecplot,n1,n2,x,y,eta,phis,dt_out)
!
! Initialize data from 3D free surface file generated by HOS-ocean
!
IMPLICIT NONE
!
CHARACTER(LEN=*), INTENT(IN) :: filename
INTEGER, INTENT(IN)          :: tecplot,i_unit
!
INTEGER, INTENT(OUT)         :: n1,n2
REAL(RP), INTENT(OUT)        :: dt_out
!
REAL(RP), ALLOCATABLE, DIMENSION(:), INTENT(OUT)   :: x,y
REAL(RP), ALLOCATABLE, DIMENSION(:,:), INTENT(OUT) :: eta, phis
!
! Local variables
CHARACTER(LEN=20) :: test
CHARACTER(LEN=4)  :: test2
REAL(RP)          :: time
INTEGER           :: i1,i2
!
!
OPEN(i_unit,file=filename,status='unknown')
! Header of the file
DO i1=1,n_hdr
    READ(i_unit,'(1A)')
ENDDO
!
! Time = 0
!
IF (tecplot == 11) THEN
    READ(i_unit,103) test,time,test2,n1,test2,n2
ELSE
    PRINT*, 'This has to be done'
    stop
ENDIF
dt_out = time
!
! Allocate x and y vectors and eta, phis
ALLOCATE(x(n1),y(n2),eta(n1,n2), phis(n1,n2))
!
DO i2=1,n2
    DO i1=1,n1
        READ(i_unit,102) x(i1), y(i2), eta(i1,i2), phis(i1,i2)
    ENDDO
ENDDO
!
! Next time step to evaluate dt_out
!
IF (tecplot == 11) THEN
    READ(i_unit,'(A,F9.2)') test, time
    BACKSPACE(i_unit) ! Going back to previous line
ELSE
    PRINT*, 'This has to be done'
    stop
ENDIF
!
! Define the time step of outputs in filename
dt_out = time-dt_out
!
102 FORMAT(3(ES12.5,1X),ES12.5)
103 FORMAT(A,F9.2,A,I5,A,I5)
!
END SUBROUTINE init_read_3d
!
!
!
SUBROUTINE read_3d(i_unit,tecplot,time_prev,time_cur,dt_out,n1,n2,eta,phis)
!
! Read a 3D free surface file generated by HOS-ocean
!
IMPLICIT NONE
!
!CHARACTER(LEN=*), INTENT(IN)            :: filename
REAL(RP), INTENT(IN)                    :: time_prev,time_cur, dt_out
INTEGER, INTENT(IN)                     :: i_unit,tecplot,n1,n2
REAL(RP), DIMENSION(n1,n2), INTENT(OUT) :: eta, phis
!
! Local variables
REAL(RP) :: time
CHARACTER(LEN=20) :: test
INTEGER  :: i1,i2,istep,nstep,ios
!
! Check that time different from zero
IF (time_cur < dt_out/2.d0) THEN
    PRINT*, 'The CALL to this routine is useless: init_read is sufficient'
    STOP
ENDIF
!
IF (tecplot /= 11) THEN
    PRINT*, 'Other output formats that tecplot 11 have to be done'
    STOP
ENDIF
!
nstep = NINT(time_cur/dt_out)-NINT(time_prev/dt_out) !NINT((time_cur-time_prev)/dt_out)
!
DO istep = 1, nstep-1
    READ(i_unit,'(1A)',IOSTAT=ios)
    IF (ios /= 0) THEN
        PRINT*, 'Time is larger than maximum time in: ', file_3d
        PRINT*, 'time max. = ', (istep-2)*dt_out
        STOP
    ENDIF
    DO i2=1,n2
        DO i1=1,n1
            READ(i_unit,'(1A)')
        ENDDO
    ENDDO
ENDDO
!
! The correct time step
!
READ(i_unit,'(A,F9.2)') test,time
PRINT*, 'time=',time
!
DO i2=1,n2
    DO i1=1,n1
        READ(i_unit,104) eta(i1,i2), phis(i1,i2)
    ENDDO
ENDDO
!
104 FORMAT((ES12.5,1X),ES12.5)
!
END SUBROUTINE read_3d
!
!
!
SUBROUTINE init_read_mod(filename,i_unit,n1,n2,dt_out,T_stop,xlen,ylen,depth,g,L,T)
!
! Initialize data from volumic mode description generated by HOS-ocean
!
IMPLICIT NONE
!
CHARACTER(LEN=*), INTENT(IN) :: filename
INTEGER, INTENT(IN)          :: i_unit
!
INTEGER, INTENT(OUT)         :: n1,n2
REAL(RP), INTENT(OUT)        :: dt_out,T_stop,xlen,ylen,depth,g,L,T
!
! Local variables
REAL(RP) :: x1, x2
!
! We will look at first eight variables written on 18 characters
OPEN(i_unit,file=filename,status='OLD', FORM='FORMATTED', ACCESS='DIRECT',RECL=18*10)
READ(i_unit,'(10(ES17.10,1X))',REC=1) x1, x2, dt_out, T_stop, xlen, ylen, depth, g, L, T
!
n1 = NINT(x1)
n2 = NINT(x2)
!
CLOSE(i_unit)
!
END SUBROUTINE init_read_mod
!
!
!
SUBROUTINE read_mod(filename,i_unit,time,dt_out,n1o2p1,n2,modesspecx,modesspecy,modesspecz,modesspect,modesFS,modesFSt)
!
! Initialize data from volumic mode description generated by HOS-ocean
!
!
IMPLICIT NONE
!
CHARACTER(LEN=*), INTENT(IN) :: filename
INTEGER, INTENT(IN)          :: i_unit, n1o2p1, n2
REAL(RP), INTENT(IN)         :: time, dt_out
!
COMPLEX(CP), INTENT(OUT), DIMENSION(n1o2p1,n2) :: modesspecx,modesspecy,modesspecz,modesspect,modesFS,modesFSt
!
! Local variables
INTEGER :: i1, i2, it
!
! We read the specific records corresponding to time
!
it = NINT(time/dt_out)+1
!
OPEN(i_unit,file=filename,status='OLD', FORM='FORMATTED', ACCESS='DIRECT',RECL=18*(2*n1o2p1))
!
DO i2=1,n2
    READ(i_unit,'(5000(ES17.10,1X))',REC=((it)*n2*6)+1+6*(i2-1)) (modesspecx(i1,i2), i1=1,n1o2p1)
    READ(i_unit,'(5000(ES17.10,1X))',REC=((it)*n2*6)+2+6*(i2-1)) (modesspecy(i1,i2), i1=1,n1o2p1)
    READ(i_unit,'(5000(ES17.10,1X))',REC=((it)*n2*6)+3+6*(i2-1)) (modesspecz(i1,i2), i1=1,n1o2p1)
    READ(i_unit,'(5000(ES17.10,1X))',REC=((it)*n2*6)+4+6*(i2-1)) (modesspect(i1,i2), i1=1,n1o2p1)
    READ(i_unit,'(5000(ES17.10,1X))',REC=((it)*n2*6)+5+6*(i2-1)) (modesFS(i1,i2)   , i1=1,n1o2p1)
    READ(i_unit,'(5000(ES17.10,1X))',REC=((it)*n2*6)+6+6*(i2-1)) (modesFSt(i1,i2)  , i1=1,n1o2p1)
ENDDO
!
CLOSE(i_unit)
!
END SUBROUTINE read_mod
!
!
!
END MODULE read_files
