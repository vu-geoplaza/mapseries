module SheetsHelper
  def table_helper
    table = {}
    highlight = []
    header = []
    # if false for column it can be hidden
    is_filled = []

    header[1], header[2], header[3], header[4], header[99] = 'jaar van uitgave', 'set', 'bladtitel', 'urls', 'exemplaren'
    is_filled[1], is_filled[2], is_filled[3], is_filled[4], is_filled[99] = true, true, true, true, true

    if policy(Sheet).update?
      header[100] = ''
      is_filled[100] = true
    end

    @sheets.each do |ed|
      table[ed.id] = []
      column = []

      # row highlighting, should make this more generic
      if ed.copies.count == 0
        highlight[ed.id] = "highlight3"
      else
        unless ed.copies.exists?(:provenance_id => 1)
          highlight[ed.id] = "highlight"
        else
          unless ed.copies.exists?(:provenance_id => [2, 3])
            highlight[ed.id] = "highlight2"
          else
            highlight[ed.id] = ""
          end
        end
      end

      # standard fields
      unless ed.pubdate.nil?
        if ed.pubdate_exact
          column[1] = ed.pubdate.year
        else
          column[1] = '[' + ed.pubdate.year.to_s + ']'
        end
      end
      column[2] = ed.base_set.display_title
      column[3] = link_to ed.display_title, sheet_path(ed)
      #link_to ed.display_title, base_sheet_sheets_path(ed.base_sheet), :title => 'view all sheets with this title'
      urls = []

      ed.electronic_versions.each do |ev|
        if ev.service_type == 'image_url'
          urls.push(link_to 'image', ev.repository_url, :target => 'blank')
        end
        if ev.service_type == 'ows'
          urls.push(link_to 'viewer', ev.ogc_web_service.viewer_url, :target => 'blank')
        end
      end

      column[4] = urls.join('<br>').html_safe
      #column[99] = link_to ed.copies.count, sheet_copies_path(ed), :title => 'view all copies of this sheet',  data: { popup: "copy" }
      column[99] = ed.copies.count
      #column[99] = link_to ed.copies.count, sheet_copies_path(ed), :class => "btn", :remote => true, "data-toggle" => "modal", "data-target" => "my-modal"
      if policy(Sheet).update?
        column[100] = link_to 'Edit', edit_base_series_sheet_path(@base_series, ed), :class => 'btn btn-primary'
      end

      #custom fields and headers
      col = 5
      #metadata_fields=["nummer","uitgever","verkend","herzien","bewerkt","uitgave","bijgewerkt","opname_jaar","basis_jaar","basis","schaal","bewerker","reproductie","editie","waterstaatskaart","bijkaart_we","bijkaart_hw"]
      metadata_fields = ["nummer", "uitgever", "verkend", "herzien", "bewerkt", "uitgave", "bijgewerkt", "opname_jaar", "basis_jaar", "basis", "schaal", "bewerker", "reproductie", "auteurs", "metingen", "editie", "opmerkingen"]
      #@base_series.metadata_fields.each do |field|
      metadata_fields.each do |field|
        column[col] = ed[field]
        header[col] = field
        unless ed[field].nil? || !ed[field]
          is_filled[col] = true
        end
        col = col + 1
      end
      table[ed.id] = column
    end
    return header, table, is_filled, highlight
  end

  def sheet_metadata_helper
    unless @sheet.pubdate.nil?
      if @sheet.pubdate_exact
        year = @sheet.pubdate.year
      else
        year = '[' + @sheet.pubdate.year.to_s + ']'
      end
    end

    mdiv = {}
    mdiv['kaartserie'] = @sheet.base_sheet.base_series.name
    unless @sheet.base_set.titel.nil?
      mdiv['serietitel'] = @sheet.base_set.titel
    end
    unless @sheet.base_set.editie.nil?
      mdiv['serie editie'] = @sheet.base_set.editie
    end
    unless @sheet.base_set.serie.nil?
      mdiv['serie'] = @sheet.base_set.serie
    end

    #'Jaar van Uitgave' => year
    metadata_fields = ["titel", "nummer", "uitgever", "verkend", "herzien", "bewerkt", "uitgave", "bijgewerkt", "opname_jaar", "basis_jaar", "basis", "schaal", "bewerker", "reproductie", "auteurs", "metingen", "editie"]
    #@base_series.metadata_fields.each do |field|
    metadata_fields.each do |field|
      unless @sheet[field].nil?
        mdiv[field] = @sheet[field]
      end
    end
    return mdiv
  end

  def sheet_copy_helper
    cdiv = {}
    @sheet.copies.each do |c|
      tmp = {}
      tmp['plaatskenmerk'] = c.shelfmark.shelfmark
      unless c.shelfmark.oclcnr.nil?
        tmp['worldcat'] = '<a href="https://vu.on.worldcat.org/oclc/' + c.shelfmark.oclcnr + '" target="_blank" title="associated worldcat record">' + c.shelfmark.oclcnr + '</a>'
      end
      unless c.phys_char.nil?
        tmp['fysieke kenmerken'] = c.phys_char
      end
      unless c.stamps.nil?
        tmp['stempels'] = c.stamps
      end
      tmp['provenance'] = c.provenance.name
      unless c.description.nil?
        tmp['opmerkingen'] = c.description
      end
      tmp['bronbestand'] = c.csv_row

      c.electronic_versions.each do |e|
        te = {}
        te['type'] = e.service_type
        unless e.repository_url.nil?
          te['url'] = link_to e.repository.name, e.repository_url
          # http://orbison.ubvu.vu.nl/rws/rvr/geogegevens/eerste_druk/Serie_1/05%20Dodewaard_1831.jpg
          # https://www.rijkswaterstaat.nl/apps/geoservices/geodata/dmc/rivierkaart/geogegevens/eerste_druk/Serie_1/05%20Dodewaard_1831.jpg
          local_url = e.repository_url.gsub('https://www.rijkswaterstaat.nl/apps/geoservices/geodata/dmc/', '/rws/')
          #picture_tags.append(e.id => {type: 'image', url: local_url})
          #te['viewer'] = openseadragon_picture_tag([ ] )
        end
        unless e.ogc_web_service.nil?
          te['url'] = link_to e.ogc_web_service.url, e.ogc_web_service.url
          te['ogc services'] = e.ogc_web_service.services.join(', ')
          te['preview'] = link_to 'link', e.ogc_web_service.viewer_url
        end
        if tmp['ev'].nil?
          tmp['ev'] = []
        end
        tmp['ev'].push(te)
      end

      lib = c.shelfmark.library.name
      if cdiv[lib].nil?
        cdiv[lib] = []
      end
      cdiv[lib].push(tmp)
    end
    logger.debug cdiv
    return cdiv
  end

  def sheet_picture_tags_helper
    picture_tags = []
    @sheet.copies.each do |c|
      c.electronic_versions.each do |e|
        if e.service_type == 'image_url'
          # TODO: move this conversion to a config file
          local_url = e.repository_url.gsub('https://www.rijkswaterstaat.nl/apps/geoservices/geodata/dmc/', '/rws/')
          picture_tags.append([e.id => {type: 'image', url: local_url}])
        end
      end
    end
    return picture_tags
  end


end
