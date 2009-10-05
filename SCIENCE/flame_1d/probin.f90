! DO NOT EDIT THIS FILE!!!
!
! This file (probin.f90) is automatically generated by write_probin.py at
! compile-time based on the contents of _parameters and probin.template,
! and any problem-specific _parameters files.
!
! To add a runtime parameter, do so by editting the appropriate _parameters
! file.

! This module stores the runtime parameters.  The probin_init() routine is
! used to initialize the runtime parameters

module probin_module

  use bl_types
  use bl_space
  use pred_parameters
  use multifab_module, only: multifab_set_alltoallv
  use cluster_module
  use layout_module

  implicit none


  character (len=256), save :: model_file
  real (kind=dp_t), save :: stop_time
  real (kind=dp_t), save :: prob_lo_x
  real (kind=dp_t), save :: prob_lo_y
  real (kind=dp_t), save :: prob_lo_z
  real (kind=dp_t), save :: prob_hi_x
  real (kind=dp_t), save :: prob_hi_y
  real (kind=dp_t), save :: prob_hi_z
  integer, save :: max_step
  integer, save :: plot_int
  real (kind=dp_t), save :: plot_deltat
  integer, save :: chk_int
  integer, save :: init_iter
  integer, save :: init_divu_iter
  real (kind=dp_t), save :: cflfac
  real (kind=dp_t), save :: init_shrink
  character (len=256), save :: test_set
  integer, save :: restart
  logical, save :: do_initial_projection
  integer, save :: bcx_lo
  integer, save :: bcx_hi
  integer, save :: bcy_lo
  integer, save :: bcy_hi
  integer, save :: bcz_lo
  integer, save :: bcz_hi
  logical, save :: pmask_x
  logical, save :: pmask_y
  logical, save :: pmask_z
  integer, save :: verbose
  integer, save :: mg_verbose
  integer, save :: cg_verbose
  integer, save :: hg_bottom_solver
  integer, save :: mg_bottom_solver
  integer, save :: max_mg_bottom_nlevels
  logical, save :: do_sponge
  real (kind=dp_t), save :: sponge_kappa
  real (kind=dp_t), save :: sponge_center_density
  real (kind=dp_t), save :: sponge_start_factor
  logical, save :: hg_dense_stencil
  real (kind=dp_t), save :: anelastic_cutoff
  real (kind=dp_t), save :: base_cutoff_density
  real (kind=dp_t), save :: buoyancy_cutoff_factor
  real (kind=dp_t), save :: dpdt_factor
  integer, save :: spherical_in
  integer, save :: dm_in
  logical, save :: perturb_model
  logical, save :: plot_spec
  logical, save :: plot_trac
  logical, save :: plot_base
  character (len=256), save :: plot_base_name
  character (len=256), save :: check_base_name
  logical, save :: evolve_base_state
  logical, save :: do_smallscale
  logical, save :: use_thermal_diffusion
  integer, save :: temp_diffusion_formulation
  integer, save :: thermal_diffusion_type
  logical, save :: do_eos_h_above_cutoff
  integer, save :: enthalpy_pred_type
  real (kind=dp_t), save :: max_dt_growth
  real (kind=dp_t), save :: fixed_dt
  logical, save :: do_burning
  real (kind=dp_t), save :: grav_const
  logical, save :: use_eos_coulomb
  real (kind=dp_t), save :: small_temp
  real (kind=dp_t), save :: small_dens
  logical, save :: use_delta_gamma1_term
  logical, save :: use_etarho
  integer, save :: slope_order
  integer, save :: s0_interp_type
  integer, save :: w0_interp_type
  integer, save :: s0mac_interp_type
  integer, save :: w0mac_interp_type
  integer, save :: nOutFiles
  logical, save :: lUsingNFiles
  logical, save :: use_tfromp
  logical, save :: single_prec_plotfiles
  logical, save :: use_soundspeed_firstdt
  logical, save :: use_divu_firstdt
  logical, save :: do_alltoallv
  logical, save :: the_knapsack_verbosity
  integer, save :: ppm_type
  integer, save :: beta_type
  integer, save :: max_levs
  integer, save :: max_grid_size
  integer, save :: max_grid_size_base
  integer, save :: regrid_int
  integer, save :: ref_ratio
  integer, save :: n_cellx
  integer, save :: n_celly
  integer, save :: n_cellz
  integer, save :: drdxfac
  integer, save :: the_sfc_threshold
  integer, save :: the_layout_verbosity
  integer, save :: the_copy_cache_max
  real (kind=dp_t), save :: min_eff
  integer, save :: min_width
  real (kind=dp_t), save :: rotational_frequency
  real (kind=dp_t), save :: co_latitude
  real (kind=dp_t), save :: rotation_radius
  character (len=256), save :: job_name
  character (len=256), save :: burner_threshold_species
  real (kind=dp_t), save :: burner_threshold_cutoff
  real (kind=dp_t), save :: dens_fuel
  real (kind=dp_t), save :: temp_fuel
  real (kind=dp_t), save :: xc12_fuel
  real (kind=dp_t), save :: vel_fuel
  real (kind=dp_t), save :: temp_ash
  real (kind=dp_t), save :: interface_pos_frac
  real (kind=dp_t), save :: smooth_len_frac
  real (kind=dp_t), save :: XC12_ref_threshold
  logical, save :: do_average_burn
  real (kind=dp_t), save :: transverse_tol


  logical, save :: pmask_xyz(MAX_SPACEDIM)

  real(dp_t), save         :: burning_cutoff_density  ! note: presently not runtime parameter


  ! These will be allocated and defined below
  logical,    allocatable, save :: edge_nodal_flag(:,:)
  logical,    allocatable, save :: nodal(:)
  logical,    allocatable, save :: pmask(:)
  real(dp_t), allocatable, save :: prob_lo(:)
  real(dp_t), allocatable, save :: prob_hi(:)


  namelist /probin/ model_file
  namelist /probin/ stop_time
  namelist /probin/ prob_lo_x
  namelist /probin/ prob_lo_y
  namelist /probin/ prob_lo_z
  namelist /probin/ prob_hi_x
  namelist /probin/ prob_hi_y
  namelist /probin/ prob_hi_z
  namelist /probin/ max_step
  namelist /probin/ plot_int
  namelist /probin/ plot_deltat
  namelist /probin/ chk_int
  namelist /probin/ init_iter
  namelist /probin/ init_divu_iter
  namelist /probin/ cflfac
  namelist /probin/ init_shrink
  namelist /probin/ test_set
  namelist /probin/ restart
  namelist /probin/ do_initial_projection
  namelist /probin/ bcx_lo
  namelist /probin/ bcx_hi
  namelist /probin/ bcy_lo
  namelist /probin/ bcy_hi
  namelist /probin/ bcz_lo
  namelist /probin/ bcz_hi
  namelist /probin/ pmask_x
  namelist /probin/ pmask_y
  namelist /probin/ pmask_z
  namelist /probin/ verbose
  namelist /probin/ mg_verbose
  namelist /probin/ cg_verbose
  namelist /probin/ hg_bottom_solver
  namelist /probin/ mg_bottom_solver
  namelist /probin/ max_mg_bottom_nlevels
  namelist /probin/ do_sponge
  namelist /probin/ sponge_kappa
  namelist /probin/ sponge_center_density
  namelist /probin/ sponge_start_factor
  namelist /probin/ hg_dense_stencil
  namelist /probin/ anelastic_cutoff
  namelist /probin/ base_cutoff_density
  namelist /probin/ buoyancy_cutoff_factor
  namelist /probin/ dpdt_factor
  namelist /probin/ spherical_in
  namelist /probin/ dm_in
  namelist /probin/ perturb_model
  namelist /probin/ plot_spec
  namelist /probin/ plot_trac
  namelist /probin/ plot_base
  namelist /probin/ plot_base_name
  namelist /probin/ check_base_name
  namelist /probin/ evolve_base_state
  namelist /probin/ do_smallscale
  namelist /probin/ use_thermal_diffusion
  namelist /probin/ temp_diffusion_formulation
  namelist /probin/ thermal_diffusion_type
  namelist /probin/ do_eos_h_above_cutoff
  namelist /probin/ enthalpy_pred_type
  namelist /probin/ max_dt_growth
  namelist /probin/ fixed_dt
  namelist /probin/ do_burning
  namelist /probin/ grav_const
  namelist /probin/ use_eos_coulomb
  namelist /probin/ small_temp
  namelist /probin/ small_dens
  namelist /probin/ use_delta_gamma1_term
  namelist /probin/ use_etarho
  namelist /probin/ slope_order
  namelist /probin/ s0_interp_type
  namelist /probin/ w0_interp_type
  namelist /probin/ s0mac_interp_type
  namelist /probin/ w0mac_interp_type
  namelist /probin/ nOutFiles
  namelist /probin/ lUsingNFiles
  namelist /probin/ use_tfromp
  namelist /probin/ single_prec_plotfiles
  namelist /probin/ use_soundspeed_firstdt
  namelist /probin/ use_divu_firstdt
  namelist /probin/ do_alltoallv
  namelist /probin/ the_knapsack_verbosity
  namelist /probin/ ppm_type
  namelist /probin/ beta_type
  namelist /probin/ max_levs
  namelist /probin/ max_grid_size
  namelist /probin/ max_grid_size_base
  namelist /probin/ regrid_int
  namelist /probin/ ref_ratio
  namelist /probin/ n_cellx
  namelist /probin/ n_celly
  namelist /probin/ n_cellz
  namelist /probin/ drdxfac
  namelist /probin/ the_sfc_threshold
  namelist /probin/ the_layout_verbosity
  namelist /probin/ the_copy_cache_max
  namelist /probin/ min_eff
  namelist /probin/ min_width
  namelist /probin/ rotational_frequency
  namelist /probin/ co_latitude
  namelist /probin/ rotation_radius
  namelist /probin/ job_name
  namelist /probin/ burner_threshold_species
  namelist /probin/ burner_threshold_cutoff
  namelist /probin/ dens_fuel
  namelist /probin/ temp_fuel
  namelist /probin/ xc12_fuel
  namelist /probin/ vel_fuel
  namelist /probin/ temp_ash
  namelist /probin/ interface_pos_frac
  namelist /probin/ smooth_len_frac
  namelist /probin/ XC12_ref_threshold
  namelist /probin/ do_average_burn
  namelist /probin/ transverse_tol


