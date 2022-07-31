import socket
from datetime import datetime

localIP     = "192.168.1.90"
localPort   = 1234
bufferSize  = 1024
msgFromServer = "Hello UDP Client"
bytesToSend   = str.encode(msgFromServer)
# Create a datagram socket
UDPServerSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
# Bind to address and ip
UDPServerSocket.bind((localIP, localPort))
print("UDP server up and listening")

# Listen for incoming datagrams
while(True):
    dt = datetime.now()
    bytesAddressPair = UDPServerSocket.recvfrom(bufferSize)
    message = bytesAddressPair[0]
    address = bytesAddressPair[1]
    clientMsg = "[{}] Message from Client:{}".format(dt, message)
    clientIP  = "[{}] Client IP Address:{}".format(dt, address)
    print(clientMsg)
    print(clientIP)
    # Sending a reply to client
    UDPServerSocket.sendto(bytesToSend, address)
