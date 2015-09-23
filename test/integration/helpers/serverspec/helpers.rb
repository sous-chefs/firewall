# helpers
def redhat?
  os[:family] == 'redhat'
end

def release?(test_version)
  os[:release] == test_version
end

def debian?
  %w(debian).include?(os[:family])
end

def ubuntu?
  %w(ubuntu).include?(os[:family])
end

def firewalld?
  redhat? && os[:release].to_f >= 7.0
end

def iptables?
  redhat? && os[:release].to_f < 7.0
end