contains

  subroutine probin_init()

    use f2kcli
    use parallel
    use bc_module
    use bl_IO_module
    use bl_prof_module
    use bl_error_module
    use bl_constants_module
    use knapsack_module
    
    integer    :: narg, farg

    character(len=128) :: fname
    character(len=128) :: probin_env

    logical    :: lexist, need_inputs
    integer    :: i, natonce, myproc, nprocs, nsets, myset, iset, ibuff(1)
    integer    :: wakeuppid, waitforpid, tag, un, ierr
    real(dp_t) :: pistart, piend, pitotal, pistartall, piendall, pitotalall
    real(dp_t) :: pitotal_max, pitotalall_max

    type(bl_prof_timer), save :: bpt

    call build(bpt, "probin_init")

    narg = command_argument_count()

    need_inputs = .true.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! initialize the runtime parameters
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    model_file = "model.hse"
    stop_time = -1.d0
    prob_lo_x = ZERO
    prob_lo_y = ZERO
    prob_lo_z = ZERO
    prob_hi_x = 1.d0
    prob_hi_y = 1.d0
    prob_hi_z = 1.d0
    max_step = 1
    plot_int = 0
    plot_deltat = 0.d0
    chk_int = 0
    init_iter = 4
    init_divu_iter = 4
    cflfac = 0.5d0
    init_shrink = 1.d0
    test_set = ''
    restart = -1
    do_initial_projection = .true.
    bcx_lo = SLIP_WALL
    bcx_hi = SLIP_WALL
    bcy_lo = SLIP_WALL
    bcy_hi = SLIP_WALL
    bcz_lo = SLIP_WALL
    bcz_hi = SLIP_WALL
    pmask_x = .false.
    pmask_y = .false.
    pmask_z = .false.
    verbose = 0
    mg_verbose = 0
    cg_verbose = 0
    hg_bottom_solver = -1
    mg_bottom_solver = -1
    max_mg_bottom_nlevels = 1000
    do_sponge = .false.
    sponge_kappa = 10.d0
    sponge_center_density = 3.d6
    sponge_start_factor = 3.333d0
    hg_dense_stencil = .true.
    anelastic_cutoff = 3.d6
    base_cutoff_density = 3.d6
    buoyancy_cutoff_factor = 5.0
    dpdt_factor = 0.d0
    spherical_in = 0
    dm_in = 2
    perturb_model = .false.
    plot_spec = .true.
    plot_trac = .false.
    plot_base = .false.
    plot_base_name = "plt"
    check_base_name = "chk"
    evolve_base_state = .true.
    do_smallscale = .false.
    use_thermal_diffusion = .false.
    temp_diffusion_formulation = 2
    thermal_diffusion_type = 1
    do_eos_h_above_cutoff = .true.
    enthalpy_pred_type = predict_rhohprime
    max_dt_growth = 1.1d0
    fixed_dt = -1.0d0
    do_burning = .true.
    grav_const = -1.5d10
    use_eos_coulomb = .true.
    small_temp = 5.d6
    small_dens = 1.d-5
    use_delta_gamma1_term = .false.
    use_etarho = .true.
    slope_order = 4
    s0_interp_type = 3
    w0_interp_type = 2
    s0mac_interp_type = 1
    w0mac_interp_type = 1
    nOutFiles = 64
    lUsingNFiles = .true.
    use_tfromp = .false.
    single_prec_plotfiles = .false.
    use_soundspeed_firstdt = .false.
    use_divu_firstdt = .false.
    do_alltoallv = .false.
    the_knapsack_verbosity = .false.
    ppm_type = 1
    beta_type = 1
    max_levs = 1
    max_grid_size = 64
    max_grid_size_base = -1
    regrid_int = -1
    ref_ratio = 2
    n_cellx = -1
    n_celly = -1
    n_cellz = -1
    drdxfac = 1
    the_sfc_threshold = 5
    the_layout_verbosity = 0
    the_copy_cache_max = 50
    min_eff = 0.7d0
    min_width = 16
    rotational_frequency = ZERO
    co_latitude = ZERO
    rotation_radius = 1.0d6
    job_name = ""
    burner_threshold_species = ""
    burner_threshold_cutoff = 1.d-10
    dens_fuel = 1.d8
    temp_fuel = 1.d8
    xc12_fuel = 0.5d0
    vel_fuel = 1.d6
    temp_ash = 3.d9
    interface_pos_frac = 0.5
    smooth_len_frac = 0.025
    XC12_ref_threshold = 1.d-3
    do_average_burn = .false.
    transverse_tol = 1.d-7


    !
    ! Don't have more than 64 processes trying to read from disk at once.
    !
    natonce = min(64,parallel_nprocs())
    myproc  = parallel_myproc()
    nprocs  = parallel_nprocs()
    nsets   = ((nprocs + (natonce - 1)) / natonce)
    myset   = (myproc / natonce)

    pistartall = parallel_wtime()

    do iset = 0, nsets-1

       if (myset .eq. iset) then

          pistart = parallel_wtime()
          
          call get_environment_variable('PROBIN', probin_env, status = ierr)
          if ( need_inputs .AND. ierr == 0 ) then
             un = unit_new()
             open(unit=un, file = probin_env, status = 'old', action = 'read')
             read(unit=un, nml = probin)
             close(unit=un)
             need_inputs = .false.
          end if

          farg = 1
          if ( need_inputs .AND. narg >= 1 ) then
             call get_command_argument(farg, value = fname)
             inquire(file = fname, exist = lexist )
             if ( lexist ) then
                farg = farg + 1
                un = unit_new()
                open(unit=un, file = fname, status = 'old', action = 'read')
                read(unit=un, nml = probin)
                close(unit=un)
                need_inputs = .false.
             end if
          end if

          inquire(file = 'inputs_varden', exist = lexist)
          if ( need_inputs .AND. lexist ) then
             un = unit_new()
             open(unit=un, file = 'inputs_varden', status = 'old', action = 'read')
             read(unit=un, nml = probin)
             close(unit=un)
             need_inputs = .false.
          end if

          piend = parallel_wtime()

          ibuff(1)  = 0
          wakeuppid = myproc + natonce
          tag       = mod(myproc,natonce)
          
          if (wakeuppid < nprocs) call parallel_send(ibuff, wakeuppid, tag)

       end if

      if (myset .eq. (iset + 1)) then

         tag        = mod(myproc,natonce)
         waitforpid = myproc - natonce

         call parallel_recv(ibuff, waitforpid, tag)
      endif

    end do

    piendall   = parallel_wtime()
    pitotal    = piend - pistart
    pitotalall = piendall - pistartall

    call parallel_reduce(pitotal_max,    pitotal,    MPI_MAX, &
                         proc = parallel_IOProcessorNode())
    call parallel_reduce(pitotalall_max, pitotalall, MPI_MAX, &
                         proc = parallel_IOProcessorNode())

    if (parallel_IOProcessor()) then
      print*, "PROBINIT max time   = ", pitotal_max
      print*, "PROBINIT total time = ", pitotalall_max
    endif

    pmask_xyz = (/pmask_x, pmask_y, pmask_z/)
    
    do while ( farg <= narg )
       call get_command_argument(farg, value = fname)
       select case (fname)


       case ('--model_file')
          farg = farg + 1
          call get_command_argument(farg, value = model_file)

       case ('--stop_time')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) stop_time

       case ('--prob_lo_x')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) prob_lo_x

       case ('--prob_lo_y')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) prob_lo_y

       case ('--prob_lo_z')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) prob_lo_z

       case ('--prob_hi_x')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) prob_hi_x

       case ('--prob_hi_y')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) prob_hi_y

       case ('--prob_hi_z')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) prob_hi_z

       case ('--max_step')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) max_step

       case ('--plot_int')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) plot_int

       case ('--plot_deltat')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) plot_deltat

       case ('--chk_int')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) chk_int

       case ('--init_iter')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) init_iter

       case ('--init_divu_iter')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) init_divu_iter

       case ('--cflfac')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) cflfac

       case ('--init_shrink')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) init_shrink

       case ('--test_set')
          farg = farg + 1
          call get_command_argument(farg, value = test_set)

       case ('--restart')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) restart

       case ('--do_initial_projection')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) do_initial_projection

       case ('--bcx_lo')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) bcx_lo

       case ('--bcx_hi')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) bcx_hi

       case ('--bcy_lo')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) bcy_lo

       case ('--bcy_hi')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) bcy_hi

       case ('--bcz_lo')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) bcz_lo

       case ('--bcz_hi')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) bcz_hi

       case ('--pmask_x')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) pmask_x

       case ('--pmask_y')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) pmask_y

       case ('--pmask_z')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) pmask_z

       case ('--verbose')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) verbose

       case ('--mg_verbose')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) mg_verbose

       case ('--cg_verbose')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) cg_verbose

       case ('--hg_bottom_solver')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) hg_bottom_solver

       case ('--mg_bottom_solver')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) mg_bottom_solver

       case ('--max_mg_bottom_nlevels')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) max_mg_bottom_nlevels

       case ('--do_sponge')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) do_sponge

       case ('--sponge_kappa')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) sponge_kappa

       case ('--sponge_center_density')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) sponge_center_density

       case ('--sponge_start_factor')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) sponge_start_factor

       case ('--hg_dense_stencil')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) hg_dense_stencil

       case ('--anelastic_cutoff')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) anelastic_cutoff

       case ('--base_cutoff_density')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) base_cutoff_density

       case ('--buoyancy_cutoff_factor')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) buoyancy_cutoff_factor

       case ('--dpdt_factor')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) dpdt_factor

       case ('--spherical_in')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) spherical_in

       case ('--dm_in')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) dm_in

       case ('--perturb_model')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) perturb_model

       case ('--plot_spec')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) plot_spec

       case ('--plot_trac')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) plot_trac

       case ('--plot_base')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) plot_base

       case ('--plot_base_name')
          farg = farg + 1
          call get_command_argument(farg, value = plot_base_name)

       case ('--check_base_name')
          farg = farg + 1
          call get_command_argument(farg, value = check_base_name)

       case ('--evolve_base_state')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) evolve_base_state

       case ('--do_smallscale')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) do_smallscale

       case ('--use_thermal_diffusion')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) use_thermal_diffusion

       case ('--temp_diffusion_formulation')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) temp_diffusion_formulation

       case ('--thermal_diffusion_type')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) thermal_diffusion_type

       case ('--do_eos_h_above_cutoff')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) do_eos_h_above_cutoff

       case ('--enthalpy_pred_type')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) enthalpy_pred_type

       case ('--max_dt_growth')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) max_dt_growth

       case ('--fixed_dt')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) fixed_dt

       case ('--do_burning')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) do_burning

       case ('--grav_const')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) grav_const

       case ('--use_eos_coulomb')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) use_eos_coulomb

       case ('--small_temp')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) small_temp

       case ('--small_dens')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) small_dens

       case ('--use_delta_gamma1_term')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) use_delta_gamma1_term

       case ('--use_etarho')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) use_etarho

       case ('--slope_order')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) slope_order

       case ('--s0_interp_type')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) s0_interp_type

       case ('--w0_interp_type')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) w0_interp_type

       case ('--s0mac_interp_type')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) s0mac_interp_type

       case ('--w0mac_interp_type')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) w0mac_interp_type

       case ('--nOutFiles')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) nOutFiles

       case ('--lUsingNFiles')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) lUsingNFiles

       case ('--use_tfromp')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) use_tfromp

       case ('--single_prec_plotfiles')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) single_prec_plotfiles

       case ('--use_soundspeed_firstdt')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) use_soundspeed_firstdt

       case ('--use_divu_firstdt')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) use_divu_firstdt

       case ('--do_alltoallv')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) do_alltoallv

       case ('--the_knapsack_verbosity')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) the_knapsack_verbosity

       case ('--ppm_type')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) ppm_type

       case ('--beta_type')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) beta_type

       case ('--max_levs')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) max_levs

       case ('--max_grid_size')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) max_grid_size

       case ('--max_grid_size_base')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) max_grid_size_base

       case ('--regrid_int')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) regrid_int

       case ('--ref_ratio')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) ref_ratio

       case ('--n_cellx')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) n_cellx

       case ('--n_celly')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) n_celly

       case ('--n_cellz')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) n_cellz

       case ('--drdxfac')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) drdxfac

       case ('--the_sfc_threshold')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) the_sfc_threshold

       case ('--the_layout_verbosity')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) the_layout_verbosity

       case ('--the_copy_cache_max')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) the_copy_cache_max

       case ('--min_eff')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) min_eff

       case ('--min_width')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) min_width

       case ('--rotational_frequency')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) rotational_frequency

       case ('--co_latitude')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) co_latitude

       case ('--rotation_radius')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) rotation_radius

       case ('--job_name')
          farg = farg + 1
          call get_command_argument(farg, value = job_name)

       case ('--burner_threshold_species')
          farg = farg + 1
          call get_command_argument(farg, value = burner_threshold_species)

       case ('--burner_threshold_cutoff')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) burner_threshold_cutoff

       case ('--dens_fuel')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) dens_fuel

       case ('--temp_fuel')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) temp_fuel

       case ('--xc12_fuel')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) xc12_fuel

       case ('--vel_fuel')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) vel_fuel

       case ('--temp_ash')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) temp_ash

       case ('--interface_pos_frac')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) interface_pos_frac

       case ('--smooth_len_frac')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) smooth_len_frac

       case ('--XC12_ref_threshold')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) XC12_ref_threshold

       case ('--do_average_burn')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) do_average_burn

       case ('--transverse_tol')
          farg = farg + 1
          call get_command_argument(farg, value = fname)
          read(fname, *) transverse_tol



       case ('--')
          farg = farg + 1
          exit

       case default
          if ( .not. parallel_q() ) then
             write(*,*) 'UNKNOWN option = ', fname
             call bl_error("MAIN")
          end if
       end select

       farg = farg + 1
    end do

    pmask_xyz = (/pmask_x, pmask_y, pmask_z/)

    if (max_grid_size_base .eq. -1) then
       max_grid_size_base = max_grid_size
    end if

    if (do_smallscale .and. evolve_base_state) then
       call bl_error("do_smallscale requires evolve_base_state = F")
    end if

    if (do_smallscale .and. beta_type .ne. 3) then
       call bl_error("do_smallscale requires beta_type = 3")
    end if

    ! for the moment, set the cutoff for burning to be base_cutoff_density
    burning_cutoff_density = base_cutoff_density

    ! initialize edge_nodal_flag
    allocate(edge_nodal_flag(dm_in,dm_in))
    edge_nodal_flag = .false.
    do i = 1,dm_in
       edge_nodal_flag(i,i) = .true.
    end do

    ! initialize nodal
    allocate(nodal(dm_in))
    nodal = .true.

    ! initialize pmask
    allocate(pmask(dm_in))
    pmask = .FALSE.
    pmask = pmask_xyz(1:dm_in)

    ! initialize prob_lo and prob_hi
    allocate(prob_lo(dm_in))
    prob_lo(1) = prob_lo_x
    if (dm_in > 1) prob_lo(2) = prob_lo_y
    if (dm_in > 2) prob_lo(3) = prob_lo_z
    allocate(prob_hi(dm_in))
    prob_hi(1) = prob_hi_x
    if (dm_in > 1) prob_hi(2) = prob_hi_y
    if (dm_in > 2) prob_hi(3) = prob_hi_z

    call cluster_set_min_eff(min_eff)
    call cluster_set_minwidth(min_width)

    if (do_alltoallv) call multifab_set_alltoallv(.true.)
    
    call knapsack_set_verbose(the_knapsack_verbosity)

    call layout_set_verbosity(the_layout_verbosity)
    call layout_set_copyassoc_max(the_copy_cache_max)
    call layout_set_sfc_threshold(the_sfc_threshold)

    call destroy(bpt)
    
  end subroutine probin_init

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  subroutine probin_close()

    deallocate(edge_nodal_flag)
    deallocate(nodal)
    deallocate(pmask)
    deallocate(prob_lo)
    deallocate(prob_hi)

  end subroutine probin_close

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

end module probin_module
