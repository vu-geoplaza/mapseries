require 'csv'

files = File.readlines('db/rvr/dir.txt')
files_lower = []
files_lower_gj = []
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
  files_lower_gp.push(fbase.downcase.tr('^a-z0-9', ''))

  images.push(file.strip())
end
cop = files_lower


raster_folder = {'EERSTE DRUK' => 'eerste_druk', 'EERSTE HERZIENING' => 'eerste_herziening', '“DE VASSEN-HERZIENING”' => 'vassen_herziening',
                 'TWEEDE HERZIENING' => 'tweede_herziening'}

parsed = {'editie' => nil, 'serie' => nil, 'serietekst' => nil, 'nr' => nil, 'titel' => nil, 'titel_aanv' => nil, 'uitgave' => nil, 'jaar' => nil, 'image' => nil}
bladen = false
sb = false
CSV.open("db/rvr/Bibliografie_rivierkaarten_#{Date.today}.csv", "w", headers: parsed.keys, write_headers: true) do |csv|
  n = 0
  File.readlines("db/rvr/Bibliografie_rivierkaarten.txt").each do |line|
    line = line.strip()
    #TWEEDE HERZIENING. SERIE 4
    /(?<editie>.+)\.\sSERIE\s(?<serienr>\dA?(\sEN\s\d)*)/ =~ line.upcase
    if serienr
      parsed.clear
      parsed['editie'] = editie
      parsed['serienr'] = serienr
      bladen = false
      sb = false
    else
      unless bladen
        /(?<a>(Kaarten|Kaartbladen))/ =~ line
        if a
          bladen = true
        else
          unless sb
            unless line == ''
              parsed['serietekst'] = line
              #puts line.split(' - ')
              sb = true
            end
          end
        end
      else
        # 1.	Westervoort (noord). 1927
        /^(?<nr>[^\.]{1,5})\.\s+(?<titel>.+)\.\s*(?<jaar>\[?\d{4}\]?(-\s?\d{4})?)/ =~ line
        unless titel
          /^(?<nr>[^\.]{1,5})\.\s+(?<titel>.+)/ =~ line
          jaar = '-'
        end
        unless titel
          /^(?<titel>.+)\.\s*(?<jaar>\d{4})/ =~ line
          nr = '-'
        end
        unless titel
          /^(?<titel>(- Lengteprofil en bladverdeeling|Titelblad).+)/ =~ line
          jaar = '-'
          nr = '-'
        end
        if titel
          /(?<t>.+)\((?<u>.+uitgave[^\)]*)\)(?<t2>.*)/ =~ titel
          if t
            titel2 = t + t2
            uitgave = u
          else
            titel2 = titel
            uitgave = '-'
          end
          ta = titel2.split(' / ')
          parsed['nr'] = nr
          parsed['titel'] = ta[0]
          parsed['titel_aanv'] = ta.count > 1 ? ta[1] : '-'
          parsed['uitgave'] = uitgave
          parsed['jaar'] = jaar

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

          tmp = sprintf('%s/serie_%s/%s%s%s%s' % [raster_folder[parsed['editie']],
                                                  parsed['serienr'].downcase.tr(' ', '_'),
                                                  fnr.downcase,
                                                  parsed['titel'].downcase.tr('^a-z0-9', ''),
                                                  parsed['uitgave'].downcase.tr('^a-z0-9', ''),
                                                  parsed['jaar'].downcase.tr('^a-z0-9', '')])

          tmp_lw = sprintf('%s/serie_%s/%s' % [raster_folder[parsed['editie']],
                                                  parsed['serienr'].downcase.tr(' ', '_'),
                                                  parsed['titel'].downcase.split.last.tr('^a-z0-9', ''),
                                                  ])

          tmp_gj = sprintf('%s/serie_%s/%s%s%s' % [raster_folder[parsed['editie']],
                                                   parsed['serienr'].downcase.tr(' ', '_'),
                                                   fnr.downcase,
                                                   parsed['titel'].downcase.tr('^a-z0-9', ''),
                                                   parsed['uitgave'].downcase.tr('^a-z0-9', '')])

          tmp_gp = sprintf('%s%s%s%s' % [fnr.downcase,
                                         parsed['titel'].downcase.tr('^a-z0-9', ''),
                                         parsed['uitgave'].downcase.tr('^a-z0-9', ''),
                                         parsed['jaar'].downcase.tr('^a-z0-9', '')])

          index = files_lower.index(tmp)
          if index.nil?
            index = files_lower.index(tmp.tr('rheenen','rhenen').tr('behoorende','behorende'))
          end
          if index.nil?
            index = files_lower_gj.index(tmp_gj)
          end
          if index.nil?
            index = files_lower_gp.index(tmp_gp)
          end
          if index.nil?
            puts tmp_lw
            index = files_lower_lw.index(tmp_lw)
          end

          unless index.nil?
            parsed['image'] = images[index]
          else
            puts tmp
            parsed['image'] = ''
          end

          #puts parsed
          csv << parsed.values
        else
          #puts line
        end
      end
    end
  end
end
#puts files_lower_lw

#tweede_herziening/serie_4/13keteldiepoost
#tweede_herziening/serie_4/13keteldiepwest1933
