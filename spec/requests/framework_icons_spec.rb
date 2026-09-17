# frozen_string_literal: true

require 'rails_helper'

# The docs chrome points every icon at one sprite sheet the browser fetches once per icon
# set, instead of each page inlining the symbols it happens to reference.
RSpec.describe 'Framework icon sprite', type: :request do
  before(:all) { FrameworkBuild.docs_assets! }

  describe 'the sheet' do
    before { get '/framework/icons.svg' }

    it 'is an svg document' do
      expect(response.media_type).to eq('image/svg+xml')
    end

    it 'defines the fallback icons every version shares' do
      expect(response.body).to include('<symbol id="fw-icon-guide"', '<symbol id="fw-icon-info"')
    end

    it 'defines each icon once' do
      ids = response.body.scan(/<symbol id="([^"]+)"/).flatten
      expect(ids).to eq(ids.uniq)
    end

    it 'sizes each symbol to its use site' do
      expect(response.body).not_to match(/<symbol[^>]* (width|height|class)=/)
    end

    # A browser parses an external sheet as XML and drops every symbol after the
    # first error; the inline sprite had been hiding a `stroke-` left by the width strip.
    it 'is well-formed xml' do
      expect { Nokogiri::XML(response.body, &:strict) }.not_to raise_error
    end

    it 'keeps a stroke-width' do
      expect(response.body).to include('<symbol id="fw-icon-colors" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="0.5">')
    end

    it 'is cacheable for a year' do
      expect(response.headers['Cache-Control']).to include('max-age=31556952', 'public')
    end
  end

  describe 'a docs page' do
    let(:page) { get("/framework/docs/#{FrameworkController::CURRENT_DOCS_VERSION}/label") && response.body }
    let(:sheet) { get('/framework/icons.svg') && response.body }
    let(:referenced_icons) { page.scan(%r{href="/framework/icons\.svg\?v=[^#]+#(fw-icon-[^"]+)"}).flatten.uniq }

    it 'points its icons at the sheet, stamped with a digest of the icon partials' do
      expect(page).to match(%r{href="/framework/icons\.svg\?v=\h{12}#fw-icon-label"})
    end

    it 'moves the stamp when an icon partial changes' do
      stamp_before = FrameworkImagesHelper.sprite_icon_sheet_digest
      allow(File).to(receive(:read).and_wrap_original { |read, path| path.to_s.end_with?('/_label.html.erb') ? '<svg/>' : read.call(path) })
      FrameworkImagesHelper.remove_instance_variable(:@sprite_icon_sheet_digest)
      stamp_after = FrameworkImagesHelper.sprite_icon_sheet_digest
      FrameworkImagesHelper.remove_instance_variable(:@sprite_icon_sheet_digest)

      expect(stamp_after).not_to eq(stamp_before)
    end

    it 'inlines no symbol' do
      expect(page).not_to include('<symbol')
    end

    it 'references only icons the sheet defines' do
      defined = sheet.scan(/<symbol id="(fw-icon-[^"]+)"/).flatten
      expect(referenced_icons - defined).to be_empty
    end
  end
end
