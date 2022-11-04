# -*- coding: utf-8 -*-

# POETASTER
import sys
sys.path.append('/usr/share/harbour-tooterb/qml')
sys.path.append('/usr/share/harbour-tooterb/qml/lib')
sys.path.append('/usr/share/harbour-tooterb/qml/pages')

# POETASTER

import pyotherside
import threading
import time
import random
import os
import http.server
import socketserver

PORT = 8000
directory = '/usr/share/harbour-tooterb/qml/lib'
Handler = http.server.SimpleHTTPRequestHandler
os.chdir(directory)

def serveMe():
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print("serving at port", PORT)
        pyotherside.send('finished', PORT)
        httpd.serve_forever()

class Downloader:
    def __init__(self):
        # Set bgthread to a finished thread so we never
        # have to check if it is None.
        self.bgthread = threading.Thread()
        self.bgthread.start()

    def serve(self):
        if self.bgthread.is_alive():
            return
        self.bgthread = threading.Thread(target=serveMe)
        self.bgthread.start()

downloader = Downloader()
