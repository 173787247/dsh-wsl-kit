#!/usr/bin/env python3
"""Relay Windows → *:3081 → 127.0.0.1:3080 (IPv6 dual-stack, mirrors uvicorn-style * bind)."""
import socket
import threading

LISTEN = ("::", 3081)
TARGET = ("127.0.0.1", 3080)


def pipe(a, b):
    try:
        while True:
            data = a.recv(65536)
            if not data:
                break
            b.sendall(data)
    except Exception:
        pass
    finally:
        for x in (a, b):
            try:
                x.close()
            except Exception:
                pass


def handle(c):
    try:
        u = socket.create_connection(TARGET, timeout=5)
    except Exception:
        c.close()
        return
    threading.Thread(target=pipe, args=(c, u), daemon=True).start()
    pipe(u, c)


def main():
    s = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        s.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
    except Exception:
        pass
    s.bind(LISTEN)
    s.listen(50)
    print(f"relay {LISTEN} -> {TARGET}", flush=True)
    while True:
        c, _ = s.accept()
        threading.Thread(target=handle, args=(c,), daemon=True).start()


if __name__ == "__main__":
    main()
