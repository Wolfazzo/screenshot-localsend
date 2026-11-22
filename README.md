# Send KOReader Screenshots with LocalSend

**Version 1.1.2**

This patch adds a **Send via LocalSend** button to KOReader’s screenshot dialog. Send the PNG you just captured directly to a phone, tablet, or computer running LocalSend.

## Installation

1. Copy `2-screenshot-localsend.lua` to the `koreader/patches/` directory on your device.
2. Restart KOReader.
3. Make sure the LocalSend plugin is installed and enabled in KOReader.

## Usage

1. Take a screenshot in KOReader and tap **Send via LocalSend**.
2. KOReader turns on Wi-Fi if needed and waits for a connection. **Searching for LocalSend devices…** stays visible during discovery.
3. Choose a device from the list. The transfer starts directly, with a PIN prompt only if the receiving device requires one.
4. LocalSend shows the transfer result. The screenshot stays saved on your device.

If the plugin is missing, the patch displays **LocalSend is not installed**. It also tells you if the plugin is disabled. If no devices appear, use **Scan again** in the LocalSend dialog.

## Transfer and language settings

The button uses LocalSend’s send-only flow. The sender process exits when the transfer finishes. If a transfer attempt takes longer than two minutes, the patch cancels it and displays a timeout message.

The patch automatically follows the language selected in KOReader. The device picker and PIN dialog use the translations available in the LocalSend plugin.

If you also use `2-reader-wifi-idle.lua`, Wi-Fi can turn off automatically after a transfer while a book is open. With automatic shutoff enabled, the countdown starts when the last online dialog closes.

<img width="353" height="500" alt="ksnip_20261122-155748" src="https://github.com/user-attachments/assets/97c0cf2e-57c4-4313-87cf-aec619b24a39" />
