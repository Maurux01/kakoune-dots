#!/usr/bin/env python3
"""Render markdown a HTML para el preview de Kakoune.

Uso:
    md_preview.py --src FILE.md --out FILE.html [--title T]

Usa pandoc si está disponible; si no, usa un conversor interno mínimo
(headings, código, listas, citas, links, énfasis).
"""

import argparse
import html
import os
import re
import shutil
import subprocess
import sys

CSS = """
:root {
  --bg: #282828; --bg1: #3c3836; --bg2: #504945;
  --fg: #ebdbb2; --fg2: #d5c4a1; --muted: #928374;
  --red: #fb4934; --green: #b8bb26; --yellow: #fabd2f;
  --blue: #83a598; --purple: #d3869b; --aqua: #8ec07c; --orange: #fe8019;
}
* { box-sizing: border-box; }
body {
  background: var(--bg); color: var(--fg); margin: 0 auto; padding: 2.5rem 1.25rem;
  max-width: 52rem; font: 16px/1.65 -apple-system, "Segoe UI", Roboto, sans-serif;
}
h1, h2, h3, h4, h5, h6 { color: var(--yellow); line-height: 1.25; margin: 1.8em 0 .6em; }
h1 { font-size: 2em; border-bottom: 1px solid var(--bg2); padding-bottom: .25em; }
h2 { font-size: 1.5em; }
h3 { font-size: 1.25em; color: var(--blue); }
h4, h5, h6 { color: var(--aqua); }
p { margin: .9em 0; }
a { color: var(--blue); text-decoration: none; }
a:hover { text-decoration: underline; }
code {
  background: var(--bg1); color: var(--green); padding: .15em .4em;
  border-radius: 4px; font-size: .9em;
}
pre {
  background: var(--bg1); border-left: 3px solid var(--blue);
  padding: 1rem; overflow-x: auto; border-radius: 6px;
}
pre code { background: none; padding: 0; color: var(--fg); }
blockquote {
  border-left: 3px solid var(--bg2); margin: 1em 0; padding: .2em 1em;
  color: var(--fg2);
}
ul, ol { padding-left: 1.4em; }
li { margin: .25em 0; }
li::marker { color: var(--orange); }
hr { border: 0; border-top: 1px solid var(--bg2); margin: 2em 0; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { border: 1px solid var(--bg2); padding: .45em .7em; text-align: left; }
th { background: var(--bg1); color: var(--yellow); }
img { max-width: 100%; }
input[type="checkbox"] { accent-color: var(--green); }
"""


def fallback_render(text):
    """Conversor markdown mínimo (CommonMark-ish) sin dependencias."""
    text = text.lstrip("\ufeff")
    out = []
    in_code = False
    code_buf = []
    list_type = None  # "ul" | "ol" | None
    in_li = False

    def close_li():
        nonlocal in_li
        if in_li:
            out.append("</li>")
            in_li = False

    def close_list():
        nonlocal list_type
        close_li()
        if list_type:
            out.append("</%s>" % list_type)
            list_type = None

    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]

        if line.startswith("```"):
            if in_code:
                out.append("<pre><code>%s</code></pre>" % html.escape("\n".join(code_buf)))
                code_buf = []
                in_code = False
            else:
                close_list()
                in_code = True
            i += 1
            continue
        if in_code:
            code_buf.append(line)
            i += 1
            continue

        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            close_list()
            level = len(m.group(1))
            out.append("<h%d>%s</h%d>" % (level, inline(m.group(2)), level))
            i += 1
            continue

        if re.match(r"^\s*([-*_])(?:\s*\1){2,}\s*$", line):
            close_list()
            out.append("<hr>")
            i += 1
            continue

        m = re.match(r"^\s*[-*+]\s+(.*)$", line)
        if m:
            if list_type != "ul":
                close_list()
                out.append("<ul>")
                list_type = "ul"
            close_li()
            out.append("<li>%s" % inline(m.group(1)))
            in_li = True
            i += 1
            continue

        m = re.match(r"^\s*\d+[.)]\s+(.*)$", line)
        if m:
            if list_type != "ol":
                close_list()
                out.append("<ol>")
                list_type = "ol"
            close_li()
            out.append("<li>%s" % inline(m.group(1)))
            in_li = True
            i += 1
            continue

        if line.strip() == "":
            close_list()
            i += 1
            continue

        if line.startswith(">"):
            close_list()
            quote = []
            while i < len(lines) and lines[i].startswith(">"):
                quote.append(lines[i].lstrip(">").strip())
                i += 1
            out.append("<blockquote>%s</blockquote>" % inline(" ".join(quote)))
            continue

        close_list()
        para = []
        while i < len(lines) and lines[i].strip() and not re.match(
            r"^(#{1,6}\s|```|\s*[-*+]\s|\s*\d+[.)]\s|>)", lines[i]
        ):
            para.append(lines[i].strip())
            i += 1
        if para:
            out.append("<p>%s</p>" % inline(" ".join(para)))

    close_list()
    if in_code and code_buf:
        out.append("<pre><code>%s</code></pre>" % html.escape("\n".join(code_buf)))
    return "\n".join(out)


def inline(text):
    text = html.escape(text)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(r"!\[([^\]]*)\]\(([^)]+)\)", r'<img alt="\1" src="\2">', text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", text)
    text = re.sub(r"_([^_]+)_", r"<em>\1</em>", text)
    text = re.sub(r"~~([^~]+)~~", r"<del>\1</del>", text)
    return text


def page(body, title):
    return (
        "<!DOCTYPE html>\n<html lang=\"es\"><head><meta charset=\"utf-8\">\n"
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
        "<title>%s</title>\n<style>%s</style>\n</head>\n<body>\n%s\n</body></html>\n"
        % (html.escape(title), CSS, body)
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--title", default="")
    args = parser.parse_args()

    try:
        with open(args.src, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError as exc:
        sys.stderr.write("md_preview: %s\n" % exc)
        return 1

    title = args.title or os.path.basename(args.src)
    body = None

    if shutil.which("pandoc"):
        try:
            result = subprocess.run(
                ["pandoc", "--from", "markdown", "--to", "html5", args.src],
                capture_output=True, text=True, check=True,
            )
            body = result.stdout
        except (subprocess.CalledProcessError, OSError):
            body = None

    if body is None:
        body = fallback_render(text)

    try:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(page(body, title))
    except OSError as exc:
        sys.stderr.write("md_preview: %s\n" % exc)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
