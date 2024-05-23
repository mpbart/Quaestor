# frozen_string_literal: true

module ApplicationHelper
  def inline_svg(path)
    file_path = Rails.root.join('app', 'assets', 'images', path)
    File.exist?(file_path) ? File.read(file_path).html_safe : 'no svg found'
  end
end
