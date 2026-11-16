# Inputs

The original media go here: copies you're licensed to use. They're
copyrighted (and the product key is yours), so git ignores everything in
this folder except this file and the folders themselves (each holds a hidden
`.gitkeep`, which the scripts skip). Each goes into its own folder; the file name
doesn't matter, as the scripts read the one file in each folder (with
several, the first of the expected type, and they say which).
`setup.sh` checks them all before it starts; the
[README](../README.md#3-put-the-original-media-into-inputs) says what each
one provides.

| Folder | What to put there |
|---|---|
| `windows_xp/` | Windows XP Professional install CD (`.iso`), 32-bit, English (tested: SP3, volume licence; see the [README](../README.md#3-put-the-original-media-into-inputs)) |
| `xp_key/` | a text file with its product key, `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX` |
| `borland_pascal/` | an archive of the Borland Pascal 7.01 install disks and run-time library source disk, as disk images |
| `delphi_developer/` | Delphi Developer 2.01 CD (`.iso`) |
| `delphi_desktop/` | an archive of Delphi Desktop 2.0's setup |
| `cpp_builder/` | an archive of C++Builder 1.0 Client/Server Suite's setup |
| `dr_dos/` | an archive of the DR DOS 6.0 disks, as disk images |
| `pkzip/` | PKZIP 2.50 for DOS (the self-extracting `.exe`) |
| `winzip_se/` | WinZip Self-Extractor 2.1's setup, `wzipse21.exe` |
| `winzipse_reg/` | `winzipse.dat`, your WinZip Self-Extractor registration; the installers carry its name, so they're byte-identical only with the original licensee's |

Archives can be anything 7-Zip reads, with their contents in any folder; disk
images can be `.img`, `.ima` or `.vfd`, under any names. Other places: the variables in
`xp/lib.sh` (`INPUTS=` for this folder, `XPISO=`, `BP=`, … for single files).

Optional, not used by the scripts: `M4W240HW.ZIP`, the 1999 hardware
edition ([docs/INSTALLERS.md](../docs/INSTALLERS.md)).
