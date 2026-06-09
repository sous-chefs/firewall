# frozen_string_literal: true

unified_mode true

property :description,
         String,
         description: 'see description tag in firewalld configuration.'
property :forward_ports,
         [Array, String],
         description: 'array of (port, protocol, to-port, to-addr). See forward-port tag in firewalld configuration.',
         coerce: proc { |o| Array(o) }
property :icmp_blocks,
         [Array, String],
         description: 'array of icmp-blocks. See icmp-block tag in firewalld configuration.',
         coerce: proc { |o| Array(o) }
property :masquerade,
         [true, false],
         description: 'see masquerade tag in firewalld configuration.'
property :ports,
         [Array, String],
         description: 'array of port and protocol pairs, in `["PORT/PROTOCOL"]` format. See port tag in firewalld configuration.',
         coerce: proc { |o| Array(o) }
property :priority,
         Integer,
         description: 'see priority tag in firewalld configuration.'
property :protocols,
         [Array, String],
         description: 'array of protocols, see protocol tag in firewalld configuration.',
         coerce: proc { |o| Array(o) }
property :services,
         [Array, String],
         description: 'array of service names, see service tag in firewalld configuration.',
         coerce: proc { |o| Array(o) }
property :short,
         String,
         name_property: true,
         description: 'see short tag in firewalld configuration.'
property :source_ports,
         [Array, String],
         description: 'array of port and protocol pairs, in `["PORT/PROTOCOL"]` format. See source-port tag in firewalld configuration.',
         coerce: proc { |o| Array(o) }
property :target,
         String,
         description: 'see target attribute in firewalld configuration.'
property :version,
         String,
         description: 'see version attribute in firewalld configuration.'
