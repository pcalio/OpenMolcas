module constants
    implicit none
    private
    public :: r4, r8, i4, i8, dp, MPIArg

    ! Although the constants from iso_fortran_env or `selected_real_kind`
    ! are preferred over non-standard real*8 etc.
    ! We define our standard-conforming kinds to be of same kind as
    ! an example variable of real*8 etc, to maintain backwards
    ! compatibility

    real*4 :: r4_example
    real*8 :: r8_example

    integer*4 :: i4_example
    integer*8 :: i8_example

    integer, parameter :: &
        r4 = kind(r4_example), &
        r8 = kind(r8_example), &
        i4 = kind(i4_example), &
        i8 = kind(i8_example)

    integer, parameter :: MPIArg = i4
    integer, parameter :: dp = r8

end module
