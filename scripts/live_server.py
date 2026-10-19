#!/usr/bin/env python3
"""Servidor estático con livereload para Kakoune.

Uso:
    live_server.py --root DIR [--port 8080] [--open index.html]

Sirve DIR, inyecta un script de livereload en las respuestas HTML y abre
el navegador en la ruta indicada (--open).
"""

import argparse
import http.server
import os
import socketserver
import subprocess
import sys
import threading
import time
import urllib.parse

SKIP_DIRS = {
    ".git", "node_modules", "__pycache__", ".cache",
    "dist", "build", ".venv", "venv", "target",
}

LIVE_JS = """
<script>
(function () {
  var last = null;
  function poll() {
    fetch('/__livereload?ts=' + Date.now(), { cache: 'no-store' })
      .then(function (r) { return r.text(); })
      .then(function (v) {
        if (last === null) { last = v; return; }
        if (v !== last) { last = v; location.reload(); }
      })
      .catch(function () {})
      .then(function () { setTimeout(poll, 1000); });
  }
  poll();
})();
</script>
"""


def tree_mtime(root):
    newest = 0.0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        for name in filenames:
            try:
                newest = max(newest, os.path.getmtime(os.path.join(dirpath, name)))
            except OSError:
                pass
    return newest


def open_browser(url):
    for cmd in (["xdg-open", url], ["open", url]):
        try:
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return
        except OSError:
            continue
    try:
        import webbrowser
        webbrowser.open(url)
    except Exception:
        pass


class Handler(http.server.SimpleHTTPRequestHandler):
    root = "."

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=self.root, **kwargs)

    def log_message(self, fmt, *args):
        sys.stderr.write("[live-server] " + (fmt % args) + "\n")

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/__livereload":
            stamp = str(int(tree_mtime(self.root) * 1000))
            body = stamp.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        path = self.translate_path(self.path)
        if os.path.isdir(path):
            path = os.path.join(path, "index.html")

        if os.path.isfile(path) and path.lower().endswith((".html", ".htm")):
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as fh:
                    data = fh.read()
            except OSError:
                data = None
            if data is not None:
                if "</body>" in data:
                    data = data.replace("</body>", LIVE_JS + "</body>", 1)
                else:
                    data += LIVE_JS
                body = data.encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Cache-Control", "no-store")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return

        super().do_GET()


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--open", default="")
    args = parser.parse_args()

    root = os.path.abspath(args.root)
    if not os.path.isdir(root):
        sys.stderr.write("[live-server] no existe el directorio: %s\n" % root)
        return 1

    Handler.root = root
    with Server(("127.0.0.1", args.port), Handler) as httpd:
        url = "http://127.0.0.1:%d/%s" % (args.port, args.open.lstrip("/"))
        sys.stderr.write("[live-server] sirviendo %s en %s\n" % (root, url))
        sys.stderr.flush()
        if args.open:
            threading.Timer(0.3, open_browser, args=(url,)).start()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
