require 'csv'


parsed ={'editie' => nil, 'nr' => nil, 'titel' => nil, 'uitgever' => nil, 'uitgave' => nil, 'bewerkt' => nil, 'verkend' => nil, 'bijgewerkt' => nil, 'herzien' => nil, 'opname_jaar' => nil, 'basis_jaar' => nil, 'basis' => nil, 'schaal' => nil, 'bewerker' => nil, 'reproductie' => nil, 'opmerking' => '', 'json_nationaal_archief' => nil, 'hw' => nil, 'we' => nil, 'image' => nil}

raster_folder={'1' => 'eerste_editie', '1BIS' => 'edit_1bis', '2' => 'tweede_editie', '2BIS' => 'edit_2bis', '3' => 'derde_editie', '3BIS' => 'edit_3bis', '4' => 'vierde_editie', '4BIS' => 'edit_4bis', '5' => 'vijfde_editie'}

files=File.readlines('db/wsk/dir.txt')
files_lower=[]
images=[]
files.each do |file|
  #files_lower.push(file.downcase.gsub('bergen-op-zoom','bergen op zoom').gsub(' - ','-').strip())
  path=file.split('/')[0]
  fname=file.split('/')[1]
  fbase=fname.split('.')[0]
  fext=fname.strip().split('.')[1]
  if fext=='jpg'
    files_lower.push(path.downcase+'/' + fbase.downcase.tr('^a-z0-9', '')+'.jpg')
    images.push(file.strip())
  end
end
cop=files_lower

