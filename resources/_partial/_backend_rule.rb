# frozen_string_literal: true

unified_mode true

property :direction, Symbol, equal_to: [:in, :out, :pre, :post], default: :in
property :logging, Symbol, equal_to: [:connections, :packets]
property :interface, String
property :dest_interface, String
property :stateful, [Symbol, Array]
property :include_comment, [true, false], default: true
property :program, String
property :service, String
property :raw, String
property :notify_firewall, [true, false], default: true
