options = {
  autolink: true,
  no_intra_emphasis: true,
  fenced_code_blocks: true,
  strikethrough: true,
  superscript: true
}
render_options = {
  filter_html: false,
  hard_wrap: true
}

renderer = Redcarpet::Render::HTML.new(render_options)
MY_MARKDOWN = Redcarpet::Markdown.new(renderer, options)