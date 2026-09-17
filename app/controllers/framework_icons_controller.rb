# Serves /framework/icons.svg, the sprite sheet every docs icon points at. Prefixed like the
# other engine controllers because the engine is not isolated.
class FrameworkIconsController < Framework.parent_controller_class
  helper FrameworkImagesHelper

  def show
    expires_in 1.year, public: true
    # The request format is svg; the icon partials are html.erb.
    lookup_context.formats = [:html]
    sheet = Rails.cache.fetch("framework-icons/#{FrameworkImagesHelper.sprite_icon_sheet_digest}") { helpers.sprite_icon_sheet }
    render body: sheet, content_type: 'image/svg+xml'
  end
end
