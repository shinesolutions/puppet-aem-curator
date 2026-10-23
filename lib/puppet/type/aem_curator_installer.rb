# frozen_string_literal: true

# Ported from bstopp/aem 3.0.0 lib/puppet/type/aem_installer.rb (Apache-2.0,
# Copyright (C) 2015-2016 Bryan Stopp, see NOTICE) because that module is
# unmaintained and incompatible with OpenVox 9. Behaviour is unchanged.
#
# Renamed from aem_installer to aem_curator_installer: type names are global, so
# this can't clash with bstopp/aem's aem_installer if both modules are on the
# modulepath during the transition, nor with the aem_resources aem_* types.

require 'pathname'

Puppet::Type.newtype(:aem_curator_installer) do
  @doc = <<~DOC
    This is a private type intended to start, monitor, and stop an AEM instance, insuring
     the repository is created.
  DOC

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the AEM Instance.'

    munge(&:downcase)

    def insync?(is_val)
      is_val.casecmp(should).zero?
    end
  end

  newproperty(:home) do
    desc 'The home directory of the AEM installation.'
    def insync?(is_val)
      unless is_val == should
        warning("Home cannot be modified after installation. [Existing = #{is_val}, New = #{should}]")
      end
      true
    end

    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise(Puppet::ResourceError, "AEM Home must be fully qualified, not '#{value}'")
      end
    end
  end

  newparam(:snooze) do
    desc 'Snooze value for wait when monitoring for AEM state transition during installation.
          Value is in seconds; default = 10 seconds'

    newvalues(%r{^\d+$})

    munge(&:to_i)
  end

  newparam(:timeout) do
    desc 'Timeout for the start process when monitoring for start and stop.
          If the system does not enter the necessary state by the timeout, an error is raised.
          Value is in seconds. Default = 10 minutes'

    newvalues(%r{^\d+$})

    munge(&:to_i)
  end

  autorequire(:file) do
    autos = []
    autos << self[:home] if self[:home] && absolute_path?(self[:home])
    autos
  end

  [:user, :group].each do |type|
    autorequire(type) do
      if @parameters.include?(type)
        val = @parameters[type]
        val
      end
    end
  end

  validate do
    raise(Puppet::ResourceError, 'AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end
end
