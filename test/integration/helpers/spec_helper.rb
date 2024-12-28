# helpers
def firewalld?
  %w(redhat suse).include?(os.family)
end

def ufw?
  os.debian?
end

def iptables?
  !firewalld? && !ufw?
end
