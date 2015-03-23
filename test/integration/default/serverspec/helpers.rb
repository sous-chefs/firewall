# helpers
def redhat?
  os[:family] == 'redhat'
end

def redhat?
  os[:family] == 'redhat'
end

def debian?
  %w(debian ubuntu).include?(os[:family])
end

def firewalld?
  redhat? && os[:release].to_f >= 7.0
end

def iptables?
  redhat? && os[:release].to_f < 7.0
end

def ufw?
  debian?
end
