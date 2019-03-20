namespace :db do
  namespace :seed do
    desc "Fill tables with rivierkaarten"
    task :process_rvr => :environment do
      require 'csv'

      series_name = 'Rivierkaarten'
      series_abbr = 'rvr'
      publisher_name = 'Rijkswaterstaat'
      rws_name = 'Rijkswaterstaat'
      rws_abbr = 'rws'

      metadata_fields = ['nummer',
                         'uitgever',
                         'uitgave',
                         'editie',
                         'reproductie',
                         'schaal',
                         'metingen',
                         'auteurs',
                         'opmerkingen'
      ]

      set_metadata_fields = ['serie', 'editie', 'titel']
      shelfmark = {}
      shelfmark['eerste druk, serie 1'] = 'LL.10991gk'
      shelfmark['eerste druk, serie 2'] = 'LL.10992gk'
      shelfmark['eerste druk, serie 3'] = 'LL.10993gk'
      shelfmark['eerste druk, serie 4'] = 'LL.10994gk'
      shelfmark['eerste druk, serie 5'] = 'LL.10995gk'
      shelfmark['eerste druk, serie 6'] = 'LL.10996gk'
      shelfmark['eerste herziening, serie 1'] = 'LL.10997gk'
      shelfmark['eerste herziening, serie 2'] = 'LL.10998gk'
      shelfmark['eerste herziening, serie 3'] = 'LL.10999gk'
      shelfmark['eerste herziening, serie 4 en 5'] = 'LL.11000gk'
      shelfmark['eerste herziening, serie 6'] = 'LL.11001gk'
      shelfmark['eerste herziening, serie 7'] = 'LL.11002gk'
      shelfmark['eerste herziening, serie 8'] = 'LL.11003gk'
      shelfmark['vassen-herziening, serie 1'] = 'LL.11004gk'
      shelfmark['vassen-herziening, serie 2'] = 'LL.11005gk'
      shelfmark['tweede herziening, serie 1'] = 'LL.11006gk'
      shelfmark['tweede herziening, serie 2'] = 'LL.11007gk'
      shelfmark['tweede herziening, serie 2a'] = 'LL.11008gk'
      shelfmark['tweede herziening, serie 3'] = 'LL.11009gk'
      shelfmark['tweede herziening, serie 4'] = 'LL.11010gk'


=begin
      titel: row['titel'],
          display_title: bsh.title,
          nummer: row['nr'],
          uitgever: row['uitgever'],
          uitgave: row['jaar van uitgave'],
          editie: row['editie'],
          reproductie: row['drukker'],
          schaal: row['schaal'],
          metingen: row['jaar metingen'], # add column
          auteurs: row['auteurs'], # add column

          opmerkingen: row['Opmerkingen PV'],
=end

=begin
        Id
        -serie_editie
        -serie
        -serietekst
        -nr
        -titel
        -auteurs
        -editie
        -jaar metingen
        -jaar van uitgave
        -uitgever
        -Drukker
        -schaal
        -Opmerkingen PV


        Stempel TIArchief
        StempelTIKaartenarchief
        StempelBiblPontonniers
        StempelKVGIVU
        StempelKaartenzaal
        Stempel
        opmerkingen
        Fyskenm
        provenance
        aanwezig in ub

