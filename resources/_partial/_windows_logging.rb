# frozen_string_literal: true

property :windows_logging, Hash, default: {}, callbacks: {
  'must map :domain, :private or :public to hashes of :allowed and :blocked booleans' => lambda { |profiles|
    profiles.all? do |profile, flags|
      %i(domain private public).include?(profile) && flags.is_a?(Hash) &&
        flags.all? { |flag, value| %i(allowed blocked).include?(flag) && [true, false].include?(value) }
    end
  },
}
