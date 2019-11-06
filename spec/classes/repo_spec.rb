require 'spec_helper'

describe 'mesos::repo', type: :class do
  shared_examples 'debian' do |family, operatingsystem, lsbdistcodename, puppet|
    let(:params) do
      {
        source: 'mesosphere'
      }
    end

    let(:facts) do
      {
        # still old fact is needed due to this
        # https://github.com/puppetlabs/puppetlabs-apt/blob/master/manifests/params.pp#L3
        osfamily: family,
        os: {
          family: family,
          name: operatingsystem,
          distro: { codename: lsbdistcodename },
          release: { major: '8', minor: '9', full: '8.9' }
        },
        puppetversion: puppet
      }
    end

    before(:each) do
      puppet_debug_override
    end

    it {
      is_expected.to contain_apt__source('mesos').with(
        'location' => "https://repos.mesosphere.io/#{operatingsystem.downcase}",
        'repos'    => 'main',
        'release'  => lsbdistcodename.to_s,
        'key'      => { 'id' => '81026D0004C44CF7EF55ADF8DF7D54CBE56151BF', 'server' => 'keyserver.ubuntu.com' },
        'include'  => { 'src' => false },
      )
    }

    it { is_expected.to contain_anchor('mesos::repo::begin').that_comes_before('Apt::Source[mesos]') }
    it { is_expected.to contain_apt__source('mesos').that_comes_before('Class[apt::update]') }
    it { is_expected.to contain_class('apt::update').that_comes_before('Anchor[mesos::repo::end]') }

    context 'undef source' do
      let(:params) do
        {
          source: nil
        }
      end

      it { is_expected.not_to contain_apt__source('mesos') }
      # it { is_expected.to contain_file('/etc/apt/sources.list.d/mesos.list').with({'ensure' => 'absent'}) }
    end
  end

  context 'on Debian based systems' do
    puppet = Puppet.version

    it_behaves_like 'debian', 'Debian', 'Debian', 'wheezy', puppet
    it_behaves_like 'debian', 'Debian', 'Ubuntu', 'precise', puppet
  end

  shared_examples 'redhat' do |family, operatingsystem, majrel, minrel|
    let(:params) do
      {
        source: 'mesosphere'
      }
    end

    let(:osrel) { majrel }
    let(:facts) do
      {
        # still old fact is needed due to this
        # https://github.com/puppetlabs/puppetlabs-apt/blob/master/manifests/params.pp#L3
        osfamily: family,
        os: {
          family: family,
          name: operatingsystem,
          release: { major: majrel, minor: minrel, full: "#{majrel}.#{minrel}" }
        },
        puppetversion: Puppet.version
      }
    end

    it {
      is_expected.to contain_package('mesosphere-el-repo').with(
        'ensure' => 'present',
        'provider' => 'rpm',
        'source'   => "https://repos.mesosphere.io/el/#{majrel}/noarch/RPMS/mesosphere-el-repo-#{majrel}-#{minrel}.noarch.rpm",
      )
    }

    it do
      is_expected.to contain_exec('yum-clean-expire-cache').with(
        command: 'yum clean expire-cache',
      )
    end

    context 'undef source' do
      let(:params) do
        {
          source: nil
        }
      end

      it { is_expected.not_to contain_package('mesosphere-el-repo') }
    end
  end

  context 'on RedHat based systems' do
    it_behaves_like 'redhat', 'RedHat', 'CentOS', '6', '2'
    it_behaves_like 'redhat', 'RedHat', 'RedHat', '7', '1'
  end

  # see: https://github.com/deric/puppet-mesos/issues/77
  context 'custom repository' do
    let(:params) do
      {
        'source' => {
          'location' => 'http://myrepo.example.com/debian',
          'release'  => 'stretch',
          'repos'    => 'main',
          'key'      => {
            'id'     => '99926D0004C44CF7EF55ADF8DF7D54CBE56151BF',
            'server' => 'keyserver.ubuntu.com'
          },
          'include' => {
            'src' => false
          }
        }
      }
    end

    let(:facts) do
      {
        # still old fact is needed due to this
        # https://github.com/puppetlabs/puppetlabs-apt/blob/master/manifests/params.pp#L3
        osfamily: 'Debian',
        os: {
          family: 'Debian',
          name: 'Debian',
          distro: { codename: 'stretch' },
          release: { major: '9', minor: '1', full: '9.1' }
        },
        puppetversion: Puppet.version
      }
    end

    it {
      is_expected.to contain_apt__source('mesos').with(
        'location' => 'http://myrepo.example.com/debian',
        'repos'    => 'main',
        'release'  => 'stretch',
        'key'      => { 'id' => '99926D0004C44CF7EF55ADF8DF7D54CBE56151BF', 'server' => 'keyserver.ubuntu.com' },
        'include'  => { 'src' => false },
      )
    }
  end

  context 'allow passing only values different from the default' do
    let(:params) do
      {
        'source' => {
          'key'      => {
            'id'     => '00026D0004C44CF7EF55ADF8DF7D54CBE56151BF',
            'server' => 'keyserver.example.com'
          }
        }
      }
    end
    let(:facts) do
      {
        # still old fact is needed due to this
        # https://github.com/puppetlabs/puppetlabs-apt/blob/master/manifests/params.pp#L3
        osfamily: 'Debian',
        os: {
          family: 'Debian',
          name: 'Debian',
          distro: { codename: 'stretch' },
          release: { major: '9', minor: '1', full: '9.1' }
        },
        puppetversion: Puppet.version
      }
    end

    it {
      is_expected.to contain_apt__source('mesos').with(
        'location' => 'https://repos.mesosphere.io/debian',
        'repos'    => 'main',
        'release'  => 'stretch',
        'key'      => { 'id' => '00026D0004C44CF7EF55ADF8DF7D54CBE56151BF', 'server' => 'keyserver.example.com' },
        'include'  => { 'src' => false },
      )
    }
  end

  context 'puppet 4.x' do
    let(:params) do
      {
        source: 'mesosphere'
      }
    end

    let(:facts) do
      {
        # still old fact is needed due to this
        # https://github.com/puppetlabs/puppetlabs-apt/blob/master/manifests/params.pp#L3
        osfamily: 'Debian',
        os: {
          family: 'Debian',
          name: 'Debian',
          distro: { codename: 'stretch' },
          release: { major: '9', minor: '1', full: '9.1' }
        },
        puppetversion: Puppet.version
      }
    end

    before(:each) do
      puppet_debug_override
    end

    it {
      is_expected.to contain_apt__source('mesos').with(
        'location' => 'https://repos.mesosphere.io/debian',
        'repos'    => 'main',
        'release'  => 'stretch',
        'key'      => { 'id' => '81026D0004C44CF7EF55ADF8DF7D54CBE56151BF', 'server' => 'keyserver.ubuntu.com' },
        'include'  => { 'src' => false },
      )
    }
  end

  context 'Ubuntu' do
    let(:facts) do
      {
        # still old fact is needed due to this
        # https://github.com/puppetlabs/puppetlabs-apt/blob/master/manifests/params.pp#L3
        osfamily: 'Debian',
        os: {
          family: 'Debian',
          name: 'Ubuntu',
          distro: { codename: 'xenial' },
          release: { major: '16.04', full: '16.04' }
        },
        puppetversion: Puppet.version
      }
    end

    let(:params) do
      {
        source: 'mesosphere'
      }
    end

    it {
      is_expected.to contain_apt__source('mesos').with(
        'location' => 'https://repos.mesosphere.io/ubuntu',
        'repos'    => 'main',
        'release'  => 'xenial',
        'key'      => { 'id' => '81026D0004C44CF7EF55ADF8DF7D54CBE56151BF', 'server' => 'keyserver.ubuntu.com' },
        'include'  => { 'src' => false },
      )
    }

  end
end
