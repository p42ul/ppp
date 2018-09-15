import asyncio
import ssl
import websockets

import logging

logging.basicConfig(level=logging.INFO)

listeners = set()
senders = dict()

SERVER_ADDRESS = '0.0.0.0'
PORT = '8080'

CERT_PATH = '/etc/letsencrypt/live/plexusplay.app/fullchain.pem'
PRIVKEY_PATH = '/etc/letsencrypt/live/plexusplay.app/privkey.pem'


def average() -> str:
    if len(senders) == 0:
        return '0'
    return str(sum(senders.values()) // len(senders))


async def update_listeners():
    if listeners:  # asyncio.wait doesn't accept an empty list
        message = average()
        await asyncio.wait([listener.send(message) for listener in listeners])


async def listener_handler(websocket):
    listeners.add(websocket)
    try:
        async for message in websocket:
            # Wait until the connection is closed
            pass
    finally:
        listeners.remove(websocket)


async def sender_handler(websocket):
    try:
        async for message in websocket:
            logging.debug(f'received message: {message} from client {websocket}')
            try:
                senders[websocket] = int(message)
            except ValueError:
                logging.error(f"non-integer data received: {message}")
            await update_listeners()
    finally:
        if websocket in senders:
            del senders[websocket]
        await update_listeners()


async def handler(websocket, path):
    if path == '/listen':
        await listener_handler(websocket)
    elif path == '/send':
        await sender_handler(websocket)


def main():
    logging.info(f'Running PlexusPlay server at {SERVER_ADDRESS} on port {PORT}...')
    # Set up SSL
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(CERT_PATH, keyfile=PRIVKEY_PATH)
    # Run server
    asyncio.get_event_loop().run_until_complete(
        websockets.serve(handler, SERVER_ADDRESS, PORT, ssl=ssl_context))
    asyncio.get_event_loop().run_forever()


if __name__ == '__main__':
    main()
