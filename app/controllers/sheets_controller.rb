class SheetsController < ApplicationController
  require 'csv'

  after_action :verify_authorized, except: [:query, :index, :search, :show]

  helper_method :can_edit, :select_vals, :lib_select_vals, :select_vals_nocount

  include Pundit

  def show
    @sheet = Sheet.find(params[:id])
    ids = []
    # would be better to do this once and store it in the session cache
    unless session[:search_params].nil?
      sp = session[:search_params]
      sp['per_page'] = 10000 # "all"
      search = do_search(sp)
      search.hits.each do |h|
        ids.push(h.stored(:id))
      end
    end
    @previous_id = false
    @next_id = false
    unless ids.count == 0
      index = ids.find_index(params[:id].to_i)
      unless index.nil?
        @previous_id = index > 0 ? ids[index - 1] : false
        @next_id = ids[index + 1]
      end
    end
  end

  def index
    @filter = false

    # alles
    if params[:base_series_id]
      #@filter=true
      @base_series = BaseSeries.find(params[:base_series_id])
      @sheets = @base_series.sheets.order(:edition, :display_title)
    end

    if params[:base_set_id]
      @base_set = BaseSet.find(params[:base_set_id])
      @base_series = @base_set.base_series
      @sheets = @base_set.sheets.order(:edition, :display_title)
    end

    if params[:base_sheet_id]
      @base_sheet = BaseSheet.find(params[:base_sheet_id])
      @base_series = @base_sheet.base_series
      @sheets = @base_sheet.sheets.order(:edition, :display_title)
    end
    respond_to do |format|
      format.html
      format.csv {send_data to_csv, filename: "sheets-#{Date.today}.csv"}
    end
  end

  # GET /sheets/new
  def new
    logger.debug '>>>>>>> controller new'
    @base_series = BaseSeries.find(params[:base_series_id])
    @sheet = Sheet.new
    authorize @sheet
  end

  # GET /sheets/1/edit
  def edit

    @sheet = Sheet.find(params[:id])
    logger.debug '>>>>>>> controller edit'
    logger.debug @sheet.base_sheet.base_series_abbr
    @base_series = BaseSeries.find(@sheet.base_sheet.base_series_abbr)
    authorize @sheet
  end

  def update
    # Validate base sheet!
    # The base_sheet title should match (this is probably dependend on the base_series)

    # Merge if the sheet is exactly the same (title, nummer, pubdate)! Take care to move existing copies
    # or don't merge and force the user to delete the sheet (after moving the copies)

    # Recalculate display title | in Model before_validation
    @sheet = Sheet.find(params[:id])
    authorize @sheet
    @base_series = BaseSeries.find(@sheet.base_sheet.base_series_abbr)
    respond_to do |format|
      logger.debug sheet_params
      if @sheet.update(sheet_params)
        format.html {redirect_to base_series_sheets_url(base_series_id: @base_series.abbr), notice: 'Sheet was successfully updated.'}
      else
        format.html {render :edit}
      end
    end
  end

  def query
    params[:fs] ||= {}
    params[:fs][:q] ||= ''
    params[:fs][:library] ||= []
    params[:fs][:library_ex] ||= []
    params[:fs][:repository] ||= []
    params[:fs][:shelfmark] ||= []
    params[:fs][:provenance] ||= []
    params[:fs][:base_series] ||= 'Waterstaatskaarten'
    params[:fs][:base_title] ||= ''
    params[:fs][:base_set] ||= []
    params[:fs][:lonlat] ||= ''
    @search = do_search(params)
    respond_to do |format|
      format.json {render :json => ['base_series' => facet_vals(:base_series),
                                    'base_titles' => facet_vals(:base_title),
                                    'libraries' => facet_vals(:libraries),
                                    'provenances' => facet_vals(:provenances),
                                    'repositories' => facet_vals(:repositories),
                                    'base_sets' => facet_vals(:base_sets),
                                    'shelfmarks' => facet_vals(:shelfmarks),
                                    'year' => facet_vals(:pubdate),
                                    'total' => @search.total
      ]
      }

    end
  end

  def search
    params[:fs] ||= {}
    params[:fs][:q] ||= ''
    params[:fs][:library] ||= []
    params[:fs][:library_ex] ||= []
    params[:fs][:repository] ||= []
    params[:fs][:shelfmark] ||= []
    params[:fs][:provenance] ||= []
    params[:fs][:base_series] ||= 'Waterstaatskaarten'
    params[:fs][:base_title] ||= ''
    params[:fs][:base_set] ||= []
    params[:sort] ||= 'set,display_title asc'
    params[:fs][:lonlat] ||= ''

    @base_series = BaseSeries.find_by({name: params[:fs][:base_series]})

    @first = @base_series.sheets.order(:pubdate).first.pubdate.year
    @last = @base_series.sheets.order(:pubdate).last.pubdate.year

    params[:fs][:from] ||= 1000
    params[:fs][:to] ||= 3000

    params[:fs][:from] = params[:fs][:from] == '' ? 1000 : params[:fs][:from]
    params[:fs][:to] = params[:fs][:to] == '' ? 3000 : params[:fs][:to]

    # store params in session
    session[:search_params] = params

    respond_to do |format|
      format.html do
        @search = do_search(params)
        @sheets = @search.results
        render :search
      end
      format.csv do
        params[:per_page] = 5000
        @search = do_search(params)
        @sheets = @search.results
        send_data to_csv, filename: "sheets-#{Date.today}.csv"
      end
      format.docx do
        params[:per_page] = 5000
        params[:sort] = 'set,display_title asc'
        @search = do_search(params)
        @sheets = @search.results
        headers["Content-Disposition"] = "attachment; filename=\"sheets-#{Date.today}.docx\""
        render :search
      end
      format.json do
        params[:per_page] = 5000
        @search = do_search(params)
        @sheets = @search.results
        render json: @sheets.to_json(include: [
            {
                copies:
                    {
                        include: [:electronic_versions, :provenance, :shelfmark]
                    }
            },
            :base_set,
            {
                base_sheet: {
                    include: :region
                }
            }
        ])
      end
    end
  end

  def can_edit
    policy(Sheet).update?
  end

  def facet_vals(f)
    @search.facet(f).rows.map {|row| [row.value, row.count]}.sort
  end

  def lib_select_vals(f)
    r = {}
    @search.facet(f).rows.each do |row|

      # PV: do not return values for facets belonging to a different series
      # Allows us to show 0-count facets whilst hiding irrelevant facets
      arr = row.value.split('^')
      if arr[0] == @base_series.abbr
        # no base_series in displayed value
        if r[arr[1]].nil?
          r[arr[1]] = []
        end
        r[arr[1]].push([arr[2] + ' (' + row.count.to_s + ')', row.value])
        r[arr[1]].sort_by! {|v| v[0]}
      end
    end
    r.sort
  end

  def select_vals_nocount(f)
    vals = []
    @search.facet(f).rows.map do |row|
      vals.append([row.value, row.value])
    end
    vals.sort
  end

  def select_vals(f)
    vals = []
    @search.facet(f).rows.map do |row|
      #logger.debug(row.value)
      #logger.debug(@base_series.abbr)
      if row.value.split('^').count > 1 # effe uit
        #  PV: do not return values for facets belonging to a different series
        # Allows us to show 0-count facets whilst hiding irrelevant facets
        if row.value.split('^')[0] == @base_series.abbr
          # no base_series in displayed value
          vals.append([row.value.split('^')[1] + ' (' + row.count.to_s + ')', row.value])
        end
      else
        vals.append([row.value + ' (' + row.count.to_s + ')', row.value])
      end
    end
    vals.sort
  end

  private

  def sheet_params
    params.require(:sheet).permit!
  end

  def to_csv
    headers = ["db_id", "jaar van uitgave", "editie", "display_title"]
    fields = @base_series.metadata_fields
    fields.each do |field|
      headers.append(field)
    end
    headers.append('exemplaren')
    headers.append('urls')

    CSV.generate(headers: true, :col_sep => ",") do |csv|
      csv << headers
      @sheets.each do |ed|
        year = ''
        unless ed.pubdate.nil?
          year = ed.pubdate.year.to_s
          unless ed.pubdate_exact
            year = '[' + year + ']'
          end
        end

        row = [ed.id, year, ed.edition, ed.display_title]
        fields.each do |f|
          row.append(ed[f])
        end

        row.append(ed.copies.count)
        if ed.electronic_versions.count > 0
          row.append(ed.electronic_versions.first.repository_url)
        else
          row.append('')
        end
        csv << row
        row.clear
      end
    end
  end

  def get_regions_by_lonlat(lonlat_str)
    # st_contains query
    #POINT(-117.18757899999991 33.709771000000046)
    lon = lonlat_str.split(',')[0]
    lat = lonlat_str.split(',')[1]
    point = "POINT(#{lon} #{lat})"
    #SELECT name FROM public.regions WHERE ST_Contains(geom4326,ST_GeometryFromText('POINT(6.088806157931686 52.323086035437996)', 4326))
    res = ActiveRecord::Base.connection.execute("SELECT name FROM public.regions WHERE st_contains(geom4326, ST_GeometryFromText('" + point + "', 4326))")
    regions = ['dummy'] # return nothing
    res.each do |h|
      logger.debug h['name']
      regions.append(h['name'])
    end
    return regions
  end

  def do_search(params)
    # might be better to move this to a search Model, also decouples search from the sheets
    unless params['fs']['lonlat'] == ''
      regions = get_regions_by_lonlat(params['fs']['lonlat'])
      logger.debug regions
    end
    @search = Sheet.search do
      fulltext params['fs']['q']
      unless params['fs'].nil?
        unless params['fs']['lonlat'] == ''
          with(:regions, regions)
        end
        unless params['fs']['base_series'].empty?
          with(:base_series, params['fs']['base_series'])
          logger.debug 'ho'
        end
        unless params['fs']['library'].empty?
          with(:libraries, params['fs']['library'])
        end
        unless params['fs']['library_ex'].empty?
          without(:libraries, params['fs']['library_ex'])
        end
        unless params['fs']['shelfmark'].empty?
          with(:shelfmarks, params['fs']['shelfmark'])
        end
        unless params['fs']['provenance'].empty?
          with(:provenances, params['fs']['provenance'])
        end
        unless params['fs']['base_set'].empty?
          with(:base_sets, params['fs']['base_set'])
        end
        unless params['fs']['repository'].empty?
          with(:repositories, params['fs']['repository'])
        end
        unless params['fs']['base_title'].empty? || params['fs']['base_title'] == ''
          with(:base_title, params['fs']['base_title'])
        end
      end
      if !params['fs']['from'].nil? && !params['fs']['to'].nil?
        with(:pubdate).between(Date.new(params['fs']['from'].to_i, 1, 1)..Date.new(params['fs']['to'].to_i, 12, 31))
      end

      if params['sort'] == 'display_title desc'
        order_by :sort_title, :desc
      end
      if params['sort'] == 'display_title asc'
        order_by :sort_title, :asc
      end
      if params['sort'] == 'pubdate,display_title desc'
        order_by :pubdate, :desc
        order_by :sort_title, :asc
      end
      if params['sort'] == 'pubdate,display_title asc'
        order_by :pubdate, :asc
        order_by :sort_title, :asc
      end
      if params['sort'] == 'set,display_title desc'
        order_by :base_sets, :desc
        order_by :sort_title, :desc
      end
      if params['sort'] == 'set,display_title asc'
        order_by :base_sets, :asc
        order_by :sort_title, :asc
      end
      if params['sort'] == 'sort_number,set asc'
        order_by :sort_number, :asc
        order_by :base_sets, :asc
        order_by :sort_title, :asc
      end

      facet :base_series, :minimum_count => 0
      facet :base_title, :limit => 1000, :minimum_count => 0
      facet :libraries, :minimum_count => 0
      facet :provenances, :minimum_count => 0
      facet :repositories, :minimum_count => 0
      facet :base_sets, :minimum_count => 0
      facet :shelfmarks, :minimum_count => 0
      facet :regions, :limit => 5000 # I need all of them to build the map
      facet :pubdate

      paginate :page => params['page'] || 1, :per_page => params['per_page'] || 50
    end
  end
end
