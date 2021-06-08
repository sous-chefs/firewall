# helpers
def firewalld?
  os.redhat? && os[:release].to_f >= 7.0
end

def iptables?
  (os.redhat? && os[:release].to_f < 7.0)
end
