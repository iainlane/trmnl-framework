# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Framework mashup styles' do
  subject(:css) { FrameworkBuild.plugins_css }

  it 'publishes fixed placement modifiers for fluid mashups' do
    (1..3).each do |track|
      expect(css).to include(".mashup--3x3>.mashup-cell--col-#{track}{grid-column-start:#{track}}")
      expect(css).to include(".mashup--3x3>.mashup-cell--col-span-#{track}{grid-column-end:span #{track}}")
      expect(css).to include(".mashup--3x3>.mashup-cell--row-#{track}{grid-row-start:#{track}}")
      expect(css).to include(".mashup--3x3>.mashup-cell--row-span-#{track}{grid-row-end:span #{track}}")
    end
  end

  # A host can render one cell as its own document, where .mashup--3x3 is not an
  # ancestor and this stylesheet loads again. The rules that size the wrapped view
  # must not ask for the grid.
  context 'when a cell renders outside the grid' do
    it 'sizes the view it wraps to the cell' do
      expect(css).to include('.mashup-cell>.view{width:100% !important;height:100% !important;')
    end

    it 'gives the layout the cell padding instead of the view size class padding' do
      expect(css).to include('.mashup-cell>.view>.layout{height:100%;padding:var(--gap);margin-bottom:0}')
    end

    it 'generates no box of its own, so the view keeps the document as its containing block' do
      expect(css).to include('.mashup-cell{display:contents}')
    end
  end
end
