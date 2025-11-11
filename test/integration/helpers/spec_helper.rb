# helpers
def firewalld?
  %w(fedora redhat suse).include?(os.family)
end

def ufw?
  os.debian?
end

def iptables?
  !firewalld? && !ufw?
end
