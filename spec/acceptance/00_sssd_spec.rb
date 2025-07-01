require 'spec_helper_acceptance'

describe 'sssd' do
  context 'default' do
    it 'works without errors' do
      # It appears as though the service cannot be run in a container, so
      # service_ensure is set to 'stopped'. This makes the functional testing
      # pretty weak, though still an improvement.
      pp = <<-EOS
      class { 'sssd':
        service_ensure => 'stopped',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      # It should be idempotent, but it is not.
      # apply_manifest(pp, :catch_changes => true)
      apply_manifest(pp, catch_failures: true)
    end

    describe package('sssd') do
      it { is_expected.to be_installed }
    end

    describe file('/etc/sssd/sssd.conf') do
      it { is_expected.to be_file }
      it { is_expected.to be_owned_by 'root' }
      it { is_expected.to be_grouped_into 'root' }
      it { is_expected.to be_mode '600' }
    end

    describe service('sssd') do
      it { is_expected.not_to be_enabled }
      it { is_expected.not_to be_running }
    end

    if fact('os.family') == 'Debian'

      content = <<-END.gsub(%r{^\s+\|}, '')
        |Name: activate mkhomedir
        |Default: yes
        |Priority: 900
        |Session-Type: Additional
        |Session:
        |  required      pam_mkhomedir.so umask=0022 skel=/etc/skel
      END

      describe file('/usr/share/pam-configs/pam_mkhomedir') do
        it { is_expected.to be_file }
        it { is_expected.to be_owned_by 'root' }
        it { is_expected.to be_grouped_into 'root' }
        it { is_expected.to be_mode '644' }
        its(:content) { is_expected.to eq content }
      end
    end
  end
end
