from __future__ import annotations

import http.server
import socketserver
import threading
import webbrowser
from pathlib import Path

HOST = "127.0.0.1"
PORT = 4173
ROOT = Path(__file__).resolve().parents[1]


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args: object, **kwargs: object) -> None:
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    url = f"http://{HOST}:{PORT}"
    threading.Timer(0.5, lambda: webbrowser.open(url)).start()
    print(f"CRM Patrimonial Next disponible en {url}")
    print("Cierra esta ventana o presiona Ctrl+C para detenerlo.")
    with ReusableTCPServer((HOST, PORT), Handler) as server:
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nServidor detenido.")
