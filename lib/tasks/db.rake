namespace :db do
  namespace :seed do
    desc "Create admin user"
    task :admin => :environment do
      u = User.new({
                       email: 'pjmvos@gmail.com',
                       password: '*',
                       password_confirmation: '*'
                   })

      l = Library.find('ubvu')
      puts l.name
      u.libraries << l
      u.role = 2
      u.save(:validate => false)
    end
  end

  namespace :seed do
    desc "Fill tables with waterstaatskaarten "
    task :process_wsk => :environment do
      require 'csv'

      series_name = 'Waterstaatskaarten'
      series_abbr = 'wsk'
      publisher_name = 'Rijkswaterstaat'
      library_name = 'Rijkswaterstaat'
      library_abbr = 'rws'

      oclcnr = {'LL.03513gk' => '71550821',
                'LL.03514gk' => '71550822',
                'LL.03515gk' => '71550823',
                'LL.03516gk' => '71551593',
                'LL.03517gk' => '71551594'
      }

      metadata_fields = ['nummer', 'uitgever', 'verkend', 'herzien', 'bewerkt', 'uitgave', 'bijgewerkt', 'opname_jaar', 'basis_jaar', 'basis', 'schaal', 'bewerker', 'reproductie', 'editie', 'waterstaatskaart', 'bijkaart_we', 'bijkaart_hw']
      set_metadata_fields = ['editie']

      unless BaseSeries.exists?(abbr: series_abbr)
        bs = BaseSeries.create({name: series_name, abbr: series_abbr, metadata_fields: metadata_fields, set_metadata_fields: set_metadata_fields})
      else
        bs = BaseSeries.find(series_abbr)
      end
      n = 0

      CSV.foreach('db/wsk/Beschrijving_Waterstaatskaarten.csv',
                  encoding: "bom|utf-8",
                  headers: :first_row,
                  col_sep: ',',
                  :header_converters => lambda {|f| f.strip},
                  :converters => lambda {|f| f ? f.strip : nil}
      ) do |row|
        regio = [row['nr'].tr('[]', '').gsub(/^(\d)$/, '0\1').gsub(/^(\d)-(\d)$/, '0\1-0\2'), row['titel'].downcase.tr('-', ' ')].join('-')

        regio = regio.tr('()', '')
        region = nil
        unless Region.exists?({name: regio})
          region = Region.create({name: regio})
        else
          region = Region.find_by({name: regio})
        end

        base_title = row['nr']
                         .tr('[]', '')
                         .gsub(/^(\d)$/, '0\1')
                         .gsub(/^(\d)-(\d)$/, '0\1-0\2') +
            ' - ' +
            row['titel']
                .upcase
                .tr('()', '')
                .tr('-', ' ')

        wkrt = row['wsk']
        bijwe = row['we']
        bijhw = row['hw']

        if wkrt == 'Ja'
          base_title = base_title #+ ' - ' + 'w.krt'
        end
        if bijwe == 'W'
          base_title = base_title + ' - ' + 'bijkrt.w.e.'
        end
        if bijhw == 'H'
          base_title = base_title + ' - ' + 'bijkrt.h.w.'
        end

        unless bs.base_sheets.exists?({title: base_title})
          bsh = bs.base_sheets.create({title: base_title, base_series_abbr: bs.abbr, region: region})
        else
          bsh = BaseSheet.find_by({title: base_title, base_series: bs})
        end

        set_display_title = 'Editie ' + row['editie']
        unless bs.base_sets.exists?({display_title: set_display_title})
          set = bs.base_sets.create({display_title: set_display_title, base_series_abbr: bs.abbr, editie: row['editie']})
        else
          set = BaseSet.find_by({display_title: set_display_title})
        end

        pubyear = row['uitgave']
        exact = true
        if pubyear == 'ND' || pubyear.nil? || pubyear == ''
          pubyear = [row['bewerkt'].to_s.last(4).to_i, row['verkend'].to_s.last(4).to_i, row['bijgewerkt'].to_s.last(4).to_s.to_i, row['herzien'].to_s.last(4).to_i, row['opname_jaar'].to_s.last(4).to_i, row['basis_jaar'].to_s.last(4).to_i].max.to_s
          exact = false
        end

        unless pubyear == '0' || pubyear.nil? || pubyear == ''
          pubyear = pubyear[-4..-1]
        else
          pubyear = "1867"
        end
        unless bsh.sheets.exists?({display_title: bsh.title, pubdate: Date.strptime(pubyear, '%Y'), edition: row['editie']})
          sheet = bsh.sheets.create({pubdate: Date.strptime(pubyear, '%Y'),
                                     edition: row['editie'],
                                     pubdate_exact: exact,
                                     titel: row['titel'],
                                     display_title: bsh.title,
                                     nummer: row['nr'],
                                     uitgever: row['uitgever'],
                                     verkend: row['verkend'],
                                     bijgewerkt: row['bijgewerkt'],
                                     herzien: row['herzien'],
                                     bewerkt: row['bewerkt'],
                                     uitgave: row['uitgave'],
                                     editie: row['editie'],
                                     opname_jaar: row['opname_jaar'],
                                     basis_jaar: row['basis_jaar'],
                                     basis: row['basis'],
                                     schaal: row['schaal'],
                                     bewerker: row['bewerker'],
                                     reproductie: row['reproductie'],
                                     waterstaatskaart: row['wsk'] == 'Ja',
                                     bijkaart_we: row['we'] == 'W',
                                     bijkaart_hw: row['hw'] == 'H',
                                     opmerkingen: row['opmerking'],
                                     base_set: set
                                    })
          if !sheet.valid?
            puts 'error creating sheet line 135'
            puts sheet.errors.full_messages
            exit
          end
        else
          puts n
          puts 'find'
          sheet = bsh.sheets.find_by({display_title: bsh.title, pubdate: Date.strptime(pubyear, '%Y'), edition: row['editie']})
        end

        unless sheet.id
          puts n
          puts row
          puts Date.strptime(pubyear, '%Y')
          puts row['editie']
          puts bsh.title
          print sheet
          print sheet.display_title
          exit
        end


        unless Library.exists?(name: library_name)
          lib = Library.create(name: library_name, abbr: library_abbr)
        else
          lib = Library.find_by(name: library_name, abbr: library_abbr)
        end

        shelfmark = 'NA'

        unless Shelfmark.exists?(shelfmark: shelfmark, library_abbr: lib.abbr)
          shelfmark = Shelfmark.create({shelfmark: shelfmark, library_abbr: lib.abbr})
        else
          shelfmark = Shelfmark.find_by({shelfmark: shelfmark, library_abbr: lib.abbr})
        end

        unless Provenance.exists?(name: 'NA', library_abbr: lib.abbr)
          provenance = Provenance.create({name: 'NA', library_abbr: lib.abbr})
        else
          provenance = Provenance.find_by({name: 'NA', library_abbr: lib.abbr})
        end
        rwsreponame = 'geodata rijkswaterstaat website'
        unless Repository.exists?(name: rwsreponame)
          repo = Repository.create({
                                       base_url: 'https://www.rijkswaterstaat.nl/apps/geoservices/geodata/dmc/',
                                       name: rwsreponame,
                                       library_abbr: lib.abbr
                                   })
        else
          repo = Repository.find_by(name: rwsreponame)
        end

        rwsreponame = 'geoservices rijkswaterstaat'
        unless Repository.exists?(name: rwsreponame)
          owsrepo = Repository.create({
                                          base_url: 'http://geoservices.rijkswaterstaat.nl',
                                          name: rwsreponame,
                                          library_abbr: lib.abbr
                                      })
        else
          owsrepo = Repository.find_by(name: rwsreponame)
        end

        wms = 'http://geoservices.rijkswaterstaat.nl/waterstaatskaarten?'
        unless OgcWebService.exists?(url: wms)
          ows = OgcWebService.create({url: wms, services: ['wms'], viewer_url: 'http://geoplaza.vu.nl/gpzviewer/gpzViewer.php?id=381'})
        else
          ows = OgcWebService.find_by({url: wms})
        end

        unless row['image'].nil?
          unless Copy.exists?({csv_row: 'Beschrijving_Waterstaatskaarten.csv' + '|' + n.to_s}) # make sure we don't enter the same row twice
            copy = Copy.create({description: 'alleen scan, locatie origineel onbekend (Nationaal Archief?)',
                                csv_row: 'Beschrijving_Waterstaatskaarten.csv' + '|' + n.to_s,
                                sheet: sheet,
                                provenance: provenance,
                                shelfmark: shelfmark})
          else
            copy = Copy.find_by({csv_row: 'Beschrijving_Waterstaatskaarten.csv' + '|' + n.to_s})
          end
          if !copy.valid?
            puts copy.errors.full_messagese
            exit
          end
          url = 'https://www.rijkswaterstaat.nl/apps/geoservices/geodata/dmc/waterstaatskaart/geogegevens/raster/' + row['image']
          unless ElectronicVersion.exists?({repository_url: url})
            ev = ElectronicVersion.create({
                                              repository_url: url,
                                              repository: repo,
                                              service_type: 'image_url',
                                              copy: copy
                                          })
          end
          if sheet.edition == '5' && row['we'] != 'W' && row['hw'] != 'H'
            unless ElectronicVersion.exists?({ogc_web_service: ows, copy: copy})
              ev2 = ElectronicVersion.create({
                                                 ogc_web_service: ows,
                                                 service_type: 'ows',
                                                 copy: copy,
                                                 repository: owsrepo
                                             })
            end
          end
        end

        n = n + 1
      end

      library_name = 'Bibliotheek Vrije Universiteit'
      library_abbr = 'ubvu'

      n = 0
      invfile = 'Inventarisatie Waterstaatskaart WerkbestandLRMP.csv'
      CSV.foreach('db/wsk/' + invfile,
                  encoding: "bom|utf-8",
                  headers: :first_row,
                  col_sep: ',',
                  :header_converters => lambda {|f| f.strip},
                  :converters => lambda {|f| f ? f.strip : nil}
      ) do |row|
        unless row['Bewaard'] == 'kan weg'
          regio = [row['Nr'].gsub(/^(\d)$/, '0\1').gsub(/^(\d)-(\d)$/, '0\1-0\2').gsub(' / ', '-'), row['Titel'].downcase.tr('-', ' ')].join('-')
          regio = regio.tr('()', '')
          region = nil
          if row['Nr'] == 'Titelblad' || row['Nr'] == 'Bijlage'
            regio = ''
          end
          unless Region.exists?({name: regio})
            region = Region.create({name: regio})
          else
            region = Region.find_by({name: regio})
          end

          base_title = row['Nr'].tr('[]', '').gsub(/^(\d)$/, '0\1').gsub(/^(\d)-(\d)$/, '0\1-0\2').gsub(' / ', '-') + ' - ' + row['Titel'].upcase.tr('()', '').tr('-', ' ')

          wkrt = row['W.krt']
          bijwe = row['Bijkrt, w.e.']
          bijhw = row['Bijkrt, h.w.']

          if wkrt == 'Ja'
            base_title = base_title #+ ' - ' + 'w.krt'
          end
          if bijwe == 'W'
            base_title = base_title + ' - ' + 'bijkrt.w.e.'
          end
          if bijhw == 'H'
            base_title = base_title + ' - ' + 'bijkrt.h.w.'
          end

          unless bs.base_sheets.exists?({title: base_title})
            bsh = bs.base_sheets.create({title: base_title, base_series_abbr: bs.abbr, region: region})
          else
            bsh = BaseSheet.find_by({title: base_title, base_series: bs})
          end

          #PV Dubieus, maar voor de titelbladen
          if row['Editie'].nil?
            set_editie = '1'
            set_display_title='Editie 1'
          else
            set_editie = row['Editie']
            set_display_title='Editie ' + row['Editie'].upcase
          end
          if row['Editie']=='6' or row['Editie']=='MD'
            set_display_title = 'Proefbladen'
            set_editie = 'NA'
          end
          unless bs.base_sets.exists?({display_title: set_display_title})
            set = bs.base_sets.create({display_title: set_display_title, base_series_abbr: bs.abbr, editie: set_editie})
          else
            set = BaseSet.find_by({display_title: set_display_title})
          end

          pubyear = row['Uitgave']
          exact = true

          if pubyear == '[na 1881]'
            pubyear = '1881'
            exact = false
          end
          if base_title == '30 - \'S GRAVENHAGE OOST - bijkrt.w.e.' && row['Editie'] == '4'
            pubyear = '1971' #according to RWS list
            exact = true
          end

          if pubyear == 'ND' || pubyear.nil?
            pubyear = [row['Bew.'].to_s.last(4).to_i, row['Herz.'].to_s.last(4).to_i, row['Verk.'].to_s.last(4).to_s.to_i].max.to_s
            exact = false
          end

          unless pubyear == '0' || pubyear.nil?
            pubyear = pubyear[-4..-1]
          else
            pubyear = "1867" # titelbladen
            exact = false
          end


          pubyear = pubyear[-4..-1]
          puts pubyear

          unless bsh.sheets.exists?({pubdate: Date.strptime(pubyear, '%Y'), edition: set_editie})
            sheet = bsh.sheets.create({pubdate: Date.strptime(pubyear, '%Y'),
                                       edition: set_editie,
                                       pubdate_exact: exact,
                                       titel: row['Titel'].upcase,
                                       display_title: bsh.title,
                                       nummer: row['Nr'],
                                       verkend: row['Verk.'],
                                       herzien: row['Herz.'],
                                       bewerkt: row['Bew.'],
                                       uitgave: row['Uitgave'],
                                       editie: row['Editie'],
                                       waterstaatskaart: row['W.krt'] == 'Ja',
                                       bijkaart_we: row['Bijkrt, w.e.'] == 'W',
                                       bijkaart_hw: row['Bijkrt, h.w.'] == 'H',
                                       opmerkingen: 'niet vermeld in Beschrijving Waterstaatskaarten.doc',
                                       base_set: set})
            if !sheet.valid?
              puts row
              puts pubyear
              puts sheet.errors.full_messages
              exit
            end
          else
            sheet = bsh.sheets.find_by({pubdate: Date.strptime(pubyear, '%Y'), edition: set_editie})
          end


          unless Library.exists?(name: library_name)
            lib = Library.create(name: library_name, abbr: library_abbr)
          else
            lib = Library.find_by(name: library_name, abbr: library_abbr)
          end

          shelfmark = row['Signatuur']
          if shelfmark.nil?
            shelfmark = 'NA'
          end

          oclc = nil
          unless oclcnr[shelfmark].nil?
            oclc = oclcnr[shelfmark]
            unless BibliographicMetadatum.exists?(oclcnr: oclcnr[shelfmark])
              bm = BibliographicMetadatum.create({oclcnr: oclcnr[shelfmark]})
            else
              bm = BibliographicMetadatum.find_by({oclcnr: oclcnr[shelfmark]})
            end
          end

          unless Shelfmark.exists?(shelfmark: shelfmark, library_abbr: lib.abbr)
            shelfmark = Shelfmark.create({shelfmark: shelfmark, library_abbr: lib.abbr, oclcnr: oclc})
          else
            shelfmark = Shelfmark.find_by({shelfmark: shelfmark, library_abbr: lib.abbr})
          end

          unless Provenance.exists?(name: row['Prov.'], library_abbr: lib.abbr)
            provenance = Provenance.create({name: row['Prov.'], library_abbr: lib.abbr})
          else
            provenance = Provenance.find_by({name: row['Prov.'], library_abbr: lib.abbr})
          end

          unless Copy.exists?({csv_row: invfile + '|' + n.to_s}) # make sure we don't enter the same row twice
            copy = Copy.create({phys_char: row['Fys. Kenm.'],
                                stamps: row['Stempels'],
                                description: row['Opm.'],
                                csv_row: invfile + '|' + n.to_s,
                                #on_index: row['op bladindex'] == 'Ja' ? true : false,
                                sheet: sheet,
                                provenance: provenance,
                                shelfmark: shelfmark})
            if !copy.valid?
              puts copy.errors.full_messagese
              exit
            end
          else
            copy = Copy.find_by({csv_row: invfile + '|' + n.to_s})
          end
          n = n + 1
        end #unless kan weg
      end #CSV
    end #task :process_wsk


  end #namespace seed
end #namespace db

