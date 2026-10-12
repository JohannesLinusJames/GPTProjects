"""Launch DutyDesk as a local Python application, optionally in a native window."""
import argparse
import threading
import webbrowser
from werkzeug.serving import make_server
from app import app

def main():
    parser=argparse.ArgumentParser(description='DutyDesk local application')
    parser.add_argument('--desktop',action='store_true',help='Use an optional pywebview native window')
    args=parser.parse_args()
    server=make_server('127.0.0.1',0,app,threaded=True)
    url=f'http://127.0.0.1:{server.server_port}'
    threading.Thread(target=server.serve_forever,daemon=True).start()
    try:
        if args.desktop:
            try: import webview
            except ImportError: raise SystemExit('Install pywebview first: python -m pip install pywebview')
            webview.create_window('DutyDesk',url,width=1400,height=950,min_size=(800,600))
            webview.start()
        else:
            webbrowser.open(url)
            print('DutyDesk is running in your browser. Press Ctrl+C to exit.')
            threading.Event().wait()
    except KeyboardInterrupt: pass
    finally: server.shutdown()

if __name__=='__main__': main()