CSV.open("db/wsk/Beschrijving_Waterstaatskaarten_#{Date.today}.csv", "w", headers: parsed.keys, write_headers: true) do |csv|
#['1','1BIS','2','2BIS','3','3BIS','4','4BIS','5'].each do |ed|
  ['1', '1BIS', '2', '2BIS', '3', '3BIS', '4', '4BIS', '5'].each do |ed|
    n = 0
    File.readlines("db/wsk/Beschrijving_Waterstaatskaarten_#{ed}.txt").each do |line|
      line = line.strip()
      #61 – 62 MAASTRICHT
      /(?<nr>\[?\d{1,2}\]?(.+\d{1,2})?)\s(?<titel>(\'S(\s|-))?[A-Z]{2}.+)/ =~ line
      p = false

      if titel
        if n>0
          extra=''
          if parsed['json_nationaal_archief']=='Ja'
            extra='1'
          end
          if parsed['hw']=='H'
            extra='2'
          end
          if parsed['we']=='W'
            extra='3'
          end

          tmp=parsed['nr'].tr('[]','').split('-')
          if tmp.count>1
            fnr='%02d%02d' % [tmp[0],tmp[1]]
          else
            fnr='%02d' % tmp[0]
          end
          index=-1
          f= sprintf('%s/%s%s%s.jpg' % [raster_folder[ed], fnr, parsed['titel'].downcase.tr('^a-z0-9', ''),extra])
          f2= sprintf('%s/%s%s%s1.jpg' % [raster_folder[ed], fnr, parsed['titel'].downcase.tr('^a-z0-9', ''),extra])
          index=files_lower.index(f)
          if index.nil?
            index=files_lower.index(f2)
          end
          puts index
          unless index.nil?
            puts f
            puts index
            puts images[index]
            parsed['image']=images[index]
          end
          csv << parsed.values
        end
        n = 0
        parsed.clear
        parsed ={'editie' => nil, 'nr' => nil, 'titel' => nil, 'uitgever' => nil, 'uitgave' => nil, 'bewerkt' => nil, 'verkend' => nil, 'bijgewerkt' => nil, 'herzien' => nil, 'opname_jaar' => nil, 'basis_jaar' => nil, 'basis' => nil, 'schaal' => nil, 'bewerker' => nil, 'reproductie' => nil, 'opmerking' => '', 'json_nationaal_archief' => nil, 'hw' => nil, 'we' => nil, 'image' => nil}
        #parsed = {'editie' => nil, 'nr' => nil, 'titel' => nil, 'uitgever' => nil, 'uitgave' => nil, 'bewerkt' => nil, 'verkend' => nil, 'bijgewerkt' => nil, 'herzien' => nil, 'basis' => nil, 'schaal' => nil, 'bewerker' => nil, 'reproductie' => nil, 'opmerking' => '', 'json_nationaal_archief' => false, 'hw' => false, 'we' => false}
        parsed['editie']=ed
        parsed['nr'] = nr.strip().gsub(' ','').tr('/–','-')
        parsed['titel'] = titel.strip().gsub(' - ','-').gsub(' – ','-').gsub('–','-').gsub('_','-')
        parsed['opmerking']=''
        p = true
      else
        n = n + 1
      end
      #puts line
      if n > 0
        /^(?<schaal>Schaal\s.+)/ =~ line
        /^(Reprodu(c|k)tie(:?)\s|Druk:\s)(?<repro>.+)/ =~ line
        /^(Bewerking:\s|Bewerkt\sbij\s)(?<bewerker>.+)/ =~ line
        /^(Bewerking\s(en\s)?(reprodu(c|k)tie|lithografie):\s(?<bere>.+))/ =~ line
        /^Uitgave:\s(?<uitgave>.+)/ =~ line
        /^Basis:\s(?<basis>.+)/ =~ line

        if schaal
          p = true
          parsed['schaal'] = schaal
        elsif basis
          p = true
          parsed['basis'] = basis
          /(?<basis_jaar>\d{4})/ =~ basis
          parsed['basis_jaar']=basis_jaar
        elsif repro
          p = true
          parsed['reproductie'] = repro
        elsif bewerker
          p = true
          parsed['bewerker'] = bewerker
          /opname\s(?<opname_jaar>\d{4})/ =~ bewerker
          parsed['opname_jaar']=opname_jaar
        elsif bere
          p = true
          parsed['bewerker'] = bere
          parsed['reproductie'] = bere
        elsif uitgave
          p = true
          parsed['uitgever'] = uitgave
        elsif line.strip() == 'Waterstaatskaart' || line.strip() == 'Waterstaatskaart van Nederland'
          p = true
          parsed['json_nationaal_archief'] = 'Ja'
        elsif line.downcase.strip() == 'hydrologische  waarnemingspunten'
          p = true
          parsed['hw'] = 'H'
        elsif line.downcase.strip() == 'watervoorzieningseenheden' || line.downcase.strip() == 'watervoorziening' || line.downcase.strip() == 'watervoorzieningsgebieden'
          p = true
          parsed['we'] = 'W'
        elsif line.downcase.start_with?('hoofdkaart') || line.downcase.start_with?('bijkaart')
          # ignore
          p = true
        elsif line.strip() == '[1881]'
          parsed['bewerkt'] = '1881'
          parsed['opmerking'] = parsed['opmerking'] + '\r' + 'Geen jaartal'
          p = true
        else
          #/^(?<actie>[a-z]+)\s(in\s)?(?<jaar>\d{4})/ =~ line.downcase
          /^(?<actie>.+)\s(?<jaar>\d{4}(-\d{4})?)/ =~ line.downcase
          if actie
            if actie.include? "bewerkt"
              p = true
              parsed['bewerkt'] = jaar
            elsif actie.include? "verkend"
              p = true
              parsed['verkend'] = jaar
            elsif actie.include? "uitgave"
              p = true
              parsed['uitgave'] = jaar
            elsif actie.include? "bijgewerkt"
              p = true
              parsed['bijgewerkt'] = jaar
            elsif actie.include? "herzien"
              p = true
              parsed['herzien'] = jaar
            elsif actie.start_with?("top.") || actie.start_with?('meetkundige dienst') ||
                actie.start_with?('directie waterhuishouding en waterbeweging') ||
                actie.start_with?('min. v.')
              p = true
              parsed['uitgever'] = actie
              parsed['uitgave'] = jaar
            end
          elsif line.downcase.start_with?("top.") || line.downcase.start_with?('meetkundige dienst') ||
              line.downcase.start_with?('directie waterhuishouding en waterbeweging') ||
              line.downcase.start_with?('min. v.')
            p = true
            parsed['uitgever'] = line.strip()
          elsif line.include?(" bijvel") || line.downcase.include?("breder formaat")
            p = true
            parsed['opmerking'] = parsed['opmerking'] + '\r' + line.strip()
          end
        end
      end
      unless p
        unless line.strip() == ''
          # puts n, bewerker, line
          puts line
        end
      end
    end
  end
end


puts '***************'
puts cop
