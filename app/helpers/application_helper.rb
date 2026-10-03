# frozen_string_literal: true

module ApplicationHelper
  def inline_svg(path)
    case path
    when 'angle_icon.svg'
      image_tag('angle_icon.svg', class: 'angle-icon', alt: '')
    when 'dash-icon.svg'
      image_tag('dash-icon.svg', class: 'dash-icon', alt: '')
    else
      'no svg found'
    end
  end
end
