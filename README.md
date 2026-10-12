# DutyDesk

A local-first officer directory and monthly duty-return application. The responsive web interface runs on a Python Flask backend with SQLite storage. `desktop.py` launches the same program from Python, with an optional native desktop window.

## Run

### Automatic Windows installation

1. Extract the entire ZIP to a permanent folder you can write to, such as Documents\DutyDesk.
2. Double-click **Install DutyDesk.bat**.

The installer finds Python 3.10 or newer or installs a private, per-user Python 3.13.7 from Python.org after validating its publisher signature. It creates a Windows virtual environment, installs dependencies, checks the app, creates a desktop shortcut, and opens DutyDesk in your browser. No commands or administrator installation are needed. Internet access is required for initial setup. Windows may still show its normal security prompts; an installer cannot guarantee a completely prompt-free experience.

Use the **DutyDesk** desktop shortcut or **Start DutyDesk.bat** thereafter. Keep the console window open while using the app; closing it stops the server. Keep the extracted folder in place. Re-running installation preserves saved officer and duty records; failures are recorded in `install.log`. The installer targets Windows 10/11 with Windows PowerShell 5.1; its automatic Python fallback supports x86/x64 (ARM64 requires x64 emulation or an existing compatible Python). Windows execution has not been verified in the Linux development environment.

### Manual installation / other operating systems

Python 3.10 or newer:

```sh
python -m venv .venv
# macOS/Linux
source .venv/bin/activate
# Windows instead: .venv\Scripts\activate
python -m pip install -r requirements.txt
python desktop.py
```

For the web application alone, run `python app.py` and visit `http://127.0.0.1:5000` in your browser. `PORT` overrides the port.

For a native desktop window, install `pywebview` and run `python desktop.py --desktop`. Linux also needs a supported GTK/Qt webview runtime; see pywebview's installation documentation. This optional mode requires a graphical desktop. Browser mode requires no extra GUI libraries. PDF printing uses the browser's PDF viewer; if the desktop webview does not support PDF downloads, use browser mode.

## Workflow

1. Add officers with regimental number, rank, name, NIS, station/branch, division, BIR, commercial bank, telephone, cellular, account number and optional station address.
2. Select one or more officers. Enter date, time in/out, duty type, diary references and remarks. A blank station uses each officer's profile; entering a station overrides it for this duty only.
3. Select a month, then export Word or PDF. Multiple selected officers produce a ZIP containing one return per officer. Select one officer and click Print to open the PDF, then use the viewer's Print control.
4. Edit profiles in Officer directory. Correct a mistaken duty by deleting and re-entering it.

Hours use exact elapsed minutes, displayed as HH:MM, without rounding or automatic break deductions. Earlier time out means the next day. Equal times are rejected; split duties of 24 hours or longer. Overlapping entries are rejected, including across midnight. A batch save is atomic: all selected officers are saved or none are. Overnight hours belong to the start date/month. Blank days are included in monthly returns, and signature fields remain blank for signing.

## Documents

Word exports populate `assets/duty-template.docx`, the supplied template, retaining its branding and certification sections and replacing sample profile and duty data. Sample officer details, duty entries, and author metadata have been removed from the bundled template. PDF exports recreate its content and table in a clean legal-size portrait layout; they are not a pixel-identical Word conversion. Profile edits appear in subsequently generated returns; duty station overrides are retained independently. Long content or multiple shifts can produce extra pages.

## Storage and scope

Records persist in `instance/duties.sqlite`. Back up this file while the app is stopped and protect the backup; it contains personal and banking information. `DUTY_DATABASE` overrides the location. No records are sent to an external service. This first version is intended for a trusted local workstation: there is no login, role system or database encryption. Keep the loopback binding. Shared/public hosting requires authentication, HTTPS, access controls and a production WSGI server before deployment.

## Tests

```sh
python -m pip install pytest
python -m pytest -q
```

Tests use temporary databases, never your saved records. The optional native window requires manual testing on your target desktop OS.
