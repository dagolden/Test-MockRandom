use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Test::MockRandom',
      create_makefile_pl => "traditional",
      create_readme => 0,
      license         => 'perl',
      requires => {
          perl => 5.004,
          Test::More => 0.45, # threadsafe
      },
	)->create_build_script;
