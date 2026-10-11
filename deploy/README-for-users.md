# Dental apps on the MacBook Air — how to use

What's installed: three Windows dental programs running through HighBall (a free Wine-based layer):
**Blue Sky Plan 5**, **DentiqGuide 1.4** and **CS 3D Imaging 3.10**.

## Starting a program
Open `~/Applications/Highball` (Finder → Go → Home → Applications → Highball) and double-click:
- **Blue Sky Plan** — sign in with your Blue Sky Bio account in the browser window that opens the first time.
- **DentiqGuide** — sign in with your DentiqSolution account; confirm the trial/terms notices.
- **CS 3D Imaging** — opens directly; use the "browse to a .dcm file" dialog to load a CBCT.
Tip: drag these three to the Dock. The first start of each takes about a minute (nothing is wrong).

## Things to know
- Keep the Highball app installed; it must stay on the Mac (it is what runs the programs). Don't delete its environments in the Highball window.
- If Highball ever proposes to move an environment to a "new engine", decline — DentiqGuide depends on a patched engine (details in the technical README).
- DentiqGuide's AI automation (red indicator) does not work on a Mac; manual planning does.
- Do not upgrade beyond macOS 27 until told otherwise (Apple removes Rosetta in macOS 28, which these programs need).
- Patient data: save it in your own Documents folder; the programs see the Mac's folders as drive `Z:`.

## If something breaks
Quit the program (Highball window → environment → Stop), start it again from the launcher. Logs are in
`~/Library/Application Support/Highball/logs/`. The technical setup record is in the `dental soft/README.md` in the repo (docs/SETUP-LOG.md).