=end


      unless BaseSeries.exists?(abbr: series_abbr)
        bs = BaseSeries.create({name: series_name, abbr: series_abbr, metadata_fields: metadata_fields, set_metadata_fields: set_metadata_fields})
      else
        bs = BaseSeries.find(series_abbr)
      end

      rws_images = []

      n = 0
      file = 'db/rvr/paul/rivierkaart_db_met_rws_filenames2.csv'
      CSV.foreach(file, encoding: "bom|utf-8", headers: :first_row, col_sep: ',') do |row|
        # volgens mij is elk blad uniek, behalve die met een "uitgave"
        # er zijn bboxen, later doen

        editie_col = row['editie'].nil? ? '' : row['editie']
        row['jaar van uitgave'] = row['jaar van uitgave'].nil? ? '' : row['jaar van uitgave']
        row['serie'] = row['serie'].nil? ? '' : row['serie']
        row['titel'] = row['titel'].nil? ? ' - ' : row['titel']
        row['nr'] = row['nr'].nil? ? '00' : row['nr']
        row.each do |key, val|
          unless val.nil?
            val = val.gsub('"', '')
            row[key] = val.strip
          end
        end

        regio = '%{se}-%{s}-%{nr}-%{ti}' % {:se => row['serie_editie'],
                                            :s => row['serie'],
                                            :nr => row['nr'],
                                            :ti => row['titel']}
        #regio = row['serie_editie'] + '-' + row['serie'] + '-' + row['nr'] + '-' + row['titel']
        regio = regio.downcase
        unless Region.exists?({name: regio})
          region = Region.create({name: regio})
        else
          region = Region.find_by({name: regio})
        end

        if row['nr'].match(/^\d\D/) || row['nr'].match(/^\d$/)
          nr = '0' + row['nr'].to_s
        else
          nr = row['nr'].to_s
        end


        puts 'jaar'
        puts row['jaar van uitgave']
        pubyear = row['jaar van uitgave'].to_s[0..3]
        exact = false; # waar kan ik dit aan zien?

        base_title = nr + ' - ' + row['titel']
        unless row['editie'].nil?
          base_title = base_title + ' (' + row['editie'] + ')'
        end
        base_title = base_title + '. ' + pubyear
        unless bs.base_sheets.exists?({title: base_title})
          bsh = bs.base_sheets.create({title: base_title, base_series_abbr: bs.abbr, region: region})
        else
          bsh = BaseSheet.find_by({title: base_title, base_series: bs})
        end
        set_display_title = '%{se}, serie %{s}' % {:se => row['serie_editie'], :s => row['serie']}
        #set_display_title = row['serie_editie'] + ', serie ' + row['serie']
        unless bs.base_sets.exists?({display_title: set_display_title})
          set = bs.base_sets.create({display_title: set_display_title,
                                     base_series_abbr: bs.abbr,
                                     editie: row['serie_editie'],
                                     serie: row['serie'],
                                     titel: row['serietekst']
                                    })
        else
          set = BaseSet.find_by({display_title: set_display_title})
        end

        unless bsh.sheets.exists?({display_title: bsh.title, pubdate: Date.strptime(pubyear, '%Y'), base_set: set})
          sheet = bsh.sheets.create({pubdate: Date.strptime(pubyear, '%Y'),
                                     edition: row['serie_editie'],
                                     pubdate_exact: exact,
                                     titel: row['titel'],
                                     display_title: bsh.title,
                                     nummer: row['nr'],
                                     uitgever: row['uitgever'],
                                     uitgave: row['jaar van uitgave'][0..3],
                                     editie: row['editie'],
                                     reproductie: row['Drukker'],
                                     schaal: row['schaal'],
                                     metingen: row['jaar metingen'], # add column
                                     auteurs: row['auteurs'], # add column

                                     opmerkingen: row['Opmerkingen PV'],
                                     base_set: set
                                    })
          if !sheet.valid?
            puts 'error creating sheet line 135'
            puts sheet.errors.full_messages
            puts pubyear
            puts Date.strptime(pubyear, '%Y')
            exit
          end
        else
          puts n
          puts 'find'
          sheet = bsh.sheets.find_by({display_title: bsh.title, pubdate: Date.strptime(pubyear, '%Y'), base_set: set})
        end
        library_name = 'Rijkswaterstaat'
        library_abbr = 'rws'
        unless Library.exists?(name: library_name)
          librws = Library.create(name: library_name, abbr: library_abbr)
        else
          librws = Library.find_by(name: library_name, abbr: library_abbr)
        end

        library_name = 'Bibliotheek Vrije Universiteit'
        library_abbr = 'ubvu'
        unless Library.exists?(name: library_name)
          libub = Library.create(name: library_name, abbr: library_abbr)
        else
          libub = Library.find_by(name: library_name, abbr: library_abbr)
        end

        sm = 'NA'
        unless Shelfmark.exists?(shelfmark: sm, library_abbr: librws.abbr)
          shelfmarkrws = Shelfmark.create({shelfmark: sm, library_abbr: librws.abbr})
        else
          shelfmarkrws = Shelfmark.find_by({shelfmark: sm, library_abbr: librws.abbr})
        end
        pk = shelfmark[set_display_title.downcase]
        if pk.nil?
          pk = 'NA'
        end
        unless Shelfmark.exists?(shelfmark: pk, library_abbr: libub.abbr)
          shelfmarkub = Shelfmark.create({shelfmark: pk, library_abbr: libub.abbr})
        else
          shelfmarkub = Shelfmark.find_by({shelfmark: pk, library_abbr: libub.abbr})
        end

        unless Provenance.exists?(name: 'NA', library_abbr: librws.abbr)
          provenancerws = Provenance.create({name: 'NA', library_abbr: librws.abbr})
        else
          provenancerws = Provenance.find_by({name: 'NA', library_abbr: librws.abbr})
        end
        rwsreponame = 'geodata rijkswaterstaat website'
        unless Repository.exists?(name: rwsreponame)
          repo = Repository.create({
                                       base_url: 'https://www.rijkswaterstaat.nl/apps/geoservices/geodata/dmc/',
                                       name: rwsreponame,
                                       library_abbr: librws.abbr
                                   })
        else
          repo = Repository.find_by(name: rwsreponame)
        end
        # copy rws
        unless row['image'].nil? || row['image'] == '-' || row['image'].in?(rws_images)
          # Alleen verdubbelen bij afwijkend bestand!
          unless Copy.exists?({csv_row: file + '|' + n.to_s + '|rws'}) # make sure we don't enter the same row twice
            copyrws = Copy.create({description: 'alleen scan, locatie origineel onbekend (Nationaal Archief?)',
                                   csv_row: file + '|' + n.to_s + '|rws',
                                   sheet: sheet,
                                   provenance: provenancerws,
                                   shelfmark: shelfmarkrws})
          else
            copyrws = Copy.find_by({csv_row: file + '|' + n.to_s + '|rws'})
          end
          if !copyrws.valid?
            puts copyrws.errors.full_messagese
            exit
          end
          url = 'https://www.rijkswaterstaat.nl/apps/geoservices/geodata/dmc/rivierkaart/geogegevens/' + row['image']
          unless ElectronicVersion.exists?({repository_url: url})
            ev = ElectronicVersion.create({
                                              repository_url: url,
                                              repository: repo,
                                              service_type: 'image_url',
                                              copy: copyrws
                                          })
          end
          rws_images.append(row['image'])
        end


        # copy ubvu
        if row['provenance'].nil?
          prov = 'NA'
        else
          prov = row['provenance']
        end
        unless Provenance.exists?(name: prov, library_abbr: libub.abbr)
          provenanceub = Provenance.create({name: prov, library_abbr: libub.abbr})
        else
          provenanceub = Provenance.find_by({name: prov, library_abbr: libub.abbr})
        end
        if row['aanwezig in ub'] == 'Ja'
          unless Copy.exists?({csv_row: file + '|' + n.to_s + '|ub'}) # make sure we don't enter the same row twice
            stempels = []
            unless row['Stempel TIArchief'].nil?
              stempels.append(row['Stempel TIArchief'])
            end
            unless row['StempelTIKaartenarchief'].nil?
              stempels.append(row['StempelTIKaartenarchief'])
            end
            unless row['StempelBiblPontonniers'].nil?
              stempels.append(row['StempelBiblPontonniers'])
            end
            unless row['StempelKVGIVU'].nil?
              stempels.append(row['StempelKVGIVU'])
            end
            unless row['StempelKaartenzaal'].nil?
              stempels.append(row['StempelKaartenzaal'])
            end
            unless row['Stempel'].nil?
              stempels.append(row['Stempel'])
            end
            puts stempels
            puts stempels.join('; ')
            copyrws = Copy.create({description: row['opmerkingen'],
                                   phys_char: row['Fyskenm'],
                                   stamps: stempels.join('; '),
                                   csv_row: file + '|' + n.to_s + '|ub',
                                   sheet: sheet,
                                   provenance: provenanceub,
                                   shelfmark: shelfmarkub})
          else
            copyrws = Copy.find_by({csv_row: file + '|' + n.to_s + '|ub'})
          end
          if !copyrws.valid?
            puts copyrws.errors.full_messagese
            exit
          end
        end
        n = n + 1

      end
      puts 'toegevoegd: ' + n.to_s
    end
  end
end

