:: Downloaded die Zip-Datei von github.com
powershell Invoke-WebRequest https://github.com/JakobZoephel/Neuronales-Netz/raw/main/windows_x64.zip -OutFile Neuronales-Netz.zip
:: Extrahiert die Zip-Datei
powershell Expand-Archive -LiteralPath .\Neuronales-Netz.zip -DestinationPath Neuronales-Netz
:: Löscht die Zip-Datei (nach dem Extrahieren wird diese nicht mehr benötigt)
del Neuronales-Netz.zip

:: Wechselt in den Ordner Neuronales-Netz
cd Neuronales-Netz
:: Das Gleiche nur für Java. Die Commands sind andere, da diese auch ohne Powershell auskommen (schneller)
:: Downloaded Java
curl -o java.zip https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.zip
:: Extrahiert Java
tar -xf java.zip
:: Den Ordner zu java umbenennen damit das Programm ihn findet
ren jdk-17.0.3.1 java
:: Diese Zip-Datei wird ebenfalls nicht mehr gebraucht 
del java.zip
