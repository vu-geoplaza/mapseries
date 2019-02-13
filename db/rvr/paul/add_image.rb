require 'csv'

files = File.readlines('db/rvr/dir.txt')
files_lower = []
files_lower_gj = []
files_lower_gn = []
files_lower_gp = []
files_lower_lw = []
images = []
files.each do |file|
  #files_lower.push(file.downcase.gsub('bergen-op-zoom','bergen op zoom').gsub(' - ','-').strip())p
  path = file.split('/')[0] + '/' + file.split('/')[1]
  fname = file.split('/')[2]
  fbase = fname[0...-5]

  fext = fname.strip().split('.')[1]
  #puts 'fname:  ' + fname
  files_lower.push(path.downcase + '/' + fbase.downcase.tr('^a-z0-9', ''))

  files_lower_lw.push(path.downcase + '/' + fbase.downcase.split.last.tr('^a-z0-9', ''))

  files_lower_gj.push(path.downcase + '/' + fbase.downcase.tr('^a-z0-9', '')[0...-4])

  files_lower_gn.push(path.downcase + '/' + fbase.downcase.tr('^a-z', '')[0...-4])

  files_lower_gp.push(fbase.downcase.tr('^a-z0-9', ''))

  images.push(file.strip())
end
cop = files_lower

raster_folder = {'EERSTE DRUK' => 'eerste_druk', 'EERSTE HERZIENING' => 'eerste_herziening', '“DE VASSEN-HERZIENING”' => 'vassen_herziening',
                 'TWEEDE HERZIENING' => 'tweede_herziening'}

db = CSV.read("db/rvr/paul/Database rivierkaarten.txt", {headers: true, col_sep: ';', quote_char: '"'})
n = 0
db.each do |row|
  nr = row['nr'].downcase
  if nr == '-'
    fnr = '00'
  elsif nr[0] == 'S'
    fnr = nr
  elsif nr[1] == 'a'
    fnr = '%02da' % nr[0]
  elsif nr.length == 1
    fnr = '%02d' % nr
  else
    fnr = nr
  end

  editie = row['editie'].nil? ? '' : row['editie']
  jvu = row['jaar van uitgave'].nil? ? '' : row['jaar van uitgave']
  serie = row['serie'].nil? ? '' : row['serie']
  titel = row['titel'].nil? ? ' - ' : row['titel']

  tmp = sprintf('%s/serie_%s/%s%s%s%s' % [raster_folder[row['serie_editie']],
                                          serie.downcase.tr(' ', '_'),
                                          fnr.downcase,
                                          titel.downcase.tr('^a-z0-9', ''),
                                          editie.downcase.tr('^a-z0-9', ''),
                                          jvu[0..3].downcase.tr('^a-z0-9', '')])

  tmp_lw = sprintf('%s/serie_%s/%s' % [raster_folder[row['serie_editie']],
                                       serie.downcase.tr(' ', '_'),
                                       titel.downcase.split.last.tr('^a-z0-9', ''),
  ])

  tmp_gj = sprintf('%s/serie_%s/%s%s%s' % [raster_folder[row['serie_editie']],
                                           serie.downcase.tr(' ', '_'),
                                           fnr.downcase,
                                           titel.downcase.tr('^a-z0-9', ''),
                                           editie.downcase.tr('^a-z0-9', '')])

  tmp_gn = sprintf('%s/serie_%s/%s%s' % [raster_folder[row['serie_editie']],
                                         serie.downcase.tr(' ', '_'),
                                         titel.downcase.tr('^a-z0-9', ''),
                                         editie.downcase.tr('^a-z0-9', '')])

  tmp_gja = sprintf('%s/serie_%s/%sa%s%s' % [raster_folder[row['serie_editie']],
                                             serie.downcase.tr(' ', '_'),
                                             fnr.downcase,
                                             titel.downcase.tr('^a-z0-9', ''),
                                             editie.downcase.tr('^a-z0-9', '')])

  tmp_gjb = sprintf('%s/serie_%s/%sb%s%s' % [raster_folder[row['serie_editie']],
                                             serie.downcase.tr(' ', '_'),
                                             fnr.downcase,
                                             titel.downcase.tr('^a-z0-9', ''),
                                             editie.downcase.tr('^a-z0-9', '')])

  tmp_gp = sprintf('%s%s%s%s' % [fnr.downcase,
                                 titel.downcase.tr('^a-z0-9', ''),
                                 editie.downcase.tr('^a-z0-9', ''),
                                 jvu[0..3].downcase.tr('^a-z0-9', '')])

  tmp_gp2 = sprintf('%sa%s%s%s' % [fnr.downcase,
                                   titel.downcase.tr('^a-z0-9', ''),
                                   editie.downcase.tr('^a-z0-9', ''),
                                   jvu[0..3].downcase.tr('^a-z0-9', '')])
  tmp_gp3 = sprintf('%sb%s%s%s' % [fnr.downcase,
                                   titel.downcase.tr('^a-z0-9', ''),
                                   editie.downcase.tr('^a-z0-9', ''),
                                   jvu[0..3].downcase.tr('^a-z0-9', '')])

  index = files_lower.index(tmp)
  if index.nil?
    index = files_lower.index(tmp.gsub('rheenen', 'rhenen').gsub('behoorende', 'behorende'))
  end
  if index.nil?
    index = files_lower.index(tmp.gsub('ad', 'aande')) # krimpen a/d lek
  end
  if index.nil?
    index = files_lower_gj.index(tmp_gj)
  end
  if index.nil?
    index = files_lower_gj.index(tmp_gja)
  end
  if index.nil?
    index = files_lower_gj.index(tmp_gjb)
  end
  if index.nil?
    index = files_lower_gp.index(tmp_gp)
  end
  if index.nil?
    index = files_lower_lw.index(tmp_lw)
  end
  if index.nil?
    index = files_lower_gp.index(tmp_gp2)
  end
  if index.nil?
    index = files_lower_gp.index(tmp_gp3)
  end
  if index.nil?
    index = files_lower_gn.index(tmp_gn)
  end

  unless index.nil?
    row['image'] = images[index]
  else

    puts row['serie_editie'], serie, fnr, titel, editie, jvu[0..3]
    puts tmp, tmp_gj, tmp_gp, tmp_lw, tmp_gp2, tmp_gp3, tmp_gja, tmp_gjb
    row['image'] = ''

    n = n + 1
  end
end

puts n
#

CSV.open("db/rvr/paul/db_rivierkaarten_#{Date.today}.csv", "w") do |csv|
  csv << db.headers
  db.each {|row| csv << row}
end

# 15krimpenaandelekvierdeuitgave1935
# tweede_herziening/serie_2/15krimpenaandelekvierdeuitgave1935
# tweede_herziening/serie_2/15krimpenadlekvierdeuitgave1935
