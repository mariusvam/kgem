name = 'ParseTree'

# res = %x{ gem list #{name} -a -r }
res = <<EOF
ParseTree (3.0.6, 3.0.5, 3.0.4, 3.0.3 ruby x86-mingw32 x86-mswin32-60, 3.0.2 ruby x86-mingw32 x86-mswin32-60, 3.0.1 ruby x86-mingw32 x86-mswin32-60, 3.0.0, 2.2.0, 2.1.1, 2.1.0, 2.0.2, 2.0.1, 2.0.0, 1.7.1, 1.7.0, 1.6.4, 1.6.3, 1.6.2, 1.6.1, 1.6.0, 1.5.0, 1.4.1, 1.4.0, 1.3.7, 1.3.6, 1.3.5, 1.3.4, 1.3.3, 1.3.2, 1.3.0, 1.2.0, 1.1.1, 1.1.0)
ParseTreeReloaded (0.0.1)
EOF
puts res
res =~ /#{Regexp.escape(name)}\s+\(([^\)]+)\)/
res = $1.split(/,\s+/).map { |v| v.split(/ /).first.strip }
puts res.inspect
