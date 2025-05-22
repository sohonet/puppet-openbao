#
# @summary install openbao
#
# @param user Customise the user openbao runs as, will also create the user unless `manage_user` is false.
#
# @param manage_user Whether or not the module should create the user.
#
# @param group Customise the group openbao runs as, will also create the user unless `manage_group` is false.
#
# @param manage_group Whether or not the module should create the group.
#
# @param bin_dir Directory the openbao executable will be installed in.
#
# @param config_dir Directory the openbao configuration will be kept in.
#
# @param config_mode Mode of the configuration file (openbao.hcl). Defaults to '0750'
#
# @param purge_config_dir Whether the `config_dir` should be purged before installing the generated config.
#
# @param download_url Manual URL to download the openbao zip distribution from.
#
# @param download_url_base base URL to download openbao zip distribution from.
#
# @param download_extension The extension of the openbao download
#
# @param service_name Customise the name of the system service
#
# @param service_provider Customise the name of the system service provider; this
#   also controls the init configuration files that are installed.
#
# @param service_options Extra argument to pass to `bao server`, as per: `bao server --help`
#
# @param manage_repo Configure the upstream HashiCorp repository. Only relevant when $nomad::install_method = 'repo'.
#
# @param manage_service Instruct puppet to manage service or not
#
# @param num_procs
#   Sets the GOMAXPROCS environment variable, to determine how many CPUs Vault
#   can use. The official Vault Terraform install.sh script sets this to the
#   output of ``nprocs``, with the comment, "Make sure to use all our CPUs,
#   because Vault can block a scheduler thread". Default: number of CPUs
#   on the system, retrieved from the ``processorcount`` Fact.
#
# @param api_addr
#   Specifies the address (full URL) to advertise to other Vault servers in the
#   cluster for client redirection. This value is also used for plugin backends.
#   This can also be provided via the environment variable VAULT_API_ADDR. In
#   general this should be set as a full URL that points to the value of the
#   listener address
#
# @param version The version of Vault to install
#
# @param mode Whether to start bao in 'server' or 'agent' mode
# @param extra_config Hash containing extra configuration options to merge with the generated config
# @param enable_ui Whether to enable the Vault web UI
# @param arch System architecture for the Vault binary (automatically determined)
# @param os Operating system for the Vault binary (automatically determined)
# @param manage_download_dir Whether to manage the download directory
# @param download_dir Directory where the Vault archive will be downloaded
# @param package_ensure The state the package should be in (installed, absent, latest)
# @param package_name Name of the Vault package
# @param install_method Installation method: 'archive' or 'repo'
# @param manage_file_capabilities Whether to manage Linux file capabilities for bao binary
# @param disable_mlock Whether to disable the memory lock capability
# @param max_lease_ttl Specifies the maximum possible lease duration for tokens and secrets
# @param default_lease_ttl Specifies the default lease duration for tokens and secrets
# @param telemetry Hash containing Vault telemetry configuration
# @param disable_cache Disable caching
# @param seal Hash containing seal configuration options
# @param ha_storage Hash containing storage configuration for HA setup
# @param listener Hash or Array of hashes containing listener configuration
# @param manage_storage_dir Whether to manage the storage directory
# @param storage Hash containing storage configuration
# @param manage_service_file Whether to manage the service file
# @param service_ensure Desired state of the Vault service (running, stopped)
# @param service_enable Whether to enable the Vault service on boot
# @param manage_config_file Whether to manage the Vault config file
# @param download_filename Filename for the downloaded archive
# @param manage_config_dir Whether to manage the configuration directory
#
# Agent specific parameters
# @param agent_openbao Hash containing Vault server connection configuration for agent mode
# @param agent_auto_auth Hash containing auto-auth configuration for agent mode
# @param agent_api_proxy Hash containing API proxy configuration for agent mode
# @param agent_cache Hash containing cache configuration for agent mode
# @param agent_listeners Array of hashes containing listener configuration for agent mode
# @param agent_template Hash containing template configuration for agent mode
# @param agent_template_config Hash containing template engine configuration for agent mode
# @param agent_exec Hash containing exec configuration for agent mode
# @param agent_env_template Hash containing environment template configuration for agent mode
# @param agent_telemetry Hash containing telemetry configuration for agent mode
class openbao (
  $user                                  = 'openbao',
  $manage_user                           = true,
  $group                                 = 'openbao',
  $manage_group                          = true,
  $bin_dir                               = $openbao::params::bin_dir,
  $manage_config_file                    = true,
  Enum['server', 'agent'] $mode          = 'server',
  $config_mode                           = '0750',
  $purge_config_dir                      = true,
  $download_url                          = undef,
  $download_url_base                     = 'https://github.com/openbao/openbao/releases/download',
  $download_extension                    = 'tar.gz',
  $service_name                          = 'openbao',
  $service_enable                        = true,
  $service_ensure                        = 'running',
  $service_provider                      = $facts['service_provider'],
  Boolean $manage_repo                   = $openbao::params::manage_repo,
  $manage_service                        = true,
  Optional[Boolean] $manage_service_file = $openbao::params::manage_service_file,
  Hash $storage                          = { 'file' => { 'path' => '/var/lib/openbao' } },
  $manage_storage_dir                    = false,
  Variant[Hash, Array[Hash]] $listener   = { 'tcp' => { 'address' => '127.0.0.1:8200', 'tls_disable' => 1 }, },
  Optional[Hash] $ha_storage             = undef,
  Optional[Hash] $seal                   = undef,
  Optional[Boolean] $disable_cache       = undef,
  Optional[Hash] $telemetry              = undef,
  Optional[String] $default_lease_ttl    = undef,
  Optional[String] $max_lease_ttl        = undef,
  $disable_mlock                         = undef,
  $manage_file_capabilities              = undef,
  $service_options                       = '',
  $num_procs                             = $facts['processors']['count'],
  $install_method                        = $openbao::params::install_method,
  $config_dir                            = if $install_method == 'repo' and $manage_repo { '/etc/openbao.d' } else { '/etc/openbao' },
  $package_name                          = 'bao',
  $package_ensure                        = 'installed',
  $download_dir                          = '/tmp',
  $manage_download_dir                   = false,
  $download_filename                     = 'openbao.tar.gz',
  $version                               = 'v2.2.1',
  $os                                    = $facts['kernel'],
  $arch                                  = $openbao::params::arch,
  Optional[Boolean] $enable_ui           = undef,
  Optional[String] $api_addr             = undef,
  Hash $extra_config                     = {},
  Boolean $manage_config_dir             = $install_method == 'archive',
  # Agent specific parameters
  Optional[Hash] $agent_openbao          = undef,
  Optional[Hash] $agent_auto_auth        = undef,
  Optional[Hash] $agent_api_proxy        = undef,
  Optional[Hash] $agent_cache            = undef,
  Optional[Array[Hash]] $agent_listeners = undef,
  Optional[Hash] $agent_template         = undef,
  Optional[Hash] $agent_template_config  = undef,
  Optional[Hash] $agent_exec             = undef,
  Optional[Hash] $agent_env_template     = undef,
  Optional[Hash] $agent_telemetry        = undef,
) inherits openbao::params {
  $stub_ver = regsubst($version, '^v', '')
  # lint:ignore:140chars
  $real_download_url = pick($download_url, "${download_url_base}/${version}/${package_name}_${stub_ver}_${os}_${arch}.${download_extension}")
  # lint:endignore

  contain openbao::install
  contain openbao::config
  contain openbao::service

  Class['openbao::install'] -> Class['openbao::config']
  Class['openbao::config'] ~> Class['openbao::service']
}
