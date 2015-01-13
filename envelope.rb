#!/usr/bin/env ruby

require 'rubygems'
require 'prawn'
require 'prawn/measurements'
require 'csv'
require 'getoptlong'

include Prawn::Measurements

class AddressSet
  attr_accessor :addresses

  def initialize
    @addresses = []
  end

  def add(address)
    @addresses << address
  end
end

class Address
  attr_accessor :names, :addresses, :city, :state, :postal_code, :country

  def initialize
    @names = []
    @addresses = []
  end

  def to_s
    if names[1].length == 3 or (names[1][0] != '???' and names[1][1] == '???')
      if names[0][2] == names[1][2] or (names[0][0] == 'Mr.' and names[1][0] == 'Mrs.')
        if names[1][1] == '???'
          name = "#{names[0][0]} and #{names[1][0]} #{names[0][1]} #{names[0][2]}"
        else
          name = "#{names[0].join(' ')} and #{names[1].join(' ')}"
        end
      else
        name = "#{names[0].join(' ')}\n#{names[1].join(' ')}"
      end
    else
      if names[1].length == 2 and names[1][1] == '???'
        name = "#{names[0].join(' ')} and Guest"
      else
        name = "#{names[0].join(' ')}"
      end
    end

    <<-EOF
#{name}
#{addresses[0]}#{addresses[1] ? (', ' + addresses[1]) : ''}
#{city}#{state ? (', ' + state) : ''} #{postal_code} #{country == 'US' ? '' : country}
    EOF
  end
end

def usage
  puts <<-EOF
#{__FILE__} [OPTION] ... CSV

-h, --help:         Show usage
-o, --out:          Output file for PDF

CSV: The file to read addresses from
  EOF

  return -1
end

def main
  opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--out', '-o', GetoptLong::REQUIRED_ARGUMENT ]
  )

  outfile = nil
  opts.each do |opt, arg|
    case opt
      when '--help'
        return usage

      when '--out'
        outfile = arg
    end
  end

  if ARGV.length != 1
    puts 'Missing address CSV'
    return usage
  end

  unless outfile
    puts 'No output file specified'
    return usage
  end

  addresses = AddressSet.new

  csv_file = ARGV.shift
  CSV.foreach(csv_file, headers: true) do |row|
    address = Address.new
    address.names = [row['Primary Salutation']] + row['Primary'].split(' ', 2), [row['+1 Salutation']] + (row['+1'] ? row['+1'] : '').split(' ', 2)
    address.addresses = [row['Address 1'], row['Address 2']]
    address.city = row['City']
    address.state = row['State']
    address.postal_code = row['Zip Code']
    address.country = row['Country']
    addresses.add address
  end

  Prawn::Document.generate(outfile, page_size: [in2pt(5.5)] * 2, options: { optimize_objects: false }) do
    font './Futura_0.ttf'

    addresses.addresses.each do |address|
      bounding_box [0, 162], width: 324, height: 288 do
        text address.to_s, size: 12, align: :center
      end

      start_new_page
    end
  end

  return 0
end

if __FILE__ == $0
  exit main
end
