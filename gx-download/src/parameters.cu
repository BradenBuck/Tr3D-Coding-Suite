#include "parameters.h"
#include <netcdf.h>
#include "toml.hpp"
#include <iostream>
#include "version.h"
using namespace std;

Parameters::Parameters() {
  initialized = false;

  // some cuda parameters (not from input file)
  int dev; 
  cudaGetDevice(&dev);
  if (false) printf("device id = %d \n",dev);
}

Parameters::~Parameters() {
  cudaDeviceSynchronize();
  if(initialized) {
    cudaFreeHost(species_h);
  }
}


void Parameters::get_nml_vars(char* filename)
{
  strcpy (run_name, filename);
  char nml_file[263];
  
  strcpy(nml_file, run_name);
  strcat(nml_file, ".in");

  printf(ANSI_COLOR_MAGENTA);

  const auto nml = toml::parse(nml_file);

  repeat = toml::find_or <bool> (nml, "repeat",  false);  
  debug  = toml::find_or <bool> (nml, "debug",   false);

  auto tnml = nml;
  if (nml.contains("Restart")) tnml = toml::find(nml, "Restart");
  
  restart           = toml::find_or <bool>   (tnml, "restart",                 false  );
  save_for_restart  = toml::find_or <bool>   (tnml, "save_for_restart",         true  );
  restart_to_file   = toml::find_or <string> (tnml, "restart_to_file", "newsave.nc"   );  
  restart_from_file = toml::find_or <string> (tnml, "restart_from_file", "oldsave.nc" );  
  scale             = toml::find_or <float>  (tnml, "scale",                      1.0 );
   
  tnml = nml;
  if (nml.contains("Dimensions")) tnml = toml::find(nml, "Dimensions");
  
  nz_in    = toml::find_or <int> (tnml, "ntheta",    32);
  ny_in    = toml::find_or <int> (tnml, "ny",        32);
  nx_in    = toml::find_or <int> (tnml, "nx",        4);
  nm_in    = toml::find_or <int> (tnml, "nhermite",  4);
  nl_in    = toml::find_or <int> (tnml, "nlaguerre", 2);
  nspec_in = toml::find_or <int> (tnml, "nspecies",  1);
  nperiod  = toml::find_or <int> (tnml, "nperiod",   1);
  
  if (nx_in<4) {printf("Warning: Behavior is not guaranteed for nx = %d \n",nx_in);}
  if (ny_in<4) {printf("Warning: Behavior is not guaranteed for ny = %d \n",ny_in);}

  tnml = nml;
  if (nml.contains("Domain")) tnml = toml::find(nml, "Domain");

  y0       = toml::find_or <float>       (tnml, "y0",          10.0  );
  x0       = toml::find_or <float>       (tnml, "x0",          10.0  );
  jtwist   = toml::find_or <int>         (tnml, "jtwist",        -1  );
  Zp       = toml::find_or <int>         (tnml, "zp",             1  );
  boundary = toml::find_or <std::string> (tnml, "boundary", "linked" );
  ExBshear = toml::find_or <bool>        (tnml, "ExBshear",    false );
  g_exb    = toml::find_or <float>       (tnml, "g_exb",         0.0 );
  
  tnml = nml;  
  if (nml.contains("Time")) tnml = toml::find (nml, "Time");

  dt      = toml::find_or <float> (tnml, "dt",          0.05 );
  nstep   = toml::find_or <int>   (tnml, "nstep",   10000    );
  nwrite  = toml::find_or <int>   (tnml, "nwrite",   1000    );
  navg    = toml::find_or <int>   (tnml, "navg",       10    );
  nsave   = toml::find_or <int>   (tnml, "nsave", 2000000    );

  tnml = nml;
  if (nml.contains("Vlasov_Poisson")) tnml = toml::find (nml, "Vlasov_Poisson");
  
  vp                = toml::find_or <bool>  (tnml, "vp",         false );
  vp_closure        = toml::find_or <bool>  (tnml, "vp_closure",  true );
  vp_nu             = toml::find_or <float> (tnml, "vp_nu",       -1.0 );
  vp_nuh            = toml::find_or <float> (tnml, "vp_nuh",      -1.0 );
  vp_alpha          = toml::find_or <int>   (tnml, "vp_alpha",       1 );
  vp_alpha_h        = toml::find_or <int>   (tnml, "vp_alpha_h",     2 );
  
  tnml = nml;
  if (nml.contains("KS")) tnml = toml::find (nml, "KS");
  
  ks                = toml::find_or <bool>  (tnml, "ks",         false );
  write_ks          = toml::find_or <bool>  (tnml, "write_ks",   false );
  eps_ks            = toml::find_or <float> (tnml, "eps_ks",       0.0 );
  ks_t0             = toml::find_or <float> (tnml, "ks_t0",       -1.0 );
  ks_tf             = toml::find_or <float> (tnml, "ks_tf",       -1.0 );
  ks_eps0           = toml::find_or <float> (tnml, "ks_eps0",     -1.0 );
  ks_epsf           = toml::find_or <float> (tnml, "ks_epsf",     -1.0 );

  tnml = nml;
  if (nml.contains("Diagnostics")) tnml = toml::find (nml, "Diagnostics");

  fixed_amplitude   = toml::find_or <bool> (tnml, "fixed_amplitude", false);
  write_omega       = toml::find_or <bool> (tnml, "omega",       false );
  write_free_energy = toml::find_or <bool> (tnml, "free_energy", true  ); if (ks) write_free_energy = false;
  write_fluxes      = toml::find_or <bool> (tnml, "fluxes",      false );
  write_moms        = toml::find_or <bool> (tnml, "moms",        false );
  write_rh          = toml::find_or <bool> (tnml, "rh",          false );
  write_pzt         = toml::find_or <bool> (tnml, "pzt",         false );

  write_all_avgz    = toml::find_or <bool> (tnml, "all_zonal_scalars", false);

  if (write_all_avgz) {
    write_avg_zvE = write_avg_zkxvEy = write_avg_zkden = true;
    write_avg_zkUpar = write_avg_zkTpar = write_avg_zkqpar = write_avg_zkTperp = true;
  } else {
    write_avg_zvE     = toml::find_or <bool> (tnml, "avg_zvE",     false );
    write_avg_zkxvEy  = toml::find_or <bool> (tnml, "avg_zkxvEy",  false );
    write_avg_zkden   = toml::find_or <bool> (tnml, "avg_zkden",   false );
    write_avg_zkUpar  = toml::find_or <bool> (tnml, "avg_zkUpar",  false );
    write_avg_zkTpar  = toml::find_or <bool> (tnml, "avg_zkTpar",  false );
    write_avg_zkTperp = toml::find_or <bool> (tnml, "avg_zkTperp", false );
    write_avg_zkqpar  = toml::find_or <bool> (tnml, "avg_zkqpar",  false );
  }
  if (nm_in < 2) write_avg_zkUpar = false;
  if (nm_in < 3) write_avg_zkTpar = false;
  if (nm_in < 4) write_avg_zkqpar = false;
  if (nl_in < 2) write_avg_zkTperp = false;

  write_all_kmom    = toml::find_or <bool> (tnml, "all_zonal", false );

  if (write_all_kmom) {
    write_vEy = write_kxvEy = write_kden = write_kUpar = true;
    write_kTpar = write_kTperp = write_kqpar = true;
  } else { 
    write_vEy     = toml::find_or <bool> (tnml, "vEy",    false );
    write_kxvEy   = toml::find_or <bool> (tnml, "kxvEy",  false );
    write_kden    = toml::find_or <bool> (tnml, "kden",   false );
    write_kUpar   = toml::find_or <bool> (tnml, "kUpar",  false );
    write_kTpar   = toml::find_or <bool> (tnml, "kTpar",  false );
    write_kTperp  = toml::find_or <bool> (tnml, "kTperp", false );
    write_kqpar   = toml::find_or <bool> (tnml, "kqpar",  false );
  }
  if (nm_in < 2) write_kUpar = false;
  if (nm_in < 3) write_kTpar = false;
  if (nm_in < 4) write_kqpar = false;
  if (nl_in < 2) write_kTperp = false;
  
  write_all_xymom   = toml::find_or <bool> (tnml, "all_non_zonal", false );

  if (write_all_xymom) {
    write_xyvEy = write_xykxvEy = write_xyTperp = write_xyTpar = true;
    write_xyden = write_xyUpar = write_xyqpar = true;
  } else {
    write_xyvEy    = toml::find_or <bool> (tnml, "xyvEy",    false );
    write_xykxvEy  = toml::find_or <bool> (tnml, "xykxvEy",  false );
    write_xyden    = toml::find_or <bool> (tnml, "xyden",    false );
    write_xyUpar   = toml::find_or <bool> (tnml, "xyUpar",   false );
    write_xyTpar   = toml::find_or <bool> (tnml, "xyTpar",   false );
    write_xyqpar   = toml::find_or <bool> (tnml, "xyqpar",   false );
    write_xyTperp  = toml::find_or <bool> (tnml, "xyTperp",  false );
  }
  if (nm_in < 2) write_xyUpar = false;
  if (nm_in < 3) write_xyTpar = false;
  if (nm_in < 4) write_xyqpar = false;
  if (nl_in < 2) write_xyTperp = false;
  
  write_phi         = toml::find_or <bool> (tnml, "phi",         false );
  write_phi_kpar    = toml::find_or <bool> (tnml, "phi_kpar",    false );
  write_h_spectrum  = toml::find_or <bool> (tnml, "h_spectrum",  false );
  write_l_spectrum  = toml::find_or <bool> (tnml, "l_spectrum",  false );
  write_lh_spectrum = toml::find_or <bool> (tnml, "lh_spectrum", false );

  write_kmom  = (write_vEy   || write_kxvEy       || write_kden        || write_kUpar);
  write_kmom  = (write_kmom  || write_kTpar       || write_kTperp      || write_kqpar);

  write_kmom  = (write_kmom  || write_avg_zvE    || write_avg_zkxvEy || write_avg_zkTperp);
  write_kmom  = (write_kmom  || write_avg_zkden  || write_avg_zkUpar || write_avg_zkTpar);
  write_kmom  = (write_kmom  || write_avg_zkqpar );
  
  write_xymom = (write_xyvEy || write_xykxvEy   || write_xyden      || write_xyUpar);
  write_xymom = (write_xymom || write_xyTpar    || write_xyTperp    || write_xyqpar);
  
  tnml = nml;
  if (nml.contains("Expert")) tnml = toml::find (nml, "Expert");

  i_share     = toml::find_or <int>    (tnml, "i_share",         8 );
  nreal       = toml::find_or <int>    (tnml, "nreal",           1 );  
  init_single = toml::find_or <bool>   (tnml, "init_single", false );
  ikx_single  = toml::find_or <int>    (tnml, "ikx_single",      0 );
  iky_single  = toml::find_or <int>    (tnml, "iky_single",      1 );
  ikx_fixed   = toml::find_or <int>    (tnml, "ikx_fixed",      -1 );
  iky_fixed   = toml::find_or <int>    (tnml, "iky_fixed",      -1 );
  eqfix       = toml::find_or <bool>   (tnml, "eqfix",       false );
  secondary   = toml::find_or <bool>   (tnml, "secondary",   false );
  phi_ext     = toml::find_or <float>  (tnml, "phi_ext",       0.0 );
  source      = toml::find_or <string> (tnml, "source",  "default" );
  tp_t0       = toml::find_or <float>  (tnml, "t0",           -1.0 );
  tp_tf       = toml::find_or <float>  (tnml, "tf",           -1.0 );
  tprim0      = toml::find_or <float>  (tnml, "tprim0",       -1.0 );
  tprimf      = toml::find_or <float>  (tnml, "tprimf",       -1.0 );
  
  tnml = nml;
  if (nml.contains("Resize")) tnml = toml::find (nml, "Resize");

  domain_change = toml::find_or <bool> (tnml, "domain_change", false);
  z0_mult = toml::find_or <int> (tnml, "z0_mult", 1);  assert( (z0_mult > 0) && "z0_mult must be an integer >= 1");
  y0_mult = toml::find_or <int> (tnml, "y0_mult", 1);  assert( (y0_mult > 0) && "y0_mult must be an integer >= 1");
  x0_mult = toml::find_or <int> (tnml, "x0_mult", 1);  assert( (x0_mult > 0) && "x0_mult must be an integer >= 1");
  nx_mult = toml::find_or <int> (tnml, "nx_mult", 1);  assert( (nx_mult > 0) && "nx_mult must be an integer >= 1");
  ny_mult = toml::find_or <int> (tnml, "ny_mult", 1);  assert( (ny_mult > 0) && "ny_mult must be an integer >= 1");
  nm_add  = toml::find_or <int> (tnml, "nm_add" , 0);  
  nl_add  = toml::find_or <int> (tnml, "nl_add" , 0);  
  ns_add  = toml::find_or <int> (tnml, "ns_add" , 0);  assert( (ns_add >= 0) && "ns_add must be an integer >= 0");
  
  ntheta_mult = toml::find_or <int> (tnml, "nz_mult", 1);
  assert( (ntheta_mult > 0) && "ntheta_mult must be an integer >= 1");

  if (!domain_change) {
    assert ((nx_mult == 1) && "When domain_change is false, nx_mult must be 1");
    assert ((ny_mult == 1) && "When domain_change is false, ny_mult must be 1");
    assert ((ntheta_mult == 1) && "When domain_change is false, ntheta_mult must be 1");
    assert ((x0_mult == 1) && "When domain_change is false, x0_mult must be 1");
    assert ((y0_mult == 1) && "When domain_change is false, y0_mult must be 1");
    assert ((z0_mult == 1) && "When domain_change is false, z0_mult must be 1");
    assert ((nl_add == 0) && "When domain_change is false, nl_add must be 0");
    assert ((nm_add == 0) && "When domain_change is false, nm_add must be 0");
  }

  if (domain_change) {
    printf( "You are changing the simulation domain with this input file. \n");
    if (x0_mult > 1) printf("Compared to the restart file, you have increased x0 by a factor of %d \n",x0_mult);
    if (y0_mult > 1) printf("Compared to the restart file, you have increased y0 by a factor of %d \n",y0_mult);
    if (z0_mult > 1) printf("Compared to the restart file, you have increased z0 by a factor of %d \n",z0_mult);
    if (nx_mult > 1) printf("Compared to the restart file, you have increased nx by a factor of %d \n",nx_mult);
    if (ny_mult > 1) printf("Compared to the restart file, you have increased ny by a factor of %d \n",ny_mult);
    if (ntheta_mult > 1) printf("Compared to the restart file, you have increased nx ntheta a factor of %d \n",ntheta_mult);
    if (nl_add > 0) printf("Compared to the restart file, you have added %d Laguerre basis elements. \n",nl_add);
    if (nl_add < 0) printf("Compared to the restart file, you have removed %d Laguerre basis elements. \n",-nl_add);
    if (nm_add > 0) printf("Compared to the restart file, you have added %d Hermite basis elements. \n",nm_add);
    if (nm_add < 0) printf("Compared to the restart file, you have removed %d Hermite basis elements. \n",-nm_add);
    if (ns_add > 0) printf("Compared to the restart file, you have added %d species. \n",ns_add);
  }    
  
  tnml = nml;
  if (nml.contains("Controls")) tnml = toml::find (nml, "Controls");

  nonlinear_mode = toml::find_or <bool>   (tnml, "nonlinear_mode",    false );  linear = !nonlinear_mode;
  closure_model  = toml::find_or <string> (tnml, "closure_model", "none" );
  smith_par_q    = toml::find_or <int>    (tnml, "smith_par_q",        3 );
  smith_perp_q   = toml::find_or <int>    (tnml, "smith_perp_q",       3 );

  fphi       = toml::find_or <float>  (tnml, "fphi",      1.0 );
  fapar      = toml::find_or <float>  (tnml, "fapar",     0.0 );
  fbpar      = toml::find_or <float>  (tnml, "fbpar",     0.0 );
  scheme     = toml::find_or <string> (tnml, "scheme",    "sspx3"   );
  stages     = toml::find_or <int>    (tnml, "stages",         10   );
  cfl        = toml::find_or <float>  (tnml, "cfl",           1.0   );
  init_field = toml::find_or <string> (tnml, "init_field", "density");
  init_amp   = toml::find_or <float>  (tnml, "init_amp",   1.0e-5   );
  kpar_init  = toml::find_or <float>  (tnml, "kpar_init",     0.0   );
  D_HB       = toml::find_or <float>  (tnml, "D_HB",          1.0   );
  w_osc      = toml::find_or <float>  (tnml, "w_osc",         0.0   );
  D_hyper    = toml::find_or <float>  (tnml, "D_hyper",       0.1   );
  nu_hyper_l = toml::find_or <float>  (tnml, "nu_hyper_l",    1.0   );
  nu_hyper_m = toml::find_or <float>  (tnml, "nu_hyper_m",    1.0   );
  nu_hyper   = toml::find_or <int>    (tnml, "nu_hyper",        2   );
  p_hyper    = toml::find_or <int>    (tnml, "p_hyper",         2   );
  p_hyper_l  = toml::find_or <int>    (tnml, "p_hyper_l",       6   );
  p_hyper_m  = toml::find_or <int>    (tnml, "p_hyper_m",       1   );  
  p_HB       = toml::find_or <int>    (tnml, "p_HB",            2   );
  hyper      = toml::find_or <bool>   (tnml, "hyper",         false );
  HB_hyper   = toml::find_or <bool>   (tnml, "HB_hyper",      false );
  hypercollisions = toml::find_or <bool> (tnml, "hypercollisions", false);
  random_init     = toml::find_or <bool> (tnml, "random_init",     false);
  if (random_init) kpar_init = 0.0; 
  
  if (write_omega && fixed_amplitude) {
    if (nonlinear_mode || nwrite < 3) fixed_amplitude = false;
  }

  tnml = nml;
  if (nml.contains("Forcing")) tnml = toml::find (nml, "Forcing");  

  forcing_type  = toml::find_or <string> (tnml, "forcing_type",    "Kz" );
  stir_field    = toml::find_or <string> (tnml, "stir_field", "density" );
  forcing_amp   = toml::find_or <float>  (tnml, "forcing_amp",      1.0 );
  forcing_index = toml::find_or <int>    (tnml, "forcing_index",    1   );
  forcing_init  = toml::find_or <bool>   (tnml, "forcing_init",   false );
  no_fields     = toml::find_or <bool>   (tnml, "no_fields",      false );
  

  ///////////////////////////////////////////////////////////////////////
  //
  // New way to handle Boltzmann response. 
  // 
  // Preferred: 
  //     All kinetic? Leave out iphi00 entirely; leave out add_Boltzmann_species or set add_Boltzmann_species = false
  //
  //     Include a Boltzmann species? Set add_Boltzmann_species = true, and set Boltzmann_type 
  //            as either "electrons" (to recover iphi00=2 in the old way)
  //            or "ions"             (to recover iphi00=1 in the old way)
  //     Use "tau_fac" instead of ti_ov_te as the multiplier for the Boltzmann response
  // 
  // Backward compatibility possibilities (not preferred)
  //     
  //     Assume there is always a Boltzmann species unless electromagnetic
  //     and control the response with iphi00 and ti_ov_te
  //
  //     This mode of operation is deprecated, and should be removed in early 2021.
  //
  ///////////////////////////////////////////////////////////////////////
  
  tnml = nml;
  if (nml.contains("Boltzmann")) tnml = toml::find (nml, "Boltzmann");  

  add_Boltzmann_species = toml::find_or <bool>   (tnml, "add_Boltzmann_species", false);
  Btype                 = toml::find_or <string> (tnml, "Boltzmann_type", "electrons" );
  iphi00                = toml::find_or <int>    (tnml, "iphi00",                  -2 );

  // For backward compatibility, check if iphi00 was specified and act accordingly
  if (iphi00 > 0) {
    if (iphi00 == 1) Btype = "Ions";
    if (iphi00 == 2) Btype = "Electrons";
    add_Boltzmann_species = true;
  }
  
  // allow some sloppiness here:
  
  if (Btype == "Electrons") Boltzmann_opt = BOLTZMANN_ELECTRONS;
  if (Btype == "Electron" ) Boltzmann_opt = BOLTZMANN_ELECTRONS;
  if (Btype == "Ions")      Boltzmann_opt = BOLTZMANN_IONS;
  if (Btype == "Ion" )      Boltzmann_opt = BOLTZMANN_IONS;

  if (Btype == "electrons") Boltzmann_opt = BOLTZMANN_ELECTRONS;
  if (Btype == "electron" ) Boltzmann_opt = BOLTZMANN_ELECTRONS;
  if (Btype == "ions")      Boltzmann_opt = BOLTZMANN_IONS;
  if (Btype == "ion" )      Boltzmann_opt = BOLTZMANN_IONS;

  // backward compatibility, sets default overall as tau_fac = unity
  ti_ov_te = toml::find_or <float> (tnml, "TiTe", 1.0);     
  // check for new, physically sensible value in the input file
  tau_fac  = toml::find_or <float> (tnml, "tau_fac", -1.0);
  
  if (tau_fac > 0.) ti_ov_te = tau_fac;                 // new definition has priority if it was provided
  tau_fac = ti_ov_te;                                   // In the body of the code, use tau_fac instead of ti_ov_te
  
  ///////////////////////////////////////////////////////////////////////
  //                                                                   //
  // Testing that we have working options                              //
  //                                                                   //
  ///////////////////////////////////////////////////////////////////////

  all_kinetic = true;
  if (add_Boltzmann_species) all_kinetic = false;

  if (all_kinetic) {
    assert( (iphi00 <= 0)
	    && "Specifying all species are kinetic and also iphi00 > 0 is not allowed");
    assert( !add_Boltzmann_species
	    && "Specifying all species are kinetic and also add_Boltzmann_species is not allowed");
  }

  if (!all_kinetic) {
    assert( (tau_fac >= 0.)
	    && "Specifying all_kinetic == false and also tau_fac < 0. is not allowed");
    assert( ( (Boltzmann_opt==BOLTZMANN_ELECTRONS) || (Boltzmann_opt==BOLTZMANN_IONS) )
	    && "If all_kinetic == false then a legal Boltzmann_opt must be specified");
    assert( add_Boltzmann_species
	    && "If all_kinetic == false then add_Boltzmann_species should be true");
  }
      
  tnml = nml;
  if (nml.contains("Geometry")) tnml = toml::find (nml, "Geometry");  

  geofilename = toml::find_or <string> (tnml, "geofile",  "eik.out" );  
  slab        = toml::find_or <bool>   (tnml, "slab",         false );
  const_curv  = toml::find_or <bool>   (tnml, "const_curv",   false );

  igeo        = toml::find_or <int>   (tnml, "igeo",       0 );
  drhodpsi    = toml::find_or <float> (tnml, "drhodpsi", 1.0 );
  kxfac       = toml::find_or <float> (tnml, "kxfac",    1.0 );
  rmaj        = toml::find_or <float> (tnml, "Rmaj",     1.0 );
  shift       = toml::find_or <float> (tnml, "shift",    0.0 );
  eps         = toml::find_or <float> (tnml, "eps",    0.167 );
  qsf         = toml::find_or <float> (tnml, "qinp",     1.4 );
  shat        = toml::find_or <float> (tnml, "shat",     0.8 );
  beta        = toml::find_or <float> (tnml, "beta",    -1.0 );
  zero_shat   = toml::find_or <bool>  (tnml, "zero_shat", false);

  if (igeo == 0 && abs(shat) < 1.e-6) zero_shat = true;
  
  if (igeo == 0 && zero_shat) {
    boundary = "periodic";
    shat = 1.e-8;
    printf("Using no magnetic shear because zero_shat = true \n");
  }
  //  if (igeo == 0 && abs(shat) < 1.e-6) boundary = "periodic";
  
  wspectra.resize(nw_spectra);
  pspectra.resize(np_spectra);
  aspectra.resize(na_spectra);

  wspectra.assign(nw_spectra, 0);
  pspectra.assign(np_spectra, 0);
  aspectra.assign(na_spectra, 0);

  tnml = nml;
  if (nml.contains("Wspectra")) tnml = toml::find (nml, "Wspectra");  

  wspectra [WSPECTRA_species] = (toml::find_or <bool> (tnml, "species",          false)) == true ? 1 : 0;
  wspectra [WSPECTRA_kx]      = (toml::find_or <bool> (tnml, "kx",               false)) == true ? 1 : 0;
  wspectra [WSPECTRA_ky]      = (toml::find_or <bool> (tnml, "ky",               false)) == true ? 1 : 0;
  wspectra [WSPECTRA_kz]      = (toml::find_or <bool> (tnml, "kz",               false)) == true ? 1 : 0;
  wspectra [WSPECTRA_z]       = (toml::find_or <bool> (tnml, "z",                false)) == true ? 1 : 0;
  wspectra [WSPECTRA_l]       = (toml::find_or <bool> (tnml, "laguerre",         false)) == true ? 1 : 0;
  wspectra [WSPECTRA_m]       = (toml::find_or <bool> (tnml, "hermite",          false)) == true ? 1 : 0;
  wspectra [WSPECTRA_lm]      = (toml::find_or <bool> (tnml, "hermite_laguerre", false)) == true ? 1 : 0;
  wspectra [WSPECTRA_kperp]   = (toml::find_or <bool> (tnml, "kperp",            false)) == true ? 1 : 0;
  wspectra [WSPECTRA_kxky]    = (toml::find_or <bool> (tnml, "kxky",             false)) == true ? 1 : 0;

  tnml = nml;
  if (nml.contains("Pspectra")) tnml = toml::find (nml, "Pspectra");  

  pspectra [PSPECTRA_species] = (toml::find_or <bool> (tnml, "species",          false)) == true ? 1 : 0;
  pspectra [PSPECTRA_kx]      = (toml::find_or <bool> (tnml, "kx",               false)) == true ? 1 : 0;
  pspectra [PSPECTRA_ky]      = (toml::find_or <bool> (tnml, "ky",               false)) == true ? 1 : 0;
  pspectra [PSPECTRA_kz]      = (toml::find_or <bool> (tnml, "kz",               false)) == true ? 1 : 0;
  pspectra [PSPECTRA_z]       = (toml::find_or <bool> (tnml, "z",                false)) == true ? 1 : 0;
  pspectra [PSPECTRA_kperp]   = (toml::find_or <bool> (tnml, "kperp",            false)) == true ? 1 : 0;
  pspectra [PSPECTRA_kxky]    = (toml::find_or <bool> (tnml, "kxky",             false)) == true ? 1 : 0;

  // if we have adiabatic ions, slave the aspectra to the wspectra as appropriate
  if (!all_kinetic) {
    aspectra [ ASPECTRA_species ] = wspectra [ WSPECTRA_species ];
    aspectra [ ASPECTRA_kx      ] = wspectra [ WSPECTRA_kx      ];
    aspectra [ ASPECTRA_ky      ] = wspectra [ WSPECTRA_ky      ];
    aspectra [ ASPECTRA_kz      ] = wspectra [ WSPECTRA_kz      ];
    aspectra [ ASPECTRA_z       ] = wspectra [ WSPECTRA_z       ];
    aspectra [ ASPECTRA_kperp   ] = wspectra [ WSPECTRA_kperp   ];
    aspectra [ ASPECTRA_kxky    ] = wspectra [ WSPECTRA_kxky    ];
  }
  // for backwards compatibility
  if (write_l_spectrum)  wspectra[WSPECTRA_l] = 1;
  if (write_h_spectrum)  wspectra[WSPECTRA_m] = 1;
  if (write_lh_spectrum) wspectra[WSPECTRA_lm] = 1;
  
  // Some diagnostics are not yet available:
  wspectra[ WSPECTRA_kperp] = 0;
  pspectra[ PSPECTRA_kperp] = 0;
  aspectra[ ASPECTRA_kperp] = 0;
  
  // If Wtot is requested, turn Ws, Ps, Phi2 on:
  if (write_free_energy) {
    wspectra[WSPECTRA_species] = 1;
    pspectra[PSPECTRA_species] = 1;
    if ( add_Boltzmann_species ) aspectra[ASPECTRA_species] = 1;
  }

  gx = (!ks && !vp);
  assert (!(ks && vp));
  assert (ks || vp || gx);

  int ksize = 0;
  for (int k=0; k<pspectra.size(); k++) ksize = max(ksize, pspectra[k]);
  for (int k=0; k<wspectra.size(); k++) ksize = max(ksize, wspectra[k]);
  for (int k=0; k<aspectra.size(); k++) ksize = max(ksize, aspectra[k]);


  tnml = nml;
  if (nml.contains("PZT")) tnml = toml::find (nml, "PZT");  

  diagnosing_pzt = write_pzt;
  
  diagnosing_spectra = false;
  if (ksize > 0) diagnosing_spectra = true;

  diagnosing_kzspec = false;
  if ((wspectra[ WSPECTRA_kz ] == 1) || (pspectra[ PSPECTRA_kz ] == 1) || (aspectra[ ASPECTRA_kz ] == 1)) {
    diagnosing_kzspec = true;
  }
  
  diagnosing_moments = false;
  if (write_moms || write_phi || write_phi_kpar) diagnosing_moments = true;
  
  species_h = (specie *) calloc(nspec_in, sizeof(specie));
  for (int is=0; is < nspec_in; is++) {
    species_h[is].uprim = 0.;
    species_h[is].nu_ss = 0.;
    species_h[is].temp = 1.;
    
    species_h[is].z     = toml::find <float>  (nml, "species", "z",     is);
    species_h[is].mass  = toml::find <float>  (nml, "species", "mass",  is);
    species_h[is].dens  = toml::find <float>  (nml, "species", "dens",  is);
    species_h[is].temp  = toml::find <float>  (nml, "species", "temp",  is);
    species_h[is].tprim = toml::find <float>  (nml, "species", "tprim", is);
    species_h[is].fprim = toml::find <float>  (nml, "species", "fprim", is);
    species_h[is].uprim = toml::find <float>  (nml, "species", "uprim", is);
    species_h[is].nu_ss = toml::find <float>  (nml, "species", "vnewk", is);
    string stype        = toml::find <string> (nml, "species", "type",  is);
    species_h[is].type = stype == "ion" ? 0 : 1;
  }
  
  float numax = -1.;
  collisions = false;
  for (int i=0; i<nspec_in; i++) {numax = max(numax, species_h[i].nu_ss);}
  if (numax > 0.) collisions = true;
  
  Reservoir = false;
  add_noise = false;
  ResFakeData = false;
  ResWrite = false;
  
  tnml = nml;
  if (nml.contains("Reservoir")) tnml = toml::find (nml, "Reservoir");  

  Reservoir          = toml::find_or <bool>  (tnml, "Use_reservoir",  false  );
  ResQ               = toml::find_or <int>   (tnml, "Q",                 20  );
  ResK               = toml::find_or <int>   (tnml, "K",                  3  );
  ResTrainingSteps   = toml::find_or <int>   (tnml, "training_steps",     0  );
  ResPredict_Steps   = toml::find_or <int>   (tnml, "prediction_steps", 200  );
  ResTrainingDelta   = toml::find_or <int>   (tnml, "training_delta",     0  );
  ResSpectralRadius  = toml::find_or <float> (tnml, "spectral_radius",  0.6  );
  ResReg             = toml::find_or <float> (tnml, "regularization", 1.0e-4 );
  ResSigma           = toml::find_or <float> (tnml, "input_sigma",      0.5  );
  ResSigmaNoise      = toml::find_or <float> (tnml, "noise",           -1.0  );
  ResFakeData        = toml::find_or <bool>  (tnml, "fake_data",      false  );
  ResWrite           = toml::find_or <bool>  (tnml, "write",          false  );
  
  if (ResTrainingSteps == 0) ResTrainingSteps = nstep/nwrite;
  if (ResTrainingDelta == 0) ResTrainingDelta = nwrite;
  if (ResSigmaNoise > 0.) add_noise = true;

  // open the netcdf4 file for this run
  // store all inputs for future reference

  char strb[263];
  strcpy(strb, run_name); 
  strcat(strb, ".nc");

  int retval, idim, sdim, wdim, pdim, adim, nc_out, nc_inputs, nc_diss;
  if (retval = nc_create(strb, NC_CLOBBER | NC_NETCDF4, &ncid)) ERR(retval);
  if (retval = nc_def_grp(ncid,      "Inputs",         &nc_inputs)) ERR(retval);
  if (retval = nc_def_grp(nc_inputs, "Domain",         &nc_dom))    ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "Time",           &nc_time))   ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "KS",             &nc_ks))     ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "Vlasov_Poisson", &nc_vp))     ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "Restart",        &nc_rst))    ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "Controls",       &nc_con))    ERR(retval);
  if (retval = nc_def_grp(nc_con,    "Numerical_Diss", &nc_diss))   ERR(retval);
  if (retval = nc_def_grp(nc_con,    "Forcing",        &nc_frc))    ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "Expert",         &nc_expert)) ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "Diagnostics",    &nc_diag))   ERR(retval);  
  if (retval = nc_def_grp(nc_diag,   "SetSpectra",     &nc_sp))     ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "Resize",         &nc_resize)) ERR(retval);  
  if (retval = nc_def_grp(nc_inputs, "Reservoir",      &nc_ml))     ERR(retval);
  if (retval = nc_def_grp(ncid,      "Geometry",       &nc_geo))    ERR(retval);
  if (retval = nc_def_grp(nc_inputs, "Species",        &nc_spec))   ERR(retval);
  if (retval = nc_def_grp(nc_spec,   "Boltzmann",      &nc_bz))     ERR(retval);  
  if (retval = nc_def_grp(ncid,      "Special",        &nc_out))    ERR(retval);  
  if (retval = nc_def_grp(ncid,      "Spectra",        &nc_out))    ERR(retval);
  if (retval = nc_def_grp(ncid,      "Non_zonal",      &nc_out))    ERR(retval);
  if (retval = nc_def_grp(ncid,      "Zonal_x",        &nc_out))    ERR(retval);
  if (retval = nc_def_grp(ncid,      "Fluxes",         &nc_out))    ERR(retval);

  if (ResWrite) {
    strcpy(strb, run_name);
    strcat(strb, "_ml.nc");

    if (retval = nc_create(strb, NC_CLOBBER | NC_NETCDF4, &ncresid)) ERR(retval);
    if (retval = nc_def_dim (ncresid, "r",     ResQ*nx_in*ny_in*nz_in*nm_in*nl_in, &idim)) ERR(retval);
    if (retval = nc_def_dim (ncresid, "time",  NC_UNLIMITED, &idim)) ERR(retval);
    if (retval = nc_enddef (ncresid)) ERR(retval);
  }
  
  if (write_xymom) {
    strcpy(strb, run_name); 
    strcat(strb, "_nonZonal_xy.nc");
    
    if (retval = nc_create(strb, NC_CLOBBER | NC_NETCDF4, &nczid)) ERR(retval);
    if (retval = nc_def_dim (nczid, "x",       nx_in,        &idim)) ERR(retval);
    if (retval = nc_def_dim (nczid, "y",       ny_in,        &idim)) ERR(retval);
    if (retval = nc_def_dim (nczid, "time",    NC_UNLIMITED, &idim)) ERR(retval);
    if (retval = nc_enddef (nczid)) ERR(retval);
  }

  int ri = 2;
  if (retval = nc_def_dim (ncid, "ri",      ri,            &idim)) ERR(retval);
  if (retval = nc_def_dim (ncid, "x",       nx_in,         &idim)) ERR(retval);
  if (retval = nc_def_dim (ncid, "y",       ny_in,         &idim)) ERR(retval);
  if (retval = nc_def_dim (ncid, "m",       nm_in,         &idim)) ERR(retval);
  if (retval = nc_def_dim (ncid, "l",       nl_in,         &idim)) ERR(retval);
  if (retval = nc_def_dim (ncid, "s",       nspec_in,      &sdim)) ERR(retval);
  if (retval = nc_def_dim (ncid, "time",    NC_UNLIMITED,  &idim)) ERR(retval);
  if (retval = nc_def_dim (nc_sp, "nw",     nw_spectra,    &wdim)) ERR(retval);
  if (retval = nc_def_dim (nc_sp, "np",     np_spectra,    &pdim)) ERR(retval);
  if (retval = nc_def_dim (nc_sp, "na",     na_spectra,    &adim)) ERR(retval);

  static char file_header[] = "GX simulation data";
  if (retval = nc_put_att_text (ncid, NC_GLOBAL, "Title", strlen(file_header), file_header)) ERR(retval);

  int ivar; 
  if (retval = nc_def_var (ncid, "ny",          NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (ncid, "nx",          NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (ncid, "ntheta",      NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (ncid, "nhermite",    NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (ncid, "nlaguerre",   NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (ncid, "nspecies",    NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (ncid, "nperiod",     NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (ncid, "debug",       NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (ncid, "repeat",      NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_time, "dt",       NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_time, "nstep",    NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_time, "nwrite",   NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_time, "navg",     NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_time, "nsave",    NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_ks, "ks",         NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ks, "write_ks",   NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ks, "eps_ks",     NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ks, "ks_t0",      NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ks, "ks_tf",      NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ks, "ks_eps0",    NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ks, "ks_epsf",    NC_FLOAT, 0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_vp, "vp",         NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_vp, "vp_closure", NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_vp, "vp_nu",      NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_vp, "vp_nuh",     NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_vp, "vp_alpha",   NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_vp, "vp_alpha_h", NC_INT,   0, NULL, &ivar)) ERR(retval);
  
  specs[0] = wdim;
  if (retval = nc_def_var (nc_sp, "wspectra",   NC_INT,   1, specs, &ivar)) ERR(retval);

  specs[0] = pdim;
  if (retval = nc_def_var (nc_sp, "pspectra",   NC_INT,   1, specs, &ivar)) ERR(retval);

  specs[0] = adim;
  if (retval = nc_def_var (nc_sp, "aspectra",   NC_INT,   1, specs, &ivar)) ERR(retval);

  specs[0] = sdim;
  if (retval = nc_def_var (nc_spec, "species_type", NC_INT,   1, specs, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_spec, "z",            NC_FLOAT, 1, specs, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_spec, "m",            NC_FLOAT, 1, specs, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_spec, "n0",           NC_FLOAT, 1, specs, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_spec, "n0_prime",     NC_FLOAT, 1, specs, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_spec, "u0_prime",     NC_FLOAT, 1, specs, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_spec, "T0",           NC_FLOAT, 1, specs, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_spec, "T0_prime",     NC_FLOAT, 1, specs, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_spec, "nu",           NC_FLOAT, 1, specs, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_dom, "y0",            NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_dom, "x0",            NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_dom, "zp",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_dom, "jtwist",        NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_dom, "boundary_dum",  NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_dom, ivar, "value", boundary.size(), boundary.c_str())) ERR(retval);

  if (retval = nc_def_var (nc_ml, "Use_reservoir",  NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "Q",              NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "K",              NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "TrainingSteps",  NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "PredictSteps",   NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "TrainingDelta",  NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "SpecRadius",     NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "Regularizer",    NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "InputSigma",     NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "SigmaNoise",     NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "FakeData",       NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_ml, "ResWrite",       NC_INT,   0, NULL, &ivar)) ERR(retval);
  
  if (retval = nc_def_var (nc_rst, "scale",            NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_rst, "restart",          NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_rst, "save_for_restart", NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_rst, "restart_from_file_dum", NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_rst, ivar, "value", restart_from_file.size(), restart_from_file.c_str())) ERR(retval);

  if (retval = nc_def_var (nc_rst, "restart_to_file_dum",   NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_rst, ivar, "value", restart_to_file.size(), restart_to_file.c_str())) ERR(retval);

  if (retval = nc_def_var (nc_diag, "fixed_amp",       NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "omega",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "fluxes",          NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_diag, "all_zonal_scalars", NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "avg_zvE",         NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "avg_zkxvEy",      NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "avg_zkden",       NC_INT,   0, NULL, &ivar)) ERR(retval); 
  if (retval = nc_def_var (nc_diag, "avg_zkUpar",      NC_INT,   0, NULL, &ivar)) ERR(retval); 
  if (retval = nc_def_var (nc_diag, "avg_zkTpar",      NC_INT,   0, NULL, &ivar)) ERR(retval); 
  if (retval = nc_def_var (nc_diag, "avg_zkTperp",     NC_INT,   0, NULL, &ivar)) ERR(retval); 
  if (retval = nc_def_var (nc_diag, "avg_zkqpar",      NC_INT,   0, NULL, &ivar)) ERR(retval); 

  if (retval = nc_def_var (nc_diag, "all_zonal",       NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "vEy",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "kxvEy",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "kden",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "kUpar",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "kTpar",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "kqpar",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "kTperp",          NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_diag, "all_non_zonal",   NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "xyvEy",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "xykxvEy",         NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "xyden",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "xyUpar",          NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "xyTpar",          NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "xyTperp",         NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "xyqpar",          NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_diag, "moms",            NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_diag, "free_energy",     NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "phi",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "phi_kpar",        NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "rh",              NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diag, "pzt",             NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_con, "scheme_dum",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_con, ivar, "value", scheme.size(), scheme.c_str())) ERR(retval);
  if (retval = nc_def_var (nc_con, "stages",                NC_INT,   0, NULL, &ivar)) ERR(retval);
  
  if (retval = nc_def_var (nc_con, "nonlinear_mode",      NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "closure_model_dum",     NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_con, ivar, "value", closure_model.size(), closure_model.c_str())) ERR(retval);
  if (retval = nc_def_var (nc_con, "smith_par_q",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "smith_perp_q",          NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "cfl",                   NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "fphi",                  NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "fapar",                 NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "fbpar",                 NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "init_amp",              NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "collisions",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "init_field_dum",        NC_INT,   0, NULL, &ivar)) ERR(retval);  
  if (retval = nc_put_att_text (nc_con, ivar, "value", init_field.size(), init_field.c_str())) ERR(retval);

  if (retval = nc_def_var (nc_con, "kpar_init",             NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_con, "random_init",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  
  if (retval = nc_def_var (nc_diss, "hyper",                 NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "D_hyper",               NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "nu_hyper",              NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "hypercollisions",       NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "nu_hyper_l",            NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "nu_hyper_m",            NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "p_hyper",               NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "p_hyper_l",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "p_hyper_m",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "w_osc",                 NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "D_HB",                  NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "p_HB",                  NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_diss, "HB_hyper",              NC_INT,   0, NULL, &ivar)) ERR(retval);
  
  if (retval = nc_def_var (nc_frc, "forcing_init",          NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_frc, "forcing_type_dum",      NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_frc, ivar, "value", forcing_type.size(), forcing_type.c_str())) ERR(retval);
  if (retval = nc_def_var (nc_frc, "no_fields",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_frc, "forcing_amp",           NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_frc, "forcing_index",         NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_frc, "stir_field_dum",        NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_frc, ivar, "value", stir_field.size(), stir_field.c_str())) ERR(retval);


  if (retval = nc_def_var (nc_expert, "i_share",               NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "nreal",                 NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "init_single",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "ikx_single",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "iky_single",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "ikx_fixed",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "iky_fixed",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "eqfix",                 NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "secondary",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "phi_ext",               NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "t0",                    NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "tf",                    NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "tprim0",                NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "tprimf",                NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_expert, "source_dum",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_expert, ivar, "value", source.size(), source.c_str())) ERR(retval);

  // for boltzmann opts need attribute BD bug

  if (retval = nc_def_var (nc_bz, "tau_fac",               NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_bz, "add_Boltzmann_species", NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_bz, "all_kinetic",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_bz, "Boltzmann_type_dum",    NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_bz, ivar, "value", Btype.size(), Btype.c_str() ) ) ERR(retval);
  
  // geometry
  if (retval = nc_def_var (nc_geo, "igeo",                  NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "slab",                  NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "const_curv",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "geofile_dum",           NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_put_att_text (nc_geo, ivar, "value", geofilename.size(), geofilename.c_str())) ERR(retval);

  if (retval = nc_def_var (nc_geo, "drhodpsi",              NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "kxfac",                 NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "Rmaj",                  NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "shift",                 NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "eps",                   NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "q",                     NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "shat",                  NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "kappa",                 NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "kappa_prime",           NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "tri",                   NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "tri_prime",             NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  
  if (retval = nc_def_var (nc_geo, "beta",                  NC_FLOAT, 0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_geo, "zero_shat",             NC_INT,   0, NULL, &ivar)) ERR(retval);

  if (retval = nc_def_var (nc_resize, "domain_change",      NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "x0_mult",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "y0_mult",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "z0_mult",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "nx_mult",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "ny_mult",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "nz_mult",            NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "nl_add",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "nm_add",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  if (retval = nc_def_var (nc_resize, "ns_add",             NC_INT,   0, NULL, &ivar)) ERR(retval);
  
  if (retval = nc_def_var (ncid, "code_info",             NC_INT,   0, NULL, &ivar)) ERR(retval);

  std::string hash(build_git_sha);                       
  if (retval = nc_put_att_text (ncid, ivar, "Hash",      hash.size(), hash.c_str() ) ) ERR(retval);
  std::string compiled(build_git_time);                  
  if (retval = nc_put_att_text (ncid, ivar, "BuildDate", compiled.size(), compiled.c_str() ) ) ERR(retval);
  std::string builder(build_user);                       
  if (retval = nc_put_att_text (ncid, ivar, "BuildUser", builder.size(), builder.c_str() ) ) ERR(retval);
  std::string build_host(build_hostname);                
  if (retval = nc_put_att_text (ncid, ivar, "BuildHost", build_host.size(), build_host.c_str() ) ) ERR(retval);

  if (retval = nc_enddef (ncid)) ERR(retval);

  putbool  (ncid, "debug",     debug);
  putint   (ncid, "ntheta",    nz_in);
  putint   (ncid, "nx",        nx_in);
  putint   (ncid, "ny",        ny_in);
  putint   (ncid, "nhermite",  nm_in);
  putint   (ncid, "nlaguerre", nl_in);
  putint   (ncid, "nspecies",  nspec_in);
  putint   (ncid, "nperiod",   nperiod);
  putbool  (ncid, "repeat",    repeat);
  
  putbool (nc_resize, "domain_change", domain_change );
  putint  (nc_resize, "x0_mult"      , x0_mult       );
  putint  (nc_resize, "y0_mult"      , y0_mult       );
  putint  (nc_resize, "z0_mult"      , z0_mult       );
  putint  (nc_resize, "nx_mult"      , nx_mult       );
  putint  (nc_resize, "ny_mult"      , ny_mult       );
  putint  (nc_resize, "nz_mult"      , ntheta_mult   );
  putint  (nc_resize, "nl_add"       , nl_add        );
  putint  (nc_resize, "nm_add"       , nm_add        );  
  putint  (nc_resize, "ns_add"       , ns_add        );  
  
  putbool  (nc_ml, "Use_reservoir", Reservoir         );
  putint   (nc_ml, "Q"            , ResQ              );
  putint   (nc_ml, "K"            , ResK              );
  putint   (nc_ml, "TrainingSteps", ResTrainingSteps  );
  putint   (nc_ml, "PredictSteps" , ResPredict_Steps  );
  putint   (nc_ml, "TrainingDelta", ResTrainingDelta  );
  put_real (nc_ml, "SpecRadius"   , ResSpectralRadius );
  put_real (nc_ml, "Regularizer"  , ResReg            );
  put_real (nc_ml, "InputSigma"   , ResSigma          );
  put_real (nc_ml, "SigmaNoise"   , ResSigmaNoise     );
  putbool  (nc_ml, "FakeData"     , ResFakeData       );
  putbool  (nc_ml, "ResWrite"     , ResWrite          );
  
  putbool  (nc_bz, "all_kinetic",           all_kinetic           );
  putbool  (nc_bz, "add_Boltzmann_species", add_Boltzmann_species );
  put_real (nc_bz, "tau_fac",               tau_fac               );
  
  put_real (nc_dom, "y0",      y0      );
  put_real (nc_dom, "x0",      x0      );
  putint   (nc_dom, "zp",      Zp      );
  putint   (nc_dom, "jtwist",  jtwist  );

  put_real (nc_time, "dt",      dt      );
  putint   (nc_time, "nstep",   nstep   );
  putint   (nc_time, "navg",    navg    );
  putint   (nc_time, "nsave",   nsave   );
  putint   (nc_time, "nwrite",  nwrite  );
  
  putbool  (nc_ks, "ks",       ks       );
  putbool  (nc_ks, "write_ks", write_ks );
  put_real (nc_ks, "eps_ks",   eps_ks   );
  put_real (nc_ks, "ks_t0",    ks_t0    );
  put_real (nc_ks, "ks_tf",    ks_tf    );
  put_real (nc_ks, "ks_eps0",  ks_eps0  );
  put_real (nc_ks, "ks_epsf",  ks_epsf  );

  putbool  (nc_vp, "vp",         vp          );
  putbool  (nc_vp, "vp_closure", vp_closure  );
  putint   (nc_vp, "vp_alpha",   vp_alpha    );
  putint   (nc_vp, "vp_alpha_h", vp_alpha_h  );
  put_real (nc_vp, "vp_nu",      vp_nu       );
  put_real (nc_vp, "vp_nuh",     vp_nuh      );
  
  putbool  (nc_rst, "restart",           restart          );
  putbool  (nc_rst, "save_for_restart",  save_for_restart );  
  put_real (nc_rst, "scale",             scale            );

  putbool  (nc_diag, "all_zonal",    write_all_kmom    );
  putbool  (nc_diag, "vEy",          write_vEy         );
  putbool  (nc_diag, "kxvEy",        write_kxvEy       );
  putbool  (nc_diag, "kden",         write_kden        );
  putbool  (nc_diag, "kUpar",        write_kUpar       );
  putbool  (nc_diag, "kTpar",        write_kTpar       );
  putbool  (nc_diag, "kTperp",       write_kTperp      );
  putbool  (nc_diag, "kqpar",        write_kqpar       );

  putbool  (nc_diag, "all_non_zonal", write_all_xymom  );
  putbool  (nc_diag, "xyvEy",        write_xyvEy       );
  putbool  (nc_diag, "xykxvEy",      write_xykxvEy     );
  putbool  (nc_diag, "xyden",        write_xyden       );
  putbool  (nc_diag, "xyUpar",       write_xyUpar      );
  putbool  (nc_diag, "xyTpar",       write_xyTpar      );
  putbool  (nc_diag, "xyTperp",      write_xyTperp     );
  putbool  (nc_diag, "xyqpar",       write_xyqpar      );

  putbool  (nc_diag, "all_zonal_scalars", write_all_avgz);
  putbool  (nc_diag, "avg_zvE",      write_avg_zvE     );
  putbool  (nc_diag, "avg_zkxvEy",   write_avg_zkxvEy  );
  putbool  (nc_diag, "avg_zkden",    write_avg_zkden   );
  putbool  (nc_diag, "avg_zkUpar",   write_avg_zkUpar  );
  putbool  (nc_diag, "avg_zkTpar",   write_avg_zkTpar  );
  putbool  (nc_diag, "avg_zkTperp",  write_avg_zkTperp );
  putbool  (nc_diag, "avg_zkqpar",   write_avg_zkqpar  );

  putbool  (nc_diag, "omega",       write_omega        );
  putbool  (nc_diag, "fixed_amp",   fixed_amplitude    );
  putbool  (nc_diag, "free_energy", write_free_energy  );
  putbool  (nc_diag, "fluxes",      write_fluxes       );
  putbool  (nc_diag, "moms",        write_moms         );
  putbool  (nc_diag, "rh",          write_rh           );
  putbool  (nc_diag, "pzt",         write_pzt          );
  putbool  (nc_diag, "phi",         write_phi          );
  putbool  (nc_diag, "phi_kpar",    write_phi_kpar     );

  putint   (nc_expert, "nreal",   nreal);
  putint   (nc_expert, "i_share", i_share);
  putint   (nc_expert, "ikx_fixed",  ikx_fixed  );
  putint   (nc_expert, "iky_fixed",  iky_fixed  );
  putbool  (nc_expert, "eqfix",      eqfix      );
  putbool  (nc_expert, "init_single", init_single  );
  putbool  (nc_expert, "secondary",   secondary    );
  put_real (nc_expert, "phi_ext",     phi_ext      );
  putint   (nc_expert, "ikx_single",  ikx_single   );
  putint   (nc_expert, "iky_single",  iky_single   );
  put_real (nc_expert, "t0",          tp_t0        );
  put_real (nc_expert, "tf",          tp_tf        );
  put_real (nc_expert, "tprim0",      tprim0       );
  put_real (nc_expert, "tprimf",      tprimf       );

  putint   (nc_con,  "stages",          stages          );
  put_real (nc_con,  "cfl",             cfl             );
  put_real (nc_con,  "init_amp",        init_amp        );
  put_real (nc_con,  "kpar_init",       kpar_init       );
  putbool  (nc_con,  "random_init",     random_init     );
  putbool  (nc_con,  "nonlinear_mode",  nonlinear_mode  );   
  putint   (nc_con,  "smith_par_q",     smith_par_q     );
  putint   (nc_con,  "smith_perp_q",    smith_perp_q    );
  putbool  (nc_con,  "collisions",      collisions      );
  put_real (nc_con,  "fphi",            fphi            );
  put_real (nc_con,  "fapar",           fapar           );
  put_real (nc_con,  "fbpar",           fbpar           );
  
  putbool  (nc_diss, "hyper",           hyper           );
  put_real (nc_diss, "D_hyper",         D_hyper         );
  putbool  (nc_diss, "hypercollisions", hypercollisions );
  put_real (nc_diss, "nu_hyper_l",      nu_hyper_l      );
  put_real (nc_diss, "nu_hyper_m",      nu_hyper_m      );
  putint   (nc_diss, "nu_hyper",        nu_hyper        );
  putint   (nc_diss, "p_hyper",         p_hyper         );
  putint   (nc_diss, "p_hyper_l",       p_hyper_l       );
  putint   (nc_diss, "p_hyper_m",       p_hyper_m       );
  put_real (nc_diss, "D_HB",            D_HB            );
  putint   (nc_diss, "p_HB",            p_HB            );
  putbool  (nc_diss, "HB_hyper",        HB_hyper        );
  put_real (nc_diss, "w_osc",           w_osc           );
  
  put_real (nc_frc, "forcing_amp",      forcing_amp     );
  putint   (nc_frc, "forcing_index",    forcing_index   );
  putbool  (nc_frc, "forcing_init",     forcing_init    );
  putbool  (nc_frc, "no_fields",        no_fields       );
      
  //  putbool  (ncid, "snyder_electrons", snyder_electrons);

  putbool  (nc_geo, "slab",        slab       );
  putbool  (nc_geo, "const_curv",  const_curv );
  putint   (nc_geo, "igeo",        igeo       );
  put_real (nc_geo, "drhodpsi",    drhodpsi   );
  put_real (nc_geo, "kxfac",       kxfac      );
  put_real (nc_geo, "Rmaj",        rmaj       );
  put_real (nc_geo, "shift",       shift      );
  put_real (nc_geo, "eps",         eps        );
  put_real (nc_geo, "q",           qsf        );
  put_real (nc_geo, "shat",        shat       );
  put_real (nc_geo, "beta",        beta       );
  putbool  (nc_geo, "zero_shat",   zero_shat  );

  put_wspectra (nc_sp, wspectra); 
  put_pspectra (nc_sp, pspectra); 
  put_aspectra (nc_sp, aspectra); 
  putspec (nc_spec, nspec_in, species_h);
  
  if(nz_in != 1) {
    int ntgrid = nz_in/2 + (nperiod-1)*nz_in; 
    nz_in = 2*ntgrid; // force even
  }
  
  Zp = 2*nperiod - 1; // BD This needs updating
  
  // BD  This is messy. Prefer to go back to original method
  // before, jtwist_old assumed Zp=1
  // now, redefining jtwist = jtwist_old*Zp

  if (jtwist==0) {
    // this is an error
    printf("************************** \n");
    printf("************************** \n");
    printf("jtwist = 0 is not allowed! \n");
    printf("************************** \n");
    printf("************************** \n");
  }

  // if jtwist = -1 in the input file
  // set default jtwist to 2*pi*shat to get the x0 in the input file
  
  if (jtwist == -1) {
    if (!zero_shat) {
      jtwist = (int) round(2*M_PI*abs(shat)*Zp/y0*x0);  // Use Zp or 1 here?
    } else {
      // no need to do anything here. x0 is set from input file and jtwist should not be used anywhere
    }
    if (jtwist == 0) jtwist = 1;  // just to be safe
  }   

  // now set x0 to be consistent with jtwist. Two cases: ~ zero shear, and otherwise
  if (!zero_shat) {
    x0 = y0 * jtwist/(2*M_PI*Zp*abs(shat));  
  }

  // record the values of jtwist and x0 used in runname.nc
  putint (nc_dom, "jtwist", jtwist);
  put_real (nc_dom, "x0", x0);
     
  //  if(strcmp(closure_model, "beer4+2")==0) {
  closure_model_opt = Closure::none   ;
  if( closure_model == "beer4+2") {
    printf("\nUsing Beer 4+2 closure model. Overriding nm=4, nl=2\n\n");
    nm_in = 4;
    nl_in = 2;
    closure_model_opt = Closure::beer42;
  } else if (closure_model == "smith_perp") { closure_model_opt = Closure::smithperp;
  } else if (closure_model == "smith_par")  { closure_model_opt = Closure::smithpar; 
  }

  if( boundary == "periodic") { boundary_option_periodic = true;
  } else { boundary_option_periodic = false; }
  
  local_limit = false;
  if(qsf < 0  &&  nz_in == 1) { local_limit=true; }

  if     ( init_field == "density") { initf = inits::density; }
  else if( init_field == "upar"   ) { initf = inits::upar   ; }
  else if( init_field == "tpar"   ) { initf = inits::tpar   ; }
  else if( init_field == "tperp"  ) { initf = inits::tperp  ; }
  else if( init_field == "qpar"   ) { initf = inits::qpar   ; }
  else if( init_field == "qperp"  ) { initf = inits::qperp  ; }
  
  if     ( stir_field == "density") { stirf = stirs::density; }
  else if( stir_field == "upar"   ) { stirf = stirs::upar   ; }
  else if( stir_field == "tpar"   ) { stirf = stirs::tpar   ; }
  else if( stir_field == "tperp"  ) { stirf = stirs::tperp  ; }
  else if( stir_field == "qpar"   ) { stirf = stirs::qpar   ; }
  else if( stir_field == "qperp"  ) { stirf = stirs::qperp  ; }
  else if( stir_field == "ppar"   ) { stirf = stirs::ppar   ; }
  else if( stir_field == "pperp"  ) { stirf = stirs::pperp  ; }
  
  if (scheme == "sspx3") scheme_opt = Tmethod::sspx3;
  if (scheme == "g3")    scheme_opt = Tmethod::g3;
  if (scheme == "k10")   scheme_opt = Tmethod::k10;
  if (scheme == "k2")    scheme_opt = Tmethod::k2;
  if (scheme == "rk4")   scheme_opt = Tmethod::rk4;
  if (scheme == "sspx2") scheme_opt = Tmethod::sspx2;
  if (scheme == "rk2")   scheme_opt = Tmethod::rk2;

  if (eqfix && ((scheme_opt == Tmethod::k10) || (scheme_opt == Tmethod::g3)  || (scheme_opt == Tmethod::k2))) {
    printf("\n");
    printf("\n");
    printf(ANSI_COLOR_MAGENTA);
    printf("The eqfix option is not compatible with this time-stepping algorithm. \n");
    printf(ANSI_COLOR_GREEN);
    printf("The eqfix option is not compatible with this time-stepping algorithm. \n");
    printf(ANSI_COLOR_RED);
    printf("The eqfix option is not compatible with this time-stepping algorithm. \n");
    printf(ANSI_COLOR_BLUE);
    printf("The eqfix option is not compatible with this time-stepping algorithm. \n");
    printf(ANSI_COLOR_RESET);    
    printf("\n");
    printf("\n");
  }  
  //  printf("scheme_opt = %d \n",scheme_opt);
    
  if( source == "phiext_full") {
    source_option = PHIEXT;
    printf("Running Rosenbluth-Hinton zonal flow calculation\n");
  }

  if(hypercollisions) printf("Using hypercollisions.\n");
  if(hyper) printf("Using hyperdiffusion.\n");

  if(debug) printf("nspec_in = %i \n",nspec_in);

  nspec = nspec_in;
  init_species(species_h);
  initialized = true;
  printf(ANSI_COLOR_RESET);    
}

void Parameters::init_species(specie* species)
{
  for(int s=0; s<nspec_in; s++) {
    species[s].vt   = sqrt(species[s].temp / species[s].mass);
    species[s].tz   = species[s].temp / species[s].z;
    species[s].zt   = species[s].z / species[s].temp;
    species[s].rho2 = species[s].temp * species[s].mass / (species[s].z * species[s].z);
    species[s].nt   = species[s].dens * species[s].temp;
    species[s].qneut= species[s].dens * species[s].z * species[s].z / species[s].temp;
    species[s].nz   = species[s].dens * species[s].z;
    species[s].as   = species[s].nz * species[s].vt;
    if (debug) {
      printf("species = %d \n",s);
      printf("mass, z, temp, dens = %f, %f, %f, %f \n",
	     species[s].mass, species[s].z, species[s].temp, species[s].dens);
      printf("vt, tz, zt = %f, %f, %f \n",
	     species[s].vt, species[s].tz, species[s].zt);
      printf("rho2, nt, qneut, nz = %f, %f, %f, %f \n \n",
	     species[s].rho2, species[s].nt, species[s].qneut, species[s].nz);
    }      
  }
}

int Parameters::getint (int ncid, const char varname[]) {
  int idum, retval, res;
  if (retval = nc_inq_varid(ncid, varname, &idum))   ERR(retval);
  if (retval = nc_get_var  (ncid, idum, &res)) ERR(retval);
  //  if (debug) printf("%s = %i \n",varname, res);
  return res;
}

void Parameters::putint (int ncid, const char varname[], int val) {
  int idum, retval;
  if (debug) printf("%s = %i \n",varname, val);
  if (retval = nc_inq_varid(ncid, varname, &idum))   ERR(retval);
  if (retval = nc_put_var  (ncid, idum, &val)) ERR(retval);
}

void Parameters::putbool (int ncid, const char varname[], bool val) {
  int idum, retval;
  int b = val==true ? 1 : 0 ; 
  if (debug) printf("%s = %d \n",varname, b);
  if (retval = nc_inq_varid(ncid, varname, &idum))   ERR(retval);
  if (retval = nc_put_var  (ncid, idum, &b))       ERR(retval);
}

bool Parameters::getbool (int ncid, const char varname[]) {
  int idum, ires, retval;
  bool res;
  if (debug) printf("%s = %i \n", varname, ires);
  if (retval = nc_inq_varid(ncid, varname, &idum))   ERR(retval);
  if (retval = nc_get_var  (ncid, idum, &ires)) ERR(retval);
  res = (ires!=0) ? true : false ;
  return res;
}

float Parameters::get_real (int ncid, const char varname[]) {
  int idum, retval;
  float res;
  if (debug) printf("%s = %f \n",varname, res);
  if (retval = nc_inq_varid(ncid, varname, &idum))   ERR(retval);
  if (retval = nc_get_var  (ncid, idum, &res)) ERR(retval);
  return res;
}

void Parameters::put_real (int ncid, const char varname[], float val) {
  int idum, retval;
  if (debug) printf("%s = %f \n",varname, val);
  if (retval = nc_inq_varid(ncid, varname, &idum))   ERR(retval);
  if (retval = nc_put_var  (ncid, idum, &val)) ERR(retval);
}

void Parameters::put_wspectra (int ncid, std::vector<int> s) {

  int idum, retval;
  wspectra_start[0] = 0;
  wspectra_count[0] = nw_spectra;

  if (retval = nc_inq_varid(ncid, "wspectra", &idum))     ERR(retval);
  if (retval = nc_put_vara (ncid, idum, wspectra_start, wspectra_count, s.data())) ERR(retval);
}

void Parameters::put_pspectra (int ncid, std::vector<int> s) {

  int idum, retval;
  pspectra_start[0] = 0;
  pspectra_count[0] = np_spectra;

  if (retval = nc_inq_varid(ncid, "pspectra", &idum))     ERR(retval);
  if (retval = nc_put_vara (ncid, idum, pspectra_start, pspectra_count, s.data())) ERR(retval);
}

void Parameters::put_aspectra (int ncid, std::vector<int> s) {

  int idum, retval;
  aspectra_start[0] = 0;
  aspectra_count[0] = na_spectra;

  if (retval = nc_inq_varid(ncid, "aspectra", &idum))     ERR(retval);
  if (retval = nc_put_vara (ncid, idum, aspectra_start, aspectra_count, s.data())) ERR(retval);
}

void Parameters::putspec (int  ncid, int nspec, specie* spec) {
  int idum, retval;
  
  is_start[0] = 0;
  is_count[0] = nspec;

  // this stuff should all be in species itself!
  // reason for all this is basically legacy + cuda does not support <vector>
  
  std::vector <float> zs, ms, ns, Ts, Tps, nps, ups, nus;
  std::vector <int> types;
  
  for (int is=0; is<nspec; is++) {
    zs.push_back(spec[is].z);
    ms.push_back(spec[is].mass);
    ns.push_back(spec[is].dens);
    Ts.push_back(spec[is].temp);
    Tps.push_back(spec[is].tprim);
    nps.push_back(spec[is].fprim);
    ups.push_back(spec[is].uprim);
    nus.push_back(spec[is].nu_ss);
    types.push_back(spec[is].type);
  }
  float *z = &zs[0];
  float *m = &ms[0];
  float *n0 = &ns[0];
  float *T0 = &Ts[0];
  float *Tp = &Tps[0];
  float *np = &nps[0];
  float *up = &ups[0];
  float *nu = &nus[0];
  int *st = &types[0];
  
  if (retval = nc_inq_varid(ncid, "z", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, z))  ERR(retval);

  if (retval = nc_inq_varid(ncid, "m", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, m))  ERR(retval);

  if (retval = nc_inq_varid(ncid, "n0", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, n0))  ERR(retval);

  if (retval = nc_inq_varid(ncid, "n0_prime", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, np))  ERR(retval);

  if (retval = nc_inq_varid(ncid, "u0_prime", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, up))  ERR(retval);

  if (retval = nc_inq_varid(ncid, "T0", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, T0))  ERR(retval);

  if (retval = nc_inq_varid(ncid, "T0_prime", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, Tp))  ERR(retval);

  if (retval = nc_inq_varid(ncid, "nu", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, nu))  ERR(retval);

  if (retval = nc_inq_varid(ncid, "species_type", &idum))   ERR(retval);
  if (retval = nc_put_vara (ncid, idum, is_start, is_count, st))  ERR(retval);
}



