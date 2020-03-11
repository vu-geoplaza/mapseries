namespace :db do
  namespace :seed do
    desc "Add tmk series and copies"
    task :process_tmk_kadaster => :environment do
      require 'csv'
      library_name = "Kadaster"
      library_abbr = "kad"
      unless Library.exists?(abbr: library_abbr)
        library = Library.create(name: library_name, abbr: library_abbr)
      else
        library = Library.find_by(name: library_name, abbr: library_abbr)
      end
      unless Library.exists?(abbr: 'dans')
        libdans = Library.create(name: 'DANS', abbr: 'dans')
      else
        libdans = Library.find_by(name: 'DANS', abbr: 'dans')
      end
      repo_name = 'UBVU Beeldbank'
      unless Repository.exists?(name: repo_name)
        repository = Repository.create({
                                           base_url: 'http://imagebase.ubvu.vu.nl',
                                           name: repo_name,
                                           library_abbr: 'ubvu'
                                       })
      else
        repository = Repository.find_by(name: repo_name)
      end

      dans_repo_name = 'DANS Easy'
      unless Repository.exists?(name: dans_repo_name)
        dans_repository = Repository.create({
                                                base_url: 'https://easy.dans.knaw.nl/',
                                                name: dans_repo_name,
                                                library_abbr: 'dans'
                                            })
      else
        dans_repository = Repository.find_by(name: dans_repo_name)
      end

      series_name = 'Topographisch Militaire Kaart'
      series_abbr = 'tmk'

      metadata_fields = %w(nummer uitgever gegraveerd verkend herzien ged.herzien bijgewerkt omgewerkt uitgave opmerkingen)
      #Editievermelding,Stempel,verkend,gegraveerd,herzien,ged.herzien,omgewerkt,bijgewerkt,uitgave,Bladnummer,Rechten,UBVU-ID
      set_metadata_fields = ['editie']

      unless BaseSeries.exists?(abbr: series_abbr)
        bs = BaseSeries.create({name: series_name, abbr: series_abbr, metadata_fields: metadata_fields, set_metadata_fields: set_metadata_fields})
      else
        bs = BaseSeries.find(series_abbr)
      end
      n = 0
      file = 'db/tmk/ubvu_bb_kadaster.csv'
      CSV.foreach(file, encoding: "bom|utf-8", headers: :first_row, col_sep: ',') do |row|
        puts("start row: #{row['Titel']}")
        nummer = row['Bladnummer']
        if nummer.nil?
          nummer = '0'
        end
        vnr = nummer.to_s.rjust(2, "0")
        if row['Titel'].split(', ').length > 1
          tmp = row['Titel'].split(', ')[0].split(' ')
          titel = tmp[1, 10].join(' ')
        else
          titel = row['Titel']
        end


        pubyear = row['uitgave'].to_s
        exact = true
        if pubyear.nil? or pubyear == ''
          exact = false
          pubyear = [
              row['gegraveerd'].to_s.last(4).to_i,
              row['bewerkt'].to_s.last(4).to_i,
              row['verkend'].to_s.last(4).to_i,
              row['bijgewerkt'].to_s.last(4).to_s.to_i,
              row['herzien'].to_s.last(4).to_i,
              row['ged.herzien'].to_s.last(4).to_i,
              row['omgewerkt'].to_s.last(4).to_i,
              row['Stempel'].to_s.last(4).to_i
          ].max.to_s
        end
        if (pubyear.nil? or pubyear == '' or pubyear == '0') and vnr == '00'
          puts('Get date from titel!')
          pubyear = row['Titel'].last(4)
          exact = false
        end
        if pubyear.nil? or pubyear == '' or pubyear == '0'
          puts("Get date from opmerkingen #{row['opmerkingen']}!")
          pubyear = row['opmerkingen'].last(4)
          exact = false
        end

        regio = "#{vnr}" # halfbladen niet vergeten --> 24, 36 (3 varianten?)
        puts("regio: #{regio}")
        regio = regio.downcase
        unless Region.exists?({name: regio})
          region = Region.create({name: regio})
        else
          region = Region.find_by({name: regio})
        end

        base_title = vnr # halfbladen nog doen!
        unless bs.base_sheets.exists?({title: base_title})
          bsh = bs.base_sheets.create({title: base_title, base_series_abbr: bs.abbr, region: region})
        else
          bsh = BaseSheet.find_by({title: base_title, base_series: bs})
        end

        set_display_title = 'NA'
        unless bs.base_sets.exists?({display_title: set_display_title})
          set = bs.base_sets.create({display_title: set_display_title, base_series_abbr: bs.abbr, editie: set_display_title})
        else
          set = BaseSet.find_by({display_title: set_display_title, base_series_abbr: bs.abbr})
        end


        display_title = "#{vnr} #{titel}"
        pubdate = Date.strptime(pubyear, '%Y')
        puts(pubdate)
        puts(display_title)
        unless bsh.sheets.exists?({display_title: display_title, pubdate: pubdate})
          sheet = bsh.sheets.create({pubdate: pubdate,
                                     edition: 'NA',
                                     pubdate_exact: exact,
                                     titel: titel,
                                     display_title: display_title,
                                     nummer: row['nr'],
                                     uitgever: row['uitgever'],
                                     verkend: row['verkend'],
                                     gegraveerd: row['gegraveerd'],
                                     bijgewerkt: row['bijgewerkt'],
                                     omgewerkt: row['omgewerkt'],
                                     herzien: row['herzien'],
                                     ged_herzien: row['ged.herzien'],
                                     stempel: row['Stempel'],
                                     uitgave: row['uitgave'],
                                     opmerkingen: row['opmerkingen'],
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
          sheet = bsh.sheets.find_by({display_title: display_title, pubdate: pubdate})
        end

        # Add copy, shelfmark & provenance unknown
        ocn = '898205445'
        unless BibliographicMetadatum.exists?(oclcnr: ocn)
          bm = BibliographicMetadatum.create({oclcnr: ocn})
        else
          bm = BibliographicMetadatum.find_by({oclcnr: ocn})
        end

        sm = 'NA'
        unless Shelfmark.exists?(shelfmark: sm, library_abbr: library_abbr)
          shelfmark = Shelfmark.create({
                                           shelfmark: sm,
                                           library_abbr: library_abbr,
                                           oclcnr: ocn
                                       })
        else
          shelfmark = Shelfmark.find_by({shelfmark: sm, library_abbr: library_abbr})
        end
        pr = 'NA'
        unless Provenance.exists?(name: pr, library_abbr: library_abbr)
          provenance = Provenance.create({name: pr, library_abbr: library_abbr})
        else
          provenance = Provenance.find_by({name: pr, library_abbr: library_abbr})
        end

        unless Copy.exists?({csv_row: file + '|' + n.to_s}) # make sure we don't enter the same row twice
          copy = Copy.create({
                                 csv_row: file + '|' + n.to_s,
                                 sheet: sheet,
                                 description: 'Alleen scan, lokatie origineel onbekend',
                                 provenance: provenance,
                                 phys_char: '',
                                 stamps: '',
                                 shelfmark: shelfmark})
        else
          copy = Copy.find_by({csv_row: file + '|' + n.to_s})
        end
        if !copy.valid?
          puts copy.errors.full_messagese
          exit
        end

        # Add iiif imagebase electronic version
        url = row['Reference URL']
        #http://cdm21033.contentdm.oclc.org/digital/iiif/krt/3152
        iiif_id = "https://cdm21033.contentdm.oclc.org/digital/iiif/krt/#{row['CONTENTdm number']}"
        local_id = "ubvuid:#{row['UBVU-ID']}"
        # native openseadragon?

        # http://imagebase.ubvu.vu.nl/deepzoom/31_1924
        dzi = "https://cdm21033.contentdm.oclc.org/deepzoom/#{row['zoomnr']}"
        #TODO: add deepzoom to table and check openseadragon config
        unless ElectronicVersion.exists?({repository_url: url})
          ev = ElectronicVersion.create({
                                            repository_url: url,
                                            repository: repository,
                                            local_id: local_id,
                                            dzi: dzi,
                                            service_type: 'deepzoom',
                                            copy: copy
                                        })
        end
        url = 'https://doi.org/10.17026/dans-zrx-wz6e'
        unless ElectronicVersion.exists?({repository_url: url, copy: copy})
          ev = ElectronicVersion.create({
                                            repository_url: url,
                                            repository: dans_repository,
                                            service_type: 'dataset',
                                            copy: copy
                                        })
        end
        n = n + 1
      end
    end
  end
  namespace :del do
    desc "Delete tmk series and copies"
    task :delete_tmk => :environment do
      base_sets = BaseSet.where({base_series_abbr: 'tmk'})
      base_sheets = BaseSheet.where({base_series_abbr: 'tmk'})
      # drop sheets
      base_sheets.each do |bs|
        bs.sheets.each do |sh|
          sh.copies.each do |cp|
            cp.electronic_versions.destroy_all
          end
          sh.copies.destroy_all
        end
        bs.sheets.destroy_all
      end
      # drop base_sets
      base_sets.destroy_all
      # drop base_sheets
      base_sheets.destroy_all
    end
  end
  namespace :seed do
    task :process_dans_geojson => :environment do
      require 'rgeo'
      require 'rgeo/geo_json'
      require 'rgeo/proj4'
      # convert geojson to geometry
      # run seed first!
      wgs84_proj4 = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'
      wgs84_wkt = <<WKT
        GEOGCS["WGS 84",
          DATUM["WGS_1984",
            SPHEROID["WGS 84",6378137,298.257223563,
              AUTHORITY["EPSG","7030"]],
            AUTHORITY["EPSG","6326"]],
          PRIMEM["Greenwich",0,
            AUTHORITY["EPSG","8901"]],
          UNIT["degree",0.01745329251994328,
            AUTHORITY["EPSG","9122"]],
          AUTHORITY["EPSG","4326"]]
WKT

      wgs84_factory = RGeo::Geographic.spherical_factory(:srid => 4326,
                                                         :proj4 => wgs84_proj4, :coord_sys => wgs84_wkt)
      json_str = File.read('db/tmk/tmk_dans_4326.geojson')
      featurecollection = RGeo::GeoJSON.decode(json_str, geo_factory: wgs84_factory, json_parser: :json)
      featurecollection.each do |feature|
        puts(feature.properties['location'])
        loc = "#{feature.properties['location']}"
        if Region.exists?({name: loc})
          region = Region.find_by({name: loc})
          #feature_rd = RGeo::Feature.cast feature.geometry, factory: rd_new_factory, project: true
          #puts feature_rd.geometry.as_text
          region.update({geom4326: feature.geometry})
        end
      end
    end
  end
end
