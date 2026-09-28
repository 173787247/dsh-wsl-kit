#!/usr/bin/env python3
"""TCP/HTTP relay: Windows → *:3081 → 127.0.0.1:3080.

Do NOT rewrite the Host header. dsh's browser-trust fence requires
Origin host === Host header host; the page is served from :3081 so both
must stay 127.0.0.1:3081. Loopback Host already passes the fence.

Ports are arguments with the live values as defaults, so a second dsh can be
rehearsed on another pair without this relay fighting the one already bound.
Hardcoded ports made that impossible: the rehearsal's relay tried to bind 3081,
failed with OSError: Address already in use, and the restart looked as if it had
broken the relay.
"""
from __future__ import annotations

import argparse
import socket
import threading

LISTEN = ("::", 3081)
TARGET = ("127.0.0.1", 3080)
# handle() runs on its own threads; this carries the resolved target port.
TARGET_PORT = [3080]


def parse_args() -> tuple[tuple[str, int], tuple[str, int]]:
    ap = argparse.ArgumentParser(description="TCP relay in front of dsh web.")
    ap.add_argument("--listen", type=int, default=LISTEN[1],
                    help=f"port to bind on all interfaces (default {LISTEN[1]})")
    ap.add_argument("--target", type=int, default=TARGET[1],
                    help=f"dsh web port to forward to (default {TARGET[1]})")
    a = ap.parse_args()
    return (LISTEN[0], a.listen), (TARGET[0], a.target)


def pipe(src: socket.socket, dst: socket.socket) -> None:
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
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
        upstream = socket.create_connection(("127.0.0.1", TARGET_PORT[0]), timeout=5)
    except OSError:
        try:
            client.sendall(
                b"HTTP/1.1 502 Bad Gateway\r\n"
                b"Content-Type: text/plain; charset=utf-8\r\n"
                b"Connection: close\r\n\r\n"
                + f"dsh is not listening on 127.0.0.1:{TARGET_PORT[0]}.\n".encode()
                + b"Run: bash dsh-wsl-kit/scripts/restart-dsh-web.sh\n"
            )
        except Exception:
            pass
        try:
            client.close()
        except Exception:
            pass
        return

    threading.Thread(target=pipe, args=(upstream, client), daemon=True).start()
    pipe(client, upstream)


def main() -> None:
    listen, target = parse_args()
    TARGET_PORT[0] = target[1]
    sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
    except OSError:
        pass
    sock.bind(listen)
    sock.listen(64)
    print(f"relay {listen} -> {target} (Host unchanged)", flush=True)
    while True:
        client, _ = sock.accept()
        threading.Thread(target=handle, args=(client,), daemon=True).start()


if __name__ == "__main__":
    main()
