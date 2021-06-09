# helpers
def firewalld?
  (os.redhat? && os[:release].to_i == 7) || os.name == 'amazon'
end

def iptables?
  (os.redhat? && (os[:release].to_i < 7 || os[:release].to_i >= 8)) && os.name != 'amazon'
end
