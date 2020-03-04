namespace :db do
  namespace :seed do
    desc "Add ubu waterstaatskaarten copies"
    task :process_wsk_ubu => :environment do
      require 'csv'
      library_name = "Universiteitsbibliotheek Utrecht"
      library_abbr = "ubu"
      unless Library.exists?(abbr: library_abbr)
        library = Library.create(name: library_name, abbr: library_abbr)
      else
        library = Library.find_by(name: library_name, abbr: library_abbr)
      end
      repo_name = 'UBU Bijzondere Collecties'
      unless Repository.exists?(name: repo_name)
        repository = Repository.create({
                                           base_url: 'http://bc.library.uu.nl/nl',
                                           name: repo_name,
                                           library_abbr: library_abbr
                                       })
      else
        repository = Repository.find_by(name: repo_name)
      end
      n = 0
      csv_file = 'Waterstaatskaarten_aanvullijst_RK-MvE (002).csv'
      CSV.foreach('db/wsk/uu/' + csv_file,
                  encoding: "bom|utf-8",
                  headers: :first_row,
                  col_sep: ',',
                  :header_converters => lambda {|f| f.strip},
                  :converters => lambda {|f| f ? f.strip : nil}
      ) do |row|
        puts(n)
        unless row['plaatskenmerk'] == '-' or row['plaatskenmerk'].nil?
          puts(row['url'])
          sheet = Sheet.find(row['db_id'])

          # sheet metadata additions
          sheet.schaal = row['schaal']
          sheet.uitgever = row['uitgever']

          ocn = row['ocn']
          unless BibliographicMetadatum.exists?(oclcnr: ocn)
            bm = BibliographicMetadatum.create({oclcnr: ocn})
          else
            bm = BibliographicMetadatum.find_by({oclcnr: ocn})
          end

          sm = row['plaatskenmerk']
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
          unless row['provenance'] == 'x'
            pr = row['provenance']
          end
          unless Provenance.exists?(name: pr, library_abbr: library_abbr)
            provenance = Provenance.create({name: pr, library_abbr: library_abbr})
          else
            provenance = Provenance.find_by({name: pr, library_abbr: library_abbr})
          end

          volgnummer = row['notities']
          unless Copy.exists?({csv_row: csv_file + '|' + n.to_s}) # make sure we don't enter the same row twice
            copy = Copy.create({
                                   csv_row: csv_file + '|' + n.to_s,
                                   sheet: sheet,
                                   description: '',
                                   provenance: provenance,
                                   phys_char: row['fysieke kenmerken'],
                                   stamps: row['stempels'],
                                   volgnummer: volgnummer,
                                   shelfmark: shelfmark})
          else
            copy = Copy.find_by({csv_row: csv_file + '|' + n.to_s})
          end
          if !copy.valid?
            puts copy.errors.full_messagese
            exit
          end

          url = row['url']
          if match = url.match(/.*#page\/(.*)\.jpg.*/i)
            id = match.captures[0]
            iiif_id = 'http://objects.library.uu.nl/fcgi-bin/iipsrv.fcgi?IIIF=/manifestation/viewer' + id + '.jp2'
          end
          unless ElectronicVersion.exists?({repository_url: url})
            ev = ElectronicVersion.create({
                                              repository_url: url,
                                              repository: repository,
                                              iiif_id: iiif_id,
                                              service_type: 'iiif',
                                              copy: copy
                                          })
          end


        end
        n = n + 1
      end
    end
  end
  namespace :droplib do
    desc "Delete uu copies from database"
    task :ubu => :environment do
      library = Library.find('ubu')
      provenances = library.provenances
      shelfmarks = library.shelfmarks
      repositories = library.repositories
      copies = library.copies
      # 1. delete electronic_versions
      copies.each do |copy|
        copy.electronic_versions.destroy_all
      end
      # 2. delete copies
      copies.destroy_all
      # 3. delete provenances
      provenances.destroy_all
      # 4. delete shelfmarks
      shelfmarks.destroy_all
      # 5. delete repositories
      repositories.destroy_all
      # [6. delete library] might leave in to avoid deleting users
      # library.destroy
    end
  end
end

