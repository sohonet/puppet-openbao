#
# @summary This class is called from openbao for service config
#
# @api private
#
class openbao::config {
  assert_private()
  if $openbao::manage_config_dir {
    file { $openbao::config_dir:
      ensure  => directory,
      purge   => $openbao::purge_config_dir,
      recurse => $openbao::purge_config_dir,
      owner   => $openbao::user,
      group   => $openbao::group,
    }
  }

  if $openbao::manage_config_file {
    case $openbao::mode {
      'server': {
        $_config_hash = delete_undef_values({
            'listener'          => $openbao::listener,
            'storage'           => $openbao::storage,
            'ha_storage'        => $openbao::ha_storage,
            'seal'              => $openbao::seal,
            'telemetry'         => $openbao::telemetry,
            'disable_cache'     => $openbao::disable_cache,
            'default_lease_ttl' => $openbao::default_lease_ttl,
            'max_lease_ttl'     => $openbao::max_lease_ttl,
            'ui'                => $openbao::enable_ui,
            'api_addr'          => $openbao::api_addr,
        })
      }
      'agent': {
        $_config_hash = delete_undef_values({
            'openbao'             => $openbao::agent_openbao,
            'auto_auth'         => $openbao::agent_auto_auth,
            'api_proxy'         => $openbao::agent_api_proxy,
            'cache'             => $openbao::agent_cache,
            'listener'          => $openbao::agent_listeners,
            'template'          => $openbao::agent_template,
            'template_config'   => $openbao::agent_template_config,
            'exec'              => $openbao::agent_exec,
            'env_template'      => $openbao::agent_env_template,
            'telemetry'         => $openbao::agent_telemetry,
        })
      }
      default: {
        fail("Unsupported openbao mode: ${openbao::mode}")
      }
    }

    $config_hash = $_config_hash + $openbao::extra_config

    file { "${openbao::config_dir}/openbao.hcl":
      content => stdlib::to_json_pretty($config_hash),
      owner   => $openbao::user,
      group   => $openbao::group,
      mode    => $openbao::config_mode,
    }

    # If manage_storage_dir is true and a file or raft storage backend is
    # configured, we create the directory configured in that backend.
    #
    if $openbao::manage_storage_dir {
      if $openbao::storage['file'] {
        $_storage_backend = 'file'
      } elsif $openbao::storage['raft'] {
        $_storage_backend = 'raft'
      } else {
        fail('Must provide a valid storage backend: file or raft')
      }

      if $openbao::storage[$_storage_backend]['path'] {
        file { $openbao::storage[$_storage_backend]['path']:
          ensure => directory,
          owner  => $openbao::user,
          group  => $openbao::group,
        }
      } else {
        fail("Must provide a path attribute to storage ${_storage_backend}")
      }
    }
  }

  if $openbao::manage_service_file {
    case $openbao::service_provider {
      'systemd': {
        systemd::unit_file { 'openbao.service':
          content => epp('openbao/openbao.systemd'),
        }
      }
      default: {
        fail("openbao::service_provider '${openbao::service_provider}' is not valid")
      }
    }
  }
}
