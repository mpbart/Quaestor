# frozen_string_literal: true

class CacheManager
  def self.get(cache_obj, user_id)
    klass = to_class(cache_obj.to_s)
    get_or_set(klass, user_id)
  end

  def self.to_class(name)
    require "cache/#{name}"
    "Cache::#{name.classify}".constantize
  end

  def self.get_or_set(klass, user_id)
    if klass.exists?(user_id)
      klass.get(user_id)
    else
      val = klass.get_value(user_id)
      klass.set(user_id, val)
      val
    end
  end
end
