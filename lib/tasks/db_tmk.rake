namespace :db do
  namespace :seed do
    desc "Add tmk series and copies"
    task :process_tmk_kadaster => :environment do
      require 'csv'
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
      file = 'db/tmk/bb2.csv'
      CSV.foreach(file, encoding: "bom|utf-8", headers: :first_row, col_sep: ',') do |row|
        nummer = row['Bladnummer']
        if nummer.nil?
          nummer='0'
        end
        titel = row['Titel'].split(', ')[0].split(' ')[1]

        pubyear = row['Uitgave'].to_s
        exact = true;
        if pubyear.nil?
          exact = false;
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

        regio = 'tmk-%{nummer}' # halfbladen niet vergeten --> 24, 36 (3 varianten?)
        regio = regio.downcase
        unless Region.exists?({name: regio})
          region = Region.create({name: regio})
        else
          region = Region.find_by({name: regio})
        end

        base_title = nummer # halfbladen nog doen!
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

        vnr = nummer.to_s.rjust(2, "0")
        display_title = '%{vnr} %{titel}'
        puts(pubyear)
        pubdate=Date.strptime(pubyear, '%Y')
        unless bsh.sheets.exists?({display_title: bsh.title, pubdate: pubdate})
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
                                     opmerkingen: row['Editievermelding'],
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


      end
    end
  end
end
