import http.server
import os

BUILD_DIR = os.path.join(os.path.dirname(__file__), 'flutter_application_1', 'build', 'web')

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BUILD_DIR, **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

    def log_message(self, format, *args):
        pass  # silence logs

if __name__ == '__main__':
    server = http.server.HTTPServer(('0.0.0.0', 8083), NoCacheHandler)
    print('Serveur Flutter sur http://0.0.0.0:8083')
    print(f'Dossier: {BUILD_DIR}')
    server.serve_forever()
