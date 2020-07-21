class Sheet < ApplicationRecord
  belongs_to :base_sheet
  belongs_to :base_set
  has_many :copies
  has_many :electronic_versions, through: :copies
  has_many :shelfmarks, through: :copies

  validates :titel, presence: true
  validates_associated :copies
  #validate :validate_base_sheet_name, :validate_uniqueness, :validate_pubdate
  validate :validate_uniqueness, :validate_pubdate

  validate :associated_copies, :on => :destroy

  before_validation :build_display_title

  # Sunspot fields
  searchable do
    text :titel, :uitgever, :bewerker, :reproductie, :opmerkingen
    date :pubdate

    integer :id, :stored => true # for browsing search results

    string :sort_title do
      display_title.downcase
    end

    string :display_title

    string :sort_number do
      display_title[0, 2]
    end

    # facet fields
    #boolean :bijkaart_we, :bijkaart_hw, :waterstaatskaart
    string :base_title do
      base_sheet.base_series_abbr + '^' + base_sheet.title
    end

    string :provenances, :multiple => true do
      copies.map {|c| c.sheet.base_sheet.base_series_abbr + '^' + c.provenance.library_abbr + '^' + c.provenance.name}
    end
    string :shelfmarks, :multiple => true do
      shelfmarks.map {|s| base_sheet.base_series_abbr + '^' + s.library_abbr + '^' + s.shelfmark}
    end
    string :base_sets do
      base_sheet.base_series_abbr + '^' + base_set.display_title
    end
    string :libraries, :multiple => true do
      shelfmarks.map {|s| s.library.name}
    end
    string :repositories, :multiple => true do
      electronic_versions.map {|ev| ev.repository.name}
    end
    string :base_series do
      base_set.base_series.name
    end
    string :regions do
      base_sheet.region.name
    end
  end

  def validate_pubdate
    d, e = build_pubdate
    errors.add(:pubdate, "This pubdate can't be right.") unless self.pubdate == d && self.pubdate_exact == e
  end

  def validate_uniqueness
    ed = Sheet.find_by(display_title: self.display_title, pubdate: self.pubdate, base_set: self.base_set)
    errors.add(:title, 'This sheet already exists.') if ed && self != ed
  end

  def validate_base_sheet_name
    base_sheet = BaseSheet.find_by(title: self.display_title)
    errors.add(:base_sheet, 'it looks like you should enter a new base_sheet first') unless base_sheet
  end

  def build_pubdate
    if self.base_sheet.base_series_abbr == 'wsk'
      pubyear = self.uitgave
      exact = true
      if pubyear == 'ND' || pubyear.nil? || pubyear == ''
        pubyear = [
            self.bewerkt.to_s.last(4).to_i,
            self.verkend.to_s.last(4).to_i,
            self.bijgewerkt.to_s.last(4).to_s.to_i,
            self.herzien.to_s.last(4).to_i,
            self.opname_jaar.to_s.last(4).to_i,
            self.basis_jaar.to_s.last(4).to_i
        ].max.to_s
        exact = false
      end
      unless pubyear == '0' || pubyear.nil? || pubyear == ''
        pubyear = pubyear[-4..-1]
      else
        pubyear = "1867"
        exact = false
      end
      return Date.strptime(pubyear, '%Y'), exact
    end
    if self.base_sheet.base_series_abbr == 'rvr'
      pubyear = self.uitgave
      return Date.strptime(pubyear, '%Y'), self.pubdate_exact
    end
    if self.base_sheet.base_series_abbr == 'tmk'
      pubyear = self.uitgave
      exact = true
      if pubyear.nil? or pubyear == ''
        exact = false
        pubyear = [
            self.gegraveerd.to_s.last(4).to_i,
            self.bewerkt.to_s.last(4).to_i,
            self.verkend.to_s.last(4).to_i,
            self.bijgewerkt.to_s.last(4).to_s.to_i,
            self.herzien.to_s.last(4).to_i,
            self.ged_herzien.to_s.last(4).to_i,
            self.omgewerkt.to_s.last(4).to_i,
            self.stempel.to_s.last(4).to_i
        ].max.to_s
      end
      if pubyear.nil? or pubyear == '' or pubyear == '0'
        pubyear = self.opmerkingen.to_s.last(4)
        exact = false
      end
      if pubyear.nil? or pubyear == '' or pubyear == '0'
        pubyear = self.titel.to_s.last(4)
        exact = false
      end
      return Date.strptime(pubyear, '%Y'), exact
    end
  end

  def build_display_title
    # Specific case of waterstaatskaarten
    if self.base_sheet.base_series_abbr == 'wsk'
      # Clean nummer and titel
      base_title = self.nummer
                       .tr('[]', '')
                       .gsub(/^(\d)$/, '0\1')
                       .gsub(/^(\d)-(\d)$/, '0\1-0\2') +
          ' - ' +
          self.titel
              .upcase
              .tr('()', '')
              .tr('-', ' ')

      base_title = base_title + ' - ' + 'bijkrt.w.e.' if self.bijkaart_we
      base_title = base_title + ' - ' + 'bijkrt.h.w.' if self.bijkaart_hw
      self.display_title = base_title
    end
  end

end
