# Prefixed because the engine is not isolated: a bare `ImagesHelper` would claim a
# generic global name in every host. The helper methods themselves are unchanged.
module FrameworkImagesHelper
  ICONS_DIR = Framework::Engine.root.join('app/views/shared/icons')

  # Stamps the sheet URL and its cache key, so an icon edit reaches browsers holding the
  # year-long cached sheet. Read once per process.
  def self.sprite_icon_sheet_digest
    @sprite_icon_sheet_digest ||= Digest::SHA256.hexdigest(Dir.glob(ICONS_DIR.join('_*.html.erb')).map { |path| File.read(path) }.join)[0, 12]
  end

  def sprite_icon(name, classes: nil)
    href = "#{framework_icons_path(v: FrameworkImagesHelper.sprite_icon_sheet_digest)}##{sprite_icon_id(name)}"
    tag.svg(tag.use(href:), class: classes.presence || 'h-16 w-16')
  end

  def sprite_icon_id(name) = "fw-icon-#{name}"

  # The icons any docs page can point at, so the sheet /framework/icons.svg serves them all.
  def sprite_icon_sheet
    pages = FrameworkController::DOC_GROUPS_BY_VERSION.values.flat_map { |groups| groups.values.flatten }
    names = pages.map { |page| FrameworkHelper::PAGE_ICON_ALIASES.fetch(page, page) }.push('guide', 'info').uniq
    names = names.select { |name| lookup_context.exists?(name, ['shared/icons'], true) }
    tag.svg(safe_join(names.sort.map { |name| sprite_icon_symbol(name) }), xmlns: 'http://www.w3.org/2000/svg')
  end

  def sprite_icon_symbol(name)
    source = render(partial: "shared/icons/#{name}", locals: { classes: nil })
    source = source.gsub(/<!--.*?-->/m, '').strip
    root = source[/<svg\b[^>]*>/]
    raise ArgumentError, "shared/icons/#{name} did not render an <svg> root" unless root

    # Strip fixed dimensions along with the class: a <symbol> must size to the
    # <use> site (icons carrying width="32" would clip inside smaller boxes).
    attrs = root.delete_prefix('<svg').delete_suffix('>').gsub(/ (?:class|width|height)="[^"]*"/, '')
    source.sub(root, %(<symbol id="#{sprite_icon_id(name)}"#{attrs}>)).sub(%r{</svg>\s*\z}m, '</symbol>').html_safe
  end
end
