import argparse
import asyncio
import ssl
import websockets

import logging

listeners = set()
senders = dict()

SERVER_ADDRESS = '0.0.0.0'
PORT = '8080'


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
    logging.debug(f'listener {websocket.remote_address} connected')
    try:
        async for message in websocket:
            # Wait until the connection is closed
            pass
    finally:
        listeners.remove(websocket)
        logging.debug(f'listener {websocket.remote_address} disconnected')


async def sender_handler(websocket):
    try:
        logging.debug(f'sender {websocket.remote_address} connected')
        async for message in websocket:
            logging.debug(f'received message: {message} from sender {websocket.remote_address}')
            try:
                senders[websocket] = int(message)
            except ValueError:
                logging.error(f"non-integer data received from sender {websocket.remote_address}: {message}")
            await update_listeners()
    finally:
        if websocket in senders:
            del senders[websocket]
        logging.debug(f'sender {websocket.remote_address} disconnected')
        await update_listeners()


async def handler(websocket, path):
    if path == '/listen':
        await listener_handler(websocket)
    elif path == '/send':
        await sender_handler(websocket)


def get_commandline_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--use_ssl', action='store_true', help='If this is set, SSL will be enabled for the server.')
    parser.add_argument('--cert_path', help='The full path to the full SSL certificate chain.')
    parser.add_argument('--privkey_path', help='The full path to the server\'s private key.')
    parser.add_argument('--logging_level', help='How detailed the logs will be.',
                        choices=['debug', 'info', 'warning', 'error', 'critical'], default='info')
    return parser.parse_args()


def get_logging_level(level_arg):
    return getattr(logging, level_arg.upper())


def main():
    args = get_commandline_args()
    logging_level = get_logging_level(args.logging_level)
    logging.basicConfig(level=logging_level)
    logging.info(f'Starting PlexusPlay server at {SERVER_ADDRESS} on port {PORT} with logging level '
                 f'{logging.getLevelName(logging_level)}...')
    if args.use_ssl:
        logging.info('SSL is enabled.')
        if not args.cert_path or not args.privkey_path:
            logging.error('cert_path and privkey_path are both required when use_ssl is enabled. Exiting.')
            return
        ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ssl_context.load_cert_chain(args.cert_path, keyfile=args.privkey_path)
        asyncio.get_event_loop().run_until_complete(
            websockets.serve(handler, SERVER_ADDRESS, PORT, ssl=ssl_context))
        asyncio.get_event_loop().run_forever()
    else:
        logging.info('SSL is disabled.')
        asyncio.get_event_loop().run_until_complete(
            websockets.serve(handler, SERVER_ADDRESS, PORT))
        asyncio.get_event_loop().run_forever()


if __name__ == '__main__':
    main()
