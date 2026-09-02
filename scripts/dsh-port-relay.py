#!/usr/bin/env python3
"""HTTP relay: Windows → *:3081 → 127.0.0.1:3080 with Host rewritten to :3080.

dsh only binds 127.0.0.1 and rejects --host 0.0.0.0. The browser trust fence
also expects Host: 127.0.0.1:3080; accessing via :3081 otherwise gets reset.
"""
from __future__ import annotations

import re
import socket
import threading

LISTEN = ("::", 3081)
TARGET = ("127.0.0.1", 3080)
HOST_REWRITE = re.compile(rb"(?im)^Host:\s*[^\r\n]*\r\n")


def pipe(src: socket.socket, dst: socket.socket, rewrite_host: bool = False) -> None:
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            if rewrite_host:
                data = HOST_REWRITE.sub(b"Host: 127.0.0.1:3080\r\n", data, count=1)
                rewrite_host = False
            dst.sendall(data)
    except Exception:
        pass
    finally:
        for s in (src, dst):
            try:
                s.shutdown(socket.SHUT_RDWR)
            except Exception:
                pass
            try:
                s.close()
            except Exception:
                pass


def handle(client: socket.socket) -> None:
    try:
        upstream = socket.create_connection(TARGET, timeout=5)
    except OSError:
        try:
            client.sendall(
                b"HTTP/1.1 502 Bad Gateway\r\n"
                b"Content-Type: text/plain; charset=utf-8\r\n"
                b"Connection: close\r\n\r\n"
                b"dsh is not listening on 127.0.0.1:3080.\n"
                b"Run: bash dsh-wsl-kit/scripts/restart-dsh-web.sh\n"
            )
        except Exception:
            pass
        try:
            client.close()
        except Exception:
            pass
        return

    threading.Thread(target=pipe, args=(upstream, client, False), daemon=True).start()
    pipe(client, upstream, rewrite_host=True)


def main() -> None:
    sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
    except OSError:
        pass
    sock.bind(LISTEN)
    sock.listen(64)
    print(f"relay {LISTEN} -> {TARGET} (Host -> 127.0.0.1:3080)", flush=True)
    while True:
        client, _ = sock.accept()
        threading.Thread(target=handle, args=(client,), daemon=True).start()


if __name__ == "__main__":
    main()
