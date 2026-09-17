# frozen_string_literal: true

require 'rails_helper'

# The docs palette lists every page of the version being read, once, in a dialog.
RSpec.describe 'Framework command palette', type: :request do
  # Same guard as spec/requests/framework_docs_spec.rb: the docs layout links the
  # compiled bundles from app/assets/builds, which is gitignored.
  before(:all) { FrameworkBuild.docs_assets! }

  let(:docs_pages) do
    FrameworkController::DOC_GROUPS_BY_VERSION.fetch(FrameworkController::CURRENT_DOCS_VERSION).values.flatten
  end

  describe 'the items on a docs page' do
    before { get "/framework/docs/#{FrameworkController::CURRENT_DOCS_VERSION}" }

    it 'lists every page of the version being read' do
      expect(response.body.scan('data-command-palette-target="item"').size).to eq(docs_pages.size)
    end

    it 'renders each page once' do
      expect(response.body.scan('data-key="chart"').size).to eq(1)
    end

    it 'names each group after the section it belongs to' do
      expect(response.body).to include('data-group="Docs - Components"')
    end

    it 'lists the items rather than a set of provider templates to swap between' do
      expect(response.body).not_to include('data-provider-id')
    end
  end

  # Rails memoizes template digests per virtual path, so the engine's cached
  # shared/_command_palette and core's copy of that path shared one Rails.cache entry.
  describe 'the views the engine ships' do
    subject(:fragment_caching_views) do
      Dir.glob(Framework::Engine.root.join('app/views/**/*.erb')).select do |path|
        File.read(path).match?(/<%=?\s*cache[\s(]/)
      end
    end

    it 'cache no fragments' do
      expect(fragment_caching_views).to be_empty
    end
  end
end
