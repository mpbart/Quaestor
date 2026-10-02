# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#inline_svg' do
    it 'renders an approved SVG as an image asset' do
      icon = helper.inline_svg('angle_icon.svg')

      expect(icon).to match(/<img[^>]+class="angle-icon"/)
      expect(icon).to include('angle_icon')
    end

    it 'does not render unapproved paths' do
      icon = helper.inline_svg('../../tmp/malicious.svg')

      expect(icon).to eq('no svg found')
    end
  end
end
