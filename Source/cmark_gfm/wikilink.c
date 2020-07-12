#include "wikilink.h"
#include "parser.h"
#include "render.h"

cmark_node_type CMARK_NODE_WIKILINK;

const char *cmark_gfm_extensions_get_wikilink_title(cmark_node *node) {
  if (node == NULL || node->type != CMARK_NODE_WIKILINK) {
    return NULL;
  }
  return cmark_chunk_to_cstr(cmark_node_mem(node), &node->as.link.title);
}

const char *cmark_gfm_extensions_get_wikilink_url(cmark_node *node) {
  if (node == NULL || node->type != CMARK_NODE_WIKILINK) {
    return NULL;
  }

  return cmark_chunk_to_cstr(cmark_node_mem(node), &node->as.link.url);
}

static cmark_node *match(cmark_syntax_extension *self, cmark_parser *parser,
                         cmark_node *parent, unsigned char character,
                         cmark_inline_parser *inline_parser) {
  if (character != '[')
    return NULL;

  cmark_chunk *chunk = cmark_inline_parser_get_chunk(inline_parser);
  uint8_t *data = chunk->data;
  size_t size = chunk->len;
  int start = cmark_inline_parser_get_offset(inline_parser);
  int at = start + 1;
  int end = at;

  if (start > 0 && data[start] != '[') {
    return NULL;
  }

  // Read up until we see the first terminating ']'
  while (end < size && data[end] != ']') {
    end++;
  }

  // Try to consume the final two ']' characters
  for (int i = 0; i < 2; i++) {
    if (data[end] == ']') {
      end++;
    } else {
      return NULL;
    }
  }

  if (end == at) {
    return NULL;
  }

  cmark_node *node = cmark_node_new_with_mem(CMARK_NODE_WIKILINK, parser->mem);

  cmark_chunk *wikilink_chunk;
  wikilink_chunk = parser->mem->calloc(1, sizeof(cmark_chunk));
  wikilink_chunk->data = data + start;
  wikilink_chunk->len = end - start;

  // If contents are empty, fail the match.
  size_t contentsLen = wikilink_chunk->len - 4;
  if (contentsLen == 0) {
    return NULL;
  }

  // Convert the chunk to a c string.
  const char *fullStr = cmark_chunk_to_cstr(parser->mem, wikilink_chunk);

  // Copy the string without [[ and ]]
  char *contents = calloc(contentsLen + 1, sizeof(char));
  memcpy(contents, fullStr + 2, contentsLen);
  contents[contentsLen] = '\0';

  // If it starts with or ends with a '|', it is not valid.
  if (contents[0] == '|' || contents[strlen(contents) - 1] == '|') {
    return NULL;
  }

  // Get the first token - the description
  const char *title = strtok(contents, "|");
  if (title == NULL) {
    return NULL;
  }
  node->as.link.title = cmark_chunk_literal(title);

  // Get the part after '|'
  const char *link = strtok(NULL, "|");
  if (link == NULL) {
    // If there is no second token, this means it's a simple wikilink
    // and the reference should be the title.
    node->as.link.url = node->as.link.title;
  } else if (strlen(link) > 0) {
    // If we do get a token, set that as the URL.
    node->as.link.url = cmark_chunk_literal(link);
  } else {
    // If somehow it's empty, ignore.
    return NULL;
  }

  // Set position
  node->start_line = node->end_line = cmark_inline_parser_get_line(inline_parser);
  node->start_column = cmark_inline_parser_get_column(inline_parser);
  node->end_column = node->start_column + (wikilink_chunk->len);

  cmark_inline_parser_set_offset(inline_parser, start + (end - start));
  cmark_node_set_syntax_extension(node, self);

  return node;
}

static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
  if (ev_type != CMARK_EVENT_ENTER) {
    return;
  }

  const char *title = cmark_gfm_extensions_get_wikilink_title(node);
  const char *url = cmark_gfm_extensions_get_wikilink_url(node);

  if (title == NULL || url == NULL) {
    return;
  }

  cmark_strbuf *html = renderer->html;
  cmark_strbuf_puts(html, "<a href=\"");
  cmark_strbuf_puts(html, url);
  cmark_strbuf_puts(html, "\">");
  cmark_strbuf_puts(html, title);
  cmark_strbuf_puts(html, "</a>");
}

static const char *get_type_string(cmark_syntax_extension *extension,
                                   cmark_node *node) {
  return node->type == CMARK_NODE_WIKILINK ? "wikilink" : "<unknown>";
}

static int can_contain(cmark_syntax_extension *extension, cmark_node *node,
                       cmark_node_type child_type) {
  if (node->type != CMARK_NODE_WIKILINK)
    return false;

  return CMARK_NODE_TYPE_INLINE_P(child_type);
}

cmark_syntax_extension *create_wikilink_extension(void) {
  cmark_syntax_extension *self = cmark_syntax_extension_new("wikilink");
  cmark_llist *special_chars = NULL;

  cmark_syntax_extension_set_get_type_string_func(self, get_type_string);
  cmark_syntax_extension_set_can_contain_func(self, can_contain);
  cmark_syntax_extension_set_html_render_func(self, html_render);

  CMARK_NODE_WIKILINK = cmark_syntax_extension_add_node(1);

  cmark_syntax_extension_set_match_inline_func(self, match);

  cmark_mem *mem = cmark_get_default_mem_allocator();
  special_chars = cmark_llist_append(mem, special_chars, (void *)'[');
  cmark_syntax_extension_set_special_inline_chars(self, special_chars);

  return self;
}

