# frozen_string_literal: true

# helpers
def firewalld?
  %w(amazon fedora redhat suse).include?(os.family)
end

def ufw?
  os.debian?
end

def iptables?
  !firewalld? && !ufw?
end
