from SimpleWebSocketServer import SimpleWebSocketServer, WebSocket

clients = {}


class Aggregator(WebSocket):
    def handleMessage(self):
        global clients
        clients[self] = self.data
        print("average is now: {}".format(average()))

    def handleClose(self):
        global clients
        del clients[self]


def average():
    global clients
    if len(clients) == 0:
        return 0
    return sum([int(x) for x in clients.values()]) / len(clients)


server = SimpleWebSocketServer('localhost', 80, Aggregator)
server.serveforever()
