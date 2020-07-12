require 'pry'
class PlaidCategory < ActiveRecord::Base
  
  def self.grouped_by_top_level
    @@top_level ||= PlaidCategory.all.group_by{ |category| category.hierarchy[0] }
  end

  # Get all categories that match the given key
  # Note: that this assumes that keys are passed in hierarchical order
  def self.all_matching_categories(key:)
    categories = grouped_by_top_level[key.shift]

    return categories unless key

    categories.select{ |c| c.hierarchy.include?(key.last) }
  end

  def most_specific_category
    hierarchy.last
  end

end
