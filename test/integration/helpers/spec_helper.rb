# helpers
def firewalld?
  %w(fedora redhat suse).include?(os.family)
end

def ufw?
  os.name == 'ubuntu'
end

def iptables?
  !firewalld? && !ufw? && !nftables?
end

def nftables?
  os.name == 'debian'
end
