# BSG Launcher Auto-Launcher for Tarkov

This PowerShell script automatically opens the BSG Launcher and launches Escape from Tarkov. It is designed to run headless, making it ideal for automated setups.

---
## **NOTE**
Opens tarkov via the "HWHO" shortcut. Change the config to open the regular BSG launcher if need be. 

---

## **Features**
- Automatically opens the BSG Launcher.
- Launches Escape from Tarkov automatically.
- Runs headless for seamless automation.

---

## **Converting the Script to an Executable (.exe)**

To convert the PowerShell script (`.ps1`) into an executable (`.exe`), follow these steps:

1. **Install PS2EXE:**
   - Download the `ps2exe.ps1` script from the [PS2EXE GitHub repository](https://github.com/MScholtes/PS2EXE).

2. **Convert the Script:**
   - Place your script (e.g., `BSG_Launcher.ps1`) in the same folder as `ps2exe.ps1`.
   - Open PowerShell and navigate to the folder.
   - Run the following command:
     ```powershell
     .\ps2exe.ps1 -inputFile "BSG_Launcher.ps1" -outputFile "BSG_Launcher.exe"
     ```
   - Replace `BSG_Launcher.ps1` with your script's name and `BSG_Launcher.exe` with your desired output name.

3. **Run the Executable:**
   - The generated `.exe` file will be in the same folder. Double-click it to run the script.

---

## **Known Issues**
- **Logout Issue:** Sometimes, the script may log you out of the BSG Launcher.

---

## **To Do**
- Add error handling.
- Add update handling.

---

## **License**
This project is open-source and available under the [MIT License](LICENSE).
