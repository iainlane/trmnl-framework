# frozen_string_literal: true

require 'rails_helper'

# The docs palette lists every page of the section being read, once, in a dialog. The
# list is fetched on first open, so a page carries the dialog and the list's URL alone.
RSpec.describe 'Framework command palette', type: :request do
  # Same guard as spec/requests/framework_docs_spec.rb: the docs layout links the
  # compiled bundles from app/assets/builds, which is gitignored.
  before(:all) { FrameworkBuild.docs_assets! }

  let(:version) { FrameworkController::CURRENT_DOCS_VERSION }
  let(:docs_pages) { FrameworkController::DOC_GROUPS_BY_VERSION.fetch(version).values.flatten }

  describe 'a docs page' do
    before { get "/framework/docs/#{version}/chart" }

    it 'ships no items' do
      expect(response.body).not_to include('data-command-palette-target="item"')
    end

    it 'names the list of its version' do
      expect(response.body).to include(%(data-command-palette-items-url-value="/framework/docs/#{version}/command_palette"))
    end
  end

  describe 'an examples page' do
    before { get '/framework/examples' }

    it 'names the examples list' do
      expect(response.body).to include('data-command-palette-items-url-value="/framework/examples/command_palette"')
    end
  end

  describe 'the docs list' do
    before { get "/framework/docs/#{version}/command_palette" }

    it 'lists every page of the version being read' do
      expect(response.body.scan('data-command-palette-target="item"').size).to eq(docs_pages.size)
    end

    it 'renders each page once' do
      expect(response.body.scan('data-key="chart"').size).to eq(1)
    end

    it 'names each group after the section it belongs to' do
      expect(response.body).to include('data-group="Docs - Components"')
    end

    it 'links each page inside its version' do
      expect(response.body).to include(%(data-href="/framework/docs/#{version}/chart"))
    end

    it 'lists the items rather than a set of provider templates to swap between' do
      expect(response.body).not_to include('data-provider-id')
    end

    it 'comes without the docs layout' do
      expect(response.body).not_to include('<html')
    end
  end

  describe 'the examples list' do
    before { get '/framework/examples/command_palette' }

    it 'names its groups after the examples section' do
      expect(response.body).to include('data-group="Examples - ')
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
