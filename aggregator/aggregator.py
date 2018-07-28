import asyncio
import websockets

listeners = set()
senders = dict()

SERVER_ADDRESS = '0.0.0.0'
PORT = '8080'


def average() -> str:
    if len(senders) == 0:
        return '0'
    return str(sum(senders.values()) / len(senders))


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
            try:
                print(f'received message: {message} from client {websocket}')
                senders[websocket] = int(message)
            except ValueError:
                print(f"non-integer data received: {message}")
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


print(f'Running server at {SERVER_ADDRESS} on port {PORT}...')
asyncio.get_event_loop().set_debug(enabled=True)
asyncio.get_event_loop().run_until_complete(
    websockets.serve(handler, SERVER_ADDRESS, PORT))
asyncio.get_event_loop().run_forever()
