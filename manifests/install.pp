# Class: mesos::install
#
# This class manages Mesos package installation.
#
# Parameters:
# [*ensure*] - 'present' for installing any version of Mesos
#   'latest' or e.g. '0.15' for specific version
#
# Sample Usage: is not meant for standalone usage, class is
# required by 'mesos::master' and 'mesos::slave'
#
class mesos::install(
  String               $ensure                  = 'present',
  Boolean              $manage_repo             = true,
  Variant[String,Hash] $repo_source             = {},
  Boolean              $manage_python           = false,
  String               $python_package          = 'python',
  Boolean              $remove_package_services = false,
) {
  # 'ensure_packages' requires puppetlabs/stdlib
  #
  # linux containers are now implemented natively
  # with usage of cgroups, requires kernel >= 2.6.24
  #
  # Python is required for web GUI (mesos could be build without GUI)
  if $manage_python {
    ensure_resource('package', [$python_package],
      {'ensure' => 'present', 'require' => Package['mesos']}
    )
  }

  if $manage_repo and !empty($repo_source) {
    class {'mesos::repo':
      source => $repo_source,
    }
    Package<| title == 'mesos' |> {
      require => Class['mesos::repo']
    }
  }

  # a debian (or other binary package) must be available,
  # see https://github.com/deric/mesos-deb-packaging
  # for Debian packaging
  package { 'mesos':
    ensure  => $ensure
  }

  if ($remove_package_services and $::osfamily == 'redhat' and $::operatingsystemmajrelease == '6') {
    file { [
      '/etc/init/mesos-master.conf', '/etc/init/mesos-slave.conf'
    ]:
      ensure  => absent,
      require => Package['mesos'],
    }
  }
}
