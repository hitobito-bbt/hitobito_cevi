# == Schema Information
#
# Table name: censuses
#
#  id        :integer          not null, primary key
#  year      :integer          not null
#  start_at  :date
#  finish_at :date
#
class Census < ActiveRecord::Base

  after_initialize :set_defaults

  validates :start_at, presence: true
  validates :start_at, :finish_at, timeliness: { type: :date, allow_blank: true }

  class << self
    # The last census defined (may be the current one)
    def last
      order('start_at DESC').first
    end

    # The currently active census
    def current
      where('start_at <= ?', Date.today).order('start_at DESC').first
    end
  end

  def to_s
    year
  end

  private

  def set_defaults
    if new_record?
      self.start_at  ||= Date.today
      self.year      ||= start_at.year
      if Settings.census
        self.finish_at ||= Date.new(year,
                                    Settings.census.default_finish_month,
                                    Settings.census.default_finish_day)
      end
    end
  end
end
